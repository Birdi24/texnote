import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/canvas_options.dart';

import '../../app_style.dart';
import '../../models/HandwrittenNote.dart' show Stroke, ImageData;
import '../../widgets/single_circle_button.dart';
import 'BottomCanvas.dart';
import 'TopCanvas.dart';
import 'CanvasBackground.dart';
import 'CanvasColorPickerOverlay.dart';
import 'canvas_history.dart';
import 'canvas_transformation_controller.dart';
import 'CanvasScrollbar.dart';
import 'PageThumbnailView.dart';

class CanvasView extends StatefulWidget {
  final List<Stroke> bottomLayerStrokes;
  final List<ImageData> images;
  final void Function(List<Stroke> strokes, List<ImageData> images) onCommit;
  final GlobalKey<BottomCanvasState> bottomCanvasKey;
  final GlobalKey<TopCanvasState> topCanvasKey;
  final Future<void> Function() onSave;
  final bool changed;
  final VoidCallback onChanged;
  final String paperType;
  final List<String?> pageBackgrounds;
  final PageBackgroundResolver? resolvePageBackground;

  const CanvasView({
    super.key,
    required this.bottomLayerStrokes,
    required this.images,
    required this.onCommit,
    required this.bottomCanvasKey,
    required this.topCanvasKey,
    required this.onSave,
    required this.changed,
    required this.onChanged,
    required this.paperType,
    this.pageBackgrounds = const [],
    this.resolvePageBackground,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  final CanvasTransformationController _transformationController = CanvasTransformationController();
  final CanvasHistoryManager _historyManager = CanvasHistoryManager();

  Size? _lastScreenSize;
  final Set<int> _activePointers = <int>{};
  bool _drawingSuspended = false;

  DrawingTool _selectedTool = DrawingTool.pen;
  DrawingTool _lastPenEraserTool = DrawingTool.pen;

  int _previousStylusButtons = 0;
  DateTime? _lastStylusButtonPress;
  static const Duration _stylusDoublePressWindow = Duration(milliseconds: 300);
  bool _stylusButtonHeld = false;

  Color _primaryColor = BLACK;
  Color _secondaryColor = Colors.indigo.shade900;
  Color _highlighterPrimaryColor = Colors.yellow.withAlpha(77);
  Color _highlighterSecondaryColor = Colors.green.withAlpha(77);
  bool _showColorPicker = false;

  late double _pageWidth;
  late double _pageHeight;
  double _basePageHeight = 0;
  int _numPages = 1;
  bool _isTransforming = false;
  bool show_all_buttons = true;
  bool _showPageManager = false;
  int _currentPageIndex = 0;

  // Track max Y content coordinate imperatively to eliminate O(N) calculations
  double _maxContentY = 0.0;

  // Cache rasterized page thumbnails to prevent vector re-paints
  final Map<int, ui.Image> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.pageBackgrounds.isNotEmpty) {
      _numPages = widget.pageBackgrounds.length;
    } else {
      widget.pageBackgrounds.add(null);
      _numPages = 1;
    }

    _recomputeContentBounds();

    _transformationController.addListener(_onTransformationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordHistory();
    });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _clearThumbnailCache();
    super.dispose();
  }

  void _clearThumbnailCache() {
    for (final img in _thumbnailCache.values) {
      img.dispose(); // Releases native Engine image resources
    }
    _thumbnailCache.clear();
  }

  void _recomputeContentBounds() {
    double maxY = 0.0;
    for (final stroke in widget.bottomLayerStrokes) {
      final b = stroke.getBounds();
      if (b.bottom > maxY) maxY = b.bottom;
    }
    for (final img in widget.images) {
      final b = img.getBounds();
      if (b.bottom > maxY) maxY = b.bottom;
    }
    _maxContentY = maxY;
  }

  void _updateContentBoundsWithStroke(Stroke stroke) {
    final b = stroke.getBounds();
    if (b.bottom > _maxContentY) {
      _maxContentY = b.bottom;
    }
  }

  void _updateContentBoundsWithImage(ImageData image) {
    final b = image.getBounds();
    if (b.bottom > _maxContentY) {
      _maxContentY = b.bottom;
    }
  }

  Future<void> _updateThumbnailCache(int pageIndex) async {
    if (_basePageHeight <= 0 || _pageWidth <= 0) return;

    // Capture the current layer state synchronously to avoid race conditions
    final topStrokes = widget.topCanvasKey.currentState?.getStrokes() ?? [];
    final bottomStrokes = List<Stroke>.from(widget.bottomLayerStrokes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // We render the strokes into a transparent image. 
    // The background (PDF/Paper) will be rendered by the PagePreview widget itself 
    // to ensure accuracy and reduce rasterization overhead.

    final pageStartY = pageIndex * _basePageHeight;
    final pageEndY = (pageIndex + 1) * _basePageHeight;

    // Use the same coordinate system and rendering logic as HandwritingPainter
    canvas.save();
    canvas.translate(0, -pageStartY);

    final allStrokes = [...bottomStrokes, ...topStrokes];
    for (final stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final bounds = stroke.getBounds();
      // Check if the stroke intersects this page
      if (bounds.bottom >= pageStartY && bounds.top <= pageEndY) {
        final path = stroke.buildPath();
        
        // Use adaptive color logic consistent with the main view
        final color = getAdaptiveStrokeColor(stroke.color, BG);

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();

    // Rasterize
    final picture = recorder.endRecording();
    const double thumbnailWidth = 150.0;
    final double scale = thumbnailWidth / _pageWidth;
    final int thumbnailHeight = (_basePageHeight * scale).toInt();

    final imageRecorder = ui.PictureRecorder();
    final imageCanvas = Canvas(imageRecorder);
    imageCanvas.scale(scale, scale);
    imageCanvas.drawPicture(picture);

    final scaledPicture = imageRecorder.endRecording();
    final newImage = await scaledPicture.toImage(
      thumbnailWidth.toInt(),
      thumbnailHeight,
    );

    if (mounted) {
      setState(() {
        // Swap out old image and dispose it only AFTER new image is ready
        final oldImage = _thumbnailCache[pageIndex];
        _thumbnailCache[pageIndex] = newImage;
        oldImage?.dispose();
      });
    } else {
      newImage.dispose();
    }
  }

  void _onTransformationChanged() {
    final page = _computeCurrentPage();
    if (page != _currentPageIndex) {
      setState(() {
        _currentPageIndex = page;
      });
    }
  }

  int _computeCurrentPage() {
    if (_basePageHeight == 0 || _lastScreenSize == null) return 0;
    final zoom = _transformationController.zoom;
    final scrollY = -_transformationController.offset.dy / zoom;
    final viewportCenterY = scrollY + (_lastScreenSize!.height / 2) / zoom;

    final page = (viewportCenterY / _basePageHeight).floor();
    return page.clamp(0, _numPages - 1);
  }

  void _recordHistory() {
    final topStrokes = widget.topCanvasKey.currentState?.getStrokes() ?? [];
    final topImages = widget.topCanvasKey.currentState?.getImages() ?? [];
    _historyManager.record(
      widget.bottomLayerStrokes,
      topStrokes,
      _numPages,
      widget.images,
      widget.pageBackgrounds,
      topImages: topImages,
    );
    _updateThumbnailCache(_currentPageIndex);
    setState(() {});
    widget.onChanged();
  }

  void _applyHistoryState(CanvasHistoryState state) {
    _numPages = state.numPages;
    _pageHeight = _basePageHeight * _numPages;

    widget.bottomLayerStrokes.clear();
    widget.bottomLayerStrokes.addAll(state.bottomLayer.map((s) => s.copy()).toList());
    widget.images.clear();
    widget.images.addAll(state.images.map((i) => i.copy()).toList());

    widget.pageBackgrounds.clear();
    widget.pageBackgrounds.addAll(state.pageBackgrounds);

    _recomputeContentBounds();

    // Clear stale thumbnails and queue fresh renders
    _clearThumbnailCache();
    for (int i = 0; i < _numPages; i++) {
      _updateThumbnailCache(i);
    }

    widget.bottomCanvasKey.currentState?.update();
    widget.topCanvasKey.currentState?.setStrokes(state.topLayer.map((s) => s.copy()).toList());
    widget.topCanvasKey.currentState?.setImages((state.topImages ?? []).map((i) => i.copy()).toList());
  }

  void _initializeFit(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _basePageHeight = mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
    _pageWidth = _basePageHeight * .707;

    // Optimized O(1) page bounds calculation using imperatively tracked _maxContentY
    if (_basePageHeight > 0) {
      int contentPages = (_maxContentY / _basePageHeight).ceil();
      if (contentPages > _numPages) {
        _numPages = contentPages;
        while (widget.pageBackgrounds.length < _numPages) {
          widget.pageBackgrounds.add(null);
        }
      }
    }

    _pageHeight = _basePageHeight * _numPages;

    _transformationController.initialize(
      pageWidth: _pageWidth,
      viewportWidth: mediaQuery.size.width,
    );
  }

  void _handleStylusPointer(PointerEvent event) {
    if (event.kind != PointerDeviceKind.stylus) return;

    final int stylusButtons = event.buttons & (kPrimaryStylusButton | kSecondaryStylusButton);
    final bool buttonPressed = stylusButtons != 0;
    final bool newButtonPress = buttonPressed && _previousStylusButtons == 0;

    _previousStylusButtons = stylusButtons;
    if (!newButtonPress) return;

    _stylusButtonHeld = true;

    final now = DateTime.now();
    final bool doublePress = _lastStylusButtonPress != null &&
        now.difference(_lastStylusButtonPress!) <= _stylusDoublePressWindow;

    if (doublePress) {
      _lastStylusButtonPress = null;
      _onToolChanged(DrawingTool.lasso);
      return;
    }

    _lastStylusButtonPress = now;

    if (_selectedTool == DrawingTool.lasso) {
      _onToolChanged(_lastPenEraserTool);
    } else if (_selectedTool == DrawingTool.pen) {
      _onToolChanged(DrawingTool.eraser);
    } else if (_selectedTool == DrawingTool.eraser || _selectedTool == DrawingTool.eraser2) {
      _onToolChanged(DrawingTool.pen);
    }
  }

  void _handleStylusPointerUp(PointerEvent event) {
    if (event.kind != PointerDeviceKind.stylus) return;
    final int stylusButtons = event.buttons & (kPrimaryStylusButton | kSecondaryStylusButton);
    _previousStylusButtons = stylusButtons;
    if (stylusButtons == 0) {
      _stylusButtonHeld = false;
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _handleStylusPointer(event);

    if (_stylusButtonHeld) return;

    if (_activePointers.isEmpty) {
      _drawingSuspended = false;
    }

    _activePointers.add(event.pointer);

    if (_activePointers.length >= 2) {
      _drawingSuspended = true;
      widget.topCanvasKey.currentState?.cancelCurrentStroke();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _handleStylusPointer(event);
  }

  void _onPointerUp(PointerEvent event) {
    _handleStylusPointerUp(event);
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _drawingSuspended = false;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _handleStylusPointerUp(event);
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _drawingSuspended = false;
    }
  }

  void _handleUndo() {
    final state = _historyManager.undo();
    if (state != null) {
      _applyHistoryState(state);
      setState(() {});
      widget.onCommit([], []);
    }
  }

  void _handleRedo() {
    final state = _historyManager.redo();
    if (state != null) {
      _applyHistoryState(state);
      setState(() {});
      widget.onCommit([], []);
    }
  }

  Future<void> _handleImportImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'note_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String fileName = "${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}";
      final String newPath = p.join(imagesDir.path, fileName);
      await File(image.path).copy(newPath);

      final zoom = _transformationController.zoom;
      final offset = _transformationController.offset;
      final viewportSize = _lastScreenSize ?? Size.zero;

      final centerX = (-offset.dx + viewportSize.width / 2) / zoom;
      final centerY = (-offset.dy + viewportSize.height / 2) / zoom;

      final newImageData = ImageData(
        position: Offset(centerX - 100, centerY - 100),
        imagePath: newPath,
      );

      setState(() {
        widget.images.add(newImageData);
        _updateContentBoundsWithImage(newImageData);
      });
      widget.onChanged();
      _recordHistory();
    }
  }

  void _onToolChanged(DrawingTool tool) {
    if (tool == DrawingTool.duplicate) {
      widget.topCanvasKey.currentState?.setTool(tool);
      return;
    }

    setState(() {
      _selectedTool = tool;

      if (tool == DrawingTool.pen || tool == DrawingTool.eraser || tool == DrawingTool.eraser2) {
        _lastPenEraserTool = tool;
      }

      widget.topCanvasKey.currentState?.setTool(tool);

      if (tool == DrawingTool.pen) {
        widget.topCanvasKey.currentState?.setColor(_primaryColor);
      } else if (tool == DrawingTool.highlighter) {
        widget.topCanvasKey.currentState?.setColor(_highlighterPrimaryColor);
      }
    });
  }

  void _addPage(Size viewportSize) {
    setState(() {
      final insertIndex = _currentPageIndex + 1;
      _numPages++;

      widget.pageBackgrounds.insert(
        insertIndex.clamp(0, widget.pageBackgrounds.length),
        "blank",
      );

      final thresholdY = insertIndex * _basePageHeight;
      final shiftDelta = Offset(0, _basePageHeight);

      for (int i = 0; i < widget.bottomLayerStrokes.length; i++) {
        final stroke = widget.bottomLayerStrokes[i];
        if (stroke.getBounds().top >= thresholdY - 1.0) {
          widget.bottomLayerStrokes[i] = stroke.translate(shiftDelta);
        }
      }

      for (int i = 0; i < widget.images.length; i++) {
        final img = widget.images[i];
        if (img.position.dy >= thresholdY - 1.0) {
          widget.images[i] = img.translate(shiftDelta);
        }
      }

      _recomputeContentBounds();
      widget.topCanvasKey.currentState?.shiftContent(thresholdY, shiftDelta);
      _pageHeight = _basePageHeight * _numPages;

      // Shift cached thumbnails down by 1 for all shifted pages
      final Map<int, ui.Image> updatedCache = {};
      _thumbnailCache.forEach((pageIdx, image) {
        if (pageIdx >= insertIndex) {
          updatedCache[pageIdx + 1] = image;
        } else {
          updatedCache[pageIdx] = image;
        }
      });
      _thumbnailCache.clear();
      _thumbnailCache.addAll(updatedCache);

      _transformationController.setOffset(
        Offset(_transformationController.offset.dx, -thresholdY),
        viewportSize,
        _pageWidth,
        _pageHeight,
      );
    });

    widget.bottomCanvasKey.currentState?.update();
    _recordHistory();

    // Rasterize the new blank page
    _updateThumbnailCache(_currentPageIndex + 1);
  }

  void _movePage(int index, int direction) {
    int targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= _numPages) return;

    setState(() {
      // 1. Swap backgrounds
      final tempBg = widget.pageBackgrounds[index];
      widget.pageBackgrounds[index] = widget.pageBackgrounds[targetIndex];
      widget.pageBackgrounds[targetIndex] = tempBg;

      final yMin1 = index * _basePageHeight;
      final yMax1 = (index + 1) * _basePageHeight;
      final yMin2 = targetIndex * _basePageHeight;
      final yMax2 = (targetIndex + 1) * _basePageHeight;
      final shift1 = Offset(0, (targetIndex - index) * _basePageHeight);
      final shift2 = Offset(0, (index - targetIndex) * _basePageHeight);

      // Shift bottomLayerStrokes
      for (int i = 0; i < widget.bottomLayerStrokes.length; i++) {
        final stroke = widget.bottomLayerStrokes[i];
        final top = stroke.getBounds().top;
        if (top >= yMin1 - 1.0 && top < yMax1 - 1.0) {
          widget.bottomLayerStrokes[i] = stroke.translate(shift1);
        } else if (top >= yMin2 - 1.0 && top < yMax2 - 1.0) {
          widget.bottomLayerStrokes[i] = stroke.translate(shift2);
        }
      }

      // Shift images
      for (int i = 0; i < widget.images.length; i++) {
        final img = widget.images[i];
        final top = img.position.dy;
        if (top >= yMin1 - 1.0 && top < yMax1 - 1.0) {
          widget.images[i] = img.translate(shift1);
        } else if (top >= yMin2 - 1.0 && top < yMax2 - 1.0) {
          widget.images[i] = img.translate(shift2);
        }
      }

      // Shift top layer content (uncommitted strokes/images)
      widget.topCanvasKey.currentState?.movePageContent(
        yMin1, yMax1, shift1,
        yMin2, yMax2, shift2,
      );

      _recomputeContentBounds();

      // 2. SWAP cached thumbnails safely instead of removing them
      final tempImage = _thumbnailCache[index];
      final targetImage = _thumbnailCache[targetIndex];

      if (targetImage != null) {
        _thumbnailCache[index] = targetImage;
      } else {
        _thumbnailCache.remove(index);
      }

      if (tempImage != null) {
        _thumbnailCache[targetIndex] = tempImage;
      } else {
        _thumbnailCache.remove(targetIndex);
      }

      widget.bottomCanvasKey.currentState?.update();
      _recordHistory();
    });

    // 3. Re-rasterize swapped pages asynchronously to update translated coordinates
    _updateThumbnailCache(index);
    _updateThumbnailCache(targetIndex);
  }

  void _scrollToPage(int index) {
    if (_lastScreenSize == null) return;
    final targetY = -index * _basePageHeight;
    _transformationController.setOffset(
      Offset(_transformationController.offset.dx, targetY),
      _lastScreenSize!,
      _pageWidth,
      _pageHeight,
    );
  }

  void _switchEraserType() {
    setState(() {
      _selectedTool = (_selectedTool == DrawingTool.eraser) ? DrawingTool.eraser2 : DrawingTool.eraser;
      widget.topCanvasKey.currentState?.setTool(_selectedTool);
    });
  }

  void _eraseFromBottom(Offset position) {
    bool changed = false;
    final double threshold = (widget.topCanvasKey.currentState?.penSize ?? 1.0) * 2.0;

    setState(() {
      widget.bottomLayerStrokes.removeWhere((stroke) {
        bool hit = stroke.points.any((p) => (p - position).distance < threshold);
        if (hit) changed = true;
        return hit;
      });

      widget.images.removeWhere((img) {
        bool hit = img.getBounds().contains(position);
        if (hit) changed = true;
        return hit;
      });
    });

    if (changed) {
      _recomputeContentBounds();
      widget.bottomCanvasKey.currentState?.update();
      widget.onCommit([], []);
      _recordHistory();
    }
  }

  List<Stroke> _selectFromBottom(Path lassoPath) {
    final List<Stroke> selected = [];
    final List<Stroke> remaining = [];

    for (final stroke in widget.bottomLayerStrokes) {
      bool isInside = stroke.points.any((p) => lassoPath.contains(p));
      if (isInside) {
        selected.add(stroke);
      } else {
        remaining.add(stroke);
      }
    }

    if (selected.isNotEmpty) {
      setState(() {
        widget.bottomLayerStrokes.clear();
        widget.bottomLayerStrokes.addAll(remaining);
        _recomputeContentBounds();
      });
      widget.bottomCanvasKey.currentState?.update();
      widget.onCommit([], []);
    }
    return selected;
  }

  List<ImageData> _selectImagesFromBottom(Path lassoPath) {
    final List<ImageData> selected = [];
    final List<ImageData> remaining = [];

    for (final img in widget.images) {
      final bounds = img.getBounds();
      if (lassoPath.contains(bounds.center) ||
          lassoPath.contains(bounds.topLeft) ||
          lassoPath.contains(bounds.bottomRight)) {
        selected.add(img);
      } else {
        remaining.add(img);
      }
    }

    if (selected.isNotEmpty) {
      setState(() {
        widget.images.clear();
        widget.images.addAll(remaining);
        _recomputeContentBounds();
      });
      widget.onCommit([], []);
    }
    return selected;
  }

  void _onColorChanged(Color color) {
    setState(() {
      if (_selectedTool == DrawingTool.highlighter) {
        final highlighterColor = color.withAlpha(70);
        if (highlighterColor == _highlighterSecondaryColor) {
          final temp = _highlighterPrimaryColor;
          _highlighterPrimaryColor = _highlighterSecondaryColor;
          _highlighterSecondaryColor = temp;
        } else {
          _highlighterPrimaryColor = highlighterColor;
        }
        widget.topCanvasKey.currentState?.setColor(_highlighterPrimaryColor);
      } else {
        if (color == _secondaryColor) {
          final temp = _primaryColor;
          _primaryColor = _secondaryColor;
          _secondaryColor = temp;
        } else {
          _primaryColor = color;
        }
        widget.topCanvasKey.currentState?.setColor(_primaryColor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    if (_lastScreenSize != screenSize) {
      _initializeFit(context);
      _lastScreenSize = screenSize;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = constraints.maxWidth;
        final safeHeight = constraints.maxHeight;
        final viewportSize = Size(safeWidth, safeHeight);

        return SizedBox(
          width: safeWidth,
          height: safeHeight,
          child: ClipRect(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  if (details.pointerCount >= 2) {
                    _isTransforming = true;
                    _transformationController.handleScaleStart(details);
                  }
                },
                onScaleUpdate: (details) {
                  if (details.pointerCount >= 2) {
                    if (!_isTransforming) {
                      _isTransforming = true;
                      _transformationController.handleScaleStart(
                        ScaleStartDetails(
                          focalPoint: details.focalPoint,
                          localFocalPoint: details.localFocalPoint,
                          pointerCount: details.pointerCount,
                        ),
                      );
                    }
                    _transformationController.handleScaleUpdate(
                      details,
                      viewportSize,
                      _pageWidth,
                      _pageHeight,
                    );
                  } else {
                    _isTransforming = false;
                  }
                },
                onScaleEnd: (details) {
                  _isTransforming = false;
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: ListenableBuilder(
                        listenable: _transformationController,
                        builder: (context, child) {
                          return Transform(
                            alignment: Alignment.topLeft,
                            transform: _transformationController.matrix,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: _pageWidth,
                          height: _pageHeight,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CanvasBackground(
                                  numPages: _numPages,
                                  pageWidth: _pageWidth,
                                  basePageHeight: _basePageHeight,
                                  paperType: widget.paperType,
                                  pageBackgrounds: widget.pageBackgrounds,
                                  resolvePageBackground: widget.resolvePageBackground,
                                  currentPage: _currentPageIndex,
                                  windowRadius: 1,
                                ),
                                ...widget.images.map((img) => Positioned(
                                  left: img.position.dx,
                                  top: img.position.dy,
                                  child: Image.file(
                                    File(img.imagePath),
                                    width: img.width,
                                    height: img.height,
                                    fit: BoxFit.contain,
                                  ),
                                )),
                                BottomCanvas(
                                  key: widget.bottomCanvasKey,
                                  strokes: widget.bottomLayerStrokes,
                                ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: icon_color.withAlpha(20),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: TopCanvas(
                                    key: widget.topCanvasKey,
                                    onCommit: (strokes, images) {
                                      for (final s in strokes) {
                                        _updateContentBoundsWithStroke(s);
                                      }
                                      for (final img in images) {
                                        _updateContentBoundsWithImage(img);
                                      }
                                      widget.onCommit(strokes, images);
                                      _recordHistory();
                                    },
                                    onChanged: () {
                                      setState(() {});
                                      _recordHistory();
                                    },
                                    suspended: () => _drawingSuspended,
                                    zoom: () => _transformationController.zoom,
                                    onEraseFromBottom: _eraseFromBottom,
                                    onSelectStrokesFromBottom: _selectFromBottom,
                                    onSelectImagesFromBottom: _selectImagesFromBottom,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 15,
                      left: 10,
                      child: single_circle_button(
                        LucideIcons.chevron_left,
                        30.0,
                        90,
                        "back",
                            () async {
                          if (widget.changed) {
                            await widget.onSave();
                          }
                          Navigator.pop(context, true);
                        },
                        context,
                        MediaQuery.of(context).size.width,
                        button_width: 50,
                        bgAlpha: 255,
                      ),
                    ),
                    show_all_buttons
                        ? (MediaQuery.of(context).size.width < 750)
                        ? Positioned(
                      top: 10,
                      left: MediaQuery.of(context).size.width / 2 - 125 > 60
                          ? MediaQuery.of(context).size.width / 2 - 125
                          : 60,
                      child: consolidated_tool_array(
                        context,
                        _handleUndo,
                        _handleRedo,
                        canUndo: _historyManager.canUndo,
                        canRedo: _historyManager.canRedo,
                        selectedTool: _selectedTool,
                        onToolChanged: _onToolChanged,
                        onAddPage: () => _addPage(viewportSize),
                        onImportImage: _handleImportImage,
                      ),
                    )
                        : Positioned(
                      top: 10,
                      left: 70,
                      child: history_button_array(
                        context,
                        _handleUndo,
                        _handleRedo,
                        canUndo: _historyManager.canUndo,
                        canRedo: _historyManager.canRedo,
                      ),
                    )
                        : const SizedBox.shrink(),
                    show_all_buttons
                        ? Align(
                      alignment: Alignment.topCenter,
                      child: (MediaQuery.of(context).size.width >= 750)
                          ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: tool_button_array(
                          context,
                          selectedTool: _selectedTool,
                          onToolChanged: _onToolChanged,
                          onAddPage: () => _addPage(viewportSize),
                          onImportImage: _handleImportImage,
                        ),
                      )
                          : const SizedBox.shrink(),
                    )
                        : const SizedBox.shrink(),
                    show_all_buttons
                        ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: left_button_array(
                          context,
                          selectedTool: _selectedTool,
                          currentSize: widget.topCanvasKey.currentState?.penSize ?? 3.0,
                          onIncrementSize: () => widget.topCanvasKey.currentState?.changeSize(0.5),
                          onDecrementSize: () => widget.topCanvasKey.currentState?.changeSize(-0.5),
                          onSizeDelta: (delta) => widget.topCanvasKey.currentState?.changeSize(delta),
                          onSwitchEraserType: _switchEraserType,
                          currentPenColor: (_selectedTool == DrawingTool.highlighter)
                              ? _highlighterPrimaryColor
                              : _primaryColor,
                          secondaryPenColor: (_selectedTool == DrawingTool.highlighter)
                              ? _highlighterSecondaryColor
                              : _secondaryColor,
                          onColorChanged: _onColorChanged,
                          onOpenColorPicker: () => setState(() => _showColorPicker = !_showColorPicker),
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                    if (_showColorPicker)
                      Positioned(
                        left: 80,
                        bottom: 20,
                        child: CanvasColorPickerOverlay(
                          initialColor: (_selectedTool == DrawingTool.highlighter)
                              ? _highlighterPrimaryColor
                              : _primaryColor,
                          onColorChanged: _onColorChanged,
                          onDismiss: () => setState(() => _showColorPicker = false),
                        ),
                      ),
                    CanvasScrollbar(
                      transformationController: _transformationController,
                      numPages: _numPages,
                      pageWidth: _pageWidth,
                      pageHeight: _pageHeight,
                      basePageHeight: _basePageHeight,
                      safeHeight: safeHeight,
                      viewportSize: viewportSize,
                      onTogglePageManager: () => setState(() => _showPageManager = !_showPageManager),
                    ),
                    if (_showPageManager)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: PageThumbnailView(
                          currentPage: _currentPageIndex,
                          numPages: _numPages,
                          pageBackgrounds: widget.pageBackgrounds,
                          paperType: widget.paperType,
                          onMovePage: _movePage,
                          onClose: () => setState(() => _showPageManager = false),
                          strokes: [
                            ...widget.bottomLayerStrokes,
                            ...widget.topCanvasKey.currentState?.getStrokes() ?? []
                          ],
                          images: [
                            ...widget.images,
                            ...widget.topCanvasKey.currentState?.getImages() ?? []
                          ],
                          pageWidth: _pageWidth,
                          basePageHeight: _basePageHeight,
                          resolvePageBackground: widget.resolvePageBackground,
                          onPageTap: _scrollToPage,
                          initialPageIndex: _currentPageIndex,
                          thumbnailCache: _thumbnailCache,
                        ),
                      ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: single_circle_button(
                        show_all_buttons ? LucideIcons.maximize : LucideIcons.minimize,
                        20,
                        90,
                        "minimize/maximize",
                            () {
                          setState(() {
                            show_all_buttons = !show_all_buttons;
                          });
                        },
                        context,
                        screenSize.width,
                        button_width: 50,
                        bgAlpha: 255,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}