import 'dart:io';
import 'dart:ui' as ui;

import 'package:birdwrite/screens/HandwrittenNoteScreen/PageListView.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app_style.dart';
import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';
import '../../widgets/single_circle_button.dart';
import 'BottomCanvas.dart';
import 'TopCanvas.dart';
import 'CanvasBackground.dart';
import 'CanvasColorPickerOverlay.dart';
import 'canvas_history.dart';
import 'canvas_options.dart';
import 'canvas_transformation_controller.dart';
import 'CanvasScrollbar.dart';

import '../../models/HandwrittenNote.dart';

class CanvasView extends StatefulWidget {
  final List<NotePage> pages;
  final void Function(List<Stroke> strokes, List<ImageData> images, List<TextData> texts) onCommit;
  final GlobalKey<TopCanvasState> topCanvasKey;
  final Future<void> Function() onSave;
  final bool changed;
  final VoidCallback onChanged;
  final String paperType;
  final PageBackgroundResolver? resolvePageBackground;
  final ValueChanged<int>? onPageChanged;
  final Future<void> Function()? onBack;

  const CanvasView({
    super.key,
    required this.pages,
    required this.onCommit,
    required this.topCanvasKey,
    required this.onSave,
    required this.changed,
    required this.onChanged,
    required this.paperType,
    required this.resolvePageBackground,
    required this.onPageChanged,
    this.onBack, // NEW
  });

  @override
  State<CanvasView> createState() => CanvasViewState();
}

class CanvasViewState extends State<CanvasView> {
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

  Color _primaryColor = Colors.indigo.shade900;
  Color _secondaryColor = BLACK;
  Color _thirdColor = Colors.red.shade700;
  Color _fourthColor = Colors.yellow.shade600;
  Color _highlighterPrimaryColor = Colors.yellow.withAlpha(77);
  Color _highlighterSecondaryColor = Colors.green.withAlpha(77);
  Color _highlighterThirdColor = Colors.orange.withAlpha(77);
  Color _highlighterFourthColor = Colors.pink.withAlpha(77);
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
  final Map<String, ui.Image> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.pages.isEmpty) {
      widget.pages.add(NotePage(source: PageSource.blank()));
    }
    _numPages = widget.pages.length;

    _recomputeContentBounds();

    _transformationController.addListener(_onTransformationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordHistory();
      if (_selectedTool == DrawingTool.pen) {
        widget.topCanvasKey.currentState?.setColor(_primaryColor);
      } else if (_selectedTool == DrawingTool.highlighter) {
        widget.topCanvasKey.currentState?.setColor(_highlighterPrimaryColor);
      }
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

  void refreshPartitions() {
    // This is called from main.dart to refresh bounds if needed
    setState(() {
      _recomputeContentBounds();
    });
  }

  void _recomputeContentBounds() {
    _numPages = widget.pages.length;
    _pageHeight = _basePageHeight * _numPages;
  }

  Future<void> _updateThumbnailCache(int pageIndex) async {
    if (_basePageHeight <= 0 || _pageWidth <= 0 || pageIndex >= widget.pages.length) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final pageRect = Rect.fromLTWH(0, 0, _pageWidth, _basePageHeight);

    // Background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(pageRect, bgPaint);

    final page = widget.pages[pageIndex];

    for (final stroke in page.strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.size
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    // ... Simplified for thumbnail ...
    final picture = recorder.endRecording();
    const double thumbnailWidth = 150.0;
    final double scale = thumbnailWidth / _pageWidth;
    final int thumbnailHeight = (_basePageHeight * scale).toInt();
    final imageRecorder = ui.PictureRecorder();
    final imageCanvas = Canvas(imageRecorder);
    imageCanvas.scale(scale, scale);
    imageCanvas.drawPicture(picture);
    final scaledPicture = imageRecorder.endRecording();
    final newImage = await scaledPicture.toImage(thumbnailWidth.toInt(), thumbnailHeight);
    if (mounted) {
      setState(() {
        final oldImage = _thumbnailCache[page.id];
        _thumbnailCache[page.id] = newImage;
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
      widget.onPageChanged?.call(page);
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
    final topTexts = widget.topCanvasKey.currentState?.getTexts() ?? [];
    _historyManager.record(
      widget.pages,
      topStrokes,
      topImages: topImages,
      topTexts: topTexts,
    );
    _updateThumbnailCache(_currentPageIndex);
    setState(() {});
    widget.onChanged();
  }

  void _applyHistoryState(CanvasHistoryState state) {
    _numPages = state.pages.length;
    _pageHeight = _basePageHeight * _numPages;

    widget.pages.clear();
    widget.pages.addAll(state.pages.map((page) => NotePage(
      id: page.id,
      strokes: page.strokes.map((s) => s.copy()).toList(),
      images: page.images.map((i) => i.copy()).toList(),
      texts: page.texts.map((t) => t.copy()).toList(),
      background: page.background,
      source: PageSource(type: page.source.type, originalIndex: page.source.originalIndex),
    )).toList());

    _recomputeContentBounds();
    _clearThumbnailCache();
    for (int i = 0; i < _numPages; i++) {
      _updateThumbnailCache(i);
    }

    widget.topCanvasKey.currentState?.setStrokes(state.topLayer.map((s) => s.copy()).toList());
    widget.topCanvasKey.currentState?.setImages((state.topImages).map((i) => i.copy()).toList());
    widget.topCanvasKey.currentState?.setTexts((state.topTexts).map((t) => t.copy()).toList());
  }

  void _initializeFit(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _basePageHeight = mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
    _pageWidth = _basePageHeight * .707;

    _numPages = widget.pages.length;
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
      _onToolChanged(DrawingTool.eraser2);
    } else if (_selectedTool == DrawingTool.eraser2) {
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

    // If first touch is outside page area, suspend drawing to allow one-finger panning
    if (_activePointers.length == 1 && _lastScreenSize != null) {
      final zoom = _transformationController.zoom;
      final scale = _transformationController.scale;
      final offset = _transformationController.offset;

      final pageRect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        _pageWidth * scale,
        _pageHeight * scale,
      );

      if (!pageRect.contains(event.localPosition)) {
        _drawingSuspended = true;
      }
    }

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
      widget.onCommit([], [], []);
    }
  }

  void _handleRedo() {
    final state = _historyManager.redo();
    if (state != null) {
      _applyHistoryState(state);
      setState(() {});
      widget.onCommit([], [], []);
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
      
      final int pageIdx = (centerY / _basePageHeight).floor().clamp(0, widget.pages.length - 1);
      final relativePos = Offset(centerX - 100, (centerY - 100) - (pageIdx * _basePageHeight));

      final newImageData = ImageData(
        position: relativePos,
        imagePath: newPath,
      );

      setState(() {
        widget.pages[pageIdx].images.add(newImageData);
      });
      widget.onChanged();
      _recordHistory();
      _updateThumbnailCache(pageIdx);
    }
  }

  void _onToolChanged(DrawingTool tool) {
    if (tool == DrawingTool.duplicate) {
      widget.topCanvasKey.currentState?.setTool(tool);
      return;
    }

    setState(() {
      _selectedTool = tool;

      if (tool == DrawingTool.pen || tool == DrawingTool.eraser2) {
        _lastPenEraserTool = tool;
      }

      widget.topCanvasKey.currentState?.setTool(tool);

      if (tool == DrawingTool.pen || tool == DrawingTool.text) {
        widget.topCanvasKey.currentState?.setColor(_primaryColor);
      } else if (tool == DrawingTool.highlighter) {
        widget.topCanvasKey.currentState?.setColor(_highlighterPrimaryColor);
      }
    });
  }

  void _addPage(Size viewportSize, {int? atIndex}) {
    final insertIndex = atIndex != null ? atIndex + 1 : _currentPageIndex + 1;
    setState(() {
      widget.pages.insert(
        insertIndex.clamp(0, widget.pages.length),
        NotePage(source: PageSource.blank()),
      );

      _recomputeContentBounds();
      
      final thresholdY = insertIndex * _basePageHeight;
      final shiftDelta = Offset(0, _basePageHeight);
      widget.topCanvasKey.currentState?.shiftContent(thresholdY, shiftDelta);

      // Thumbnail cache remains valid for existing pages since it's ID-based.
      // We don't need to shift anything in _thumbnailCache anymore.

      if (atIndex == null) {
        _transformationController.setOffset(
          Offset(_transformationController.offset.dx, -thresholdY),
          viewportSize,
          _pageWidth,
          _pageHeight,
        );
      }
    });

    _recordHistory();
    _updateThumbnailCache(insertIndex);
  }

  void _duplicatePage(Size viewportSize, {int? atIndex}) {
    final index = atIndex ?? _currentPageIndex;
    final original = widget.pages[index];

    final duplicate = NotePage(
      source: PageSource(
        type: original.source.type,
        originalIndex: original.source.originalIndex,
      ),
      strokes: original.strokes.map((s) => s.copy()).toList(),
      images: original.images.map((i) => i.copy()).toList(),
      texts: original.texts.map((t) => t.copy()).toList(),
      background: original.background,
    );

    setState(() {
      final insertIndex = index + 1;
      widget.pages.insert(
        insertIndex.clamp(0, widget.pages.length),
        duplicate,
      );

      _recomputeContentBounds();

      final thresholdY = insertIndex * _basePageHeight;
      final shiftDelta = Offset(0, _basePageHeight);
      widget.topCanvasKey.currentState?.shiftContent(thresholdY, shiftDelta);

      if (atIndex == null) {
        _transformationController.setOffset(
          Offset(_transformationController.offset.dx, -thresholdY),
          viewportSize,
          _pageWidth,
          _pageHeight,
        );
      }
    });

    _recordHistory();
    _updateThumbnailCache(index + 1);
  }
  
  void _deletePage(Size viewportSize, {int? atIndex}) {
    if (_numPages <= 1) return;

    setState(() {
      final deleteIndex = atIndex ?? _currentPageIndex;
      final pageToDelete = widget.pages.removeAt(deleteIndex);

      _recomputeContentBounds();

      final pageStartY = deleteIndex * _basePageHeight;
      final pageEndY = (deleteIndex + 1) * _basePageHeight;
      final shiftDelta = Offset(0, -_basePageHeight);

      widget.topCanvasKey.currentState?.deletePageContent(pageStartY, pageEndY, shiftDelta);

      // Update thumbnail cache by ID
      final img = _thumbnailCache.remove(pageToDelete.id);
      img?.dispose();

      if (_currentPageIndex >= _numPages) {
        _currentPageIndex = _numPages - 1;
      }
    });

    _recordHistory();
  }

  void _movePage(int index, int direction) {
    int targetIndex = index + direction;
    if (targetIndex < 0 || targetIndex >= _numPages) return;

    setState(() {
      // 1. Swap pages
      final tempPage = widget.pages[index];
      widget.pages[index] = widget.pages[targetIndex];
      widget.pages[targetIndex] = tempPage;

      final pageStartY = index * _basePageHeight;
      final pageEndY = (index + 1) * _basePageHeight;
      final targetStartY = targetIndex * _basePageHeight;
      final targetEndY = (targetIndex + 1) * _basePageHeight;

      final shiftDown = Offset(0, (targetIndex - index) * _basePageHeight);
      final shiftUp = Offset(0, (index - targetIndex) * _basePageHeight);

      widget.topCanvasKey.currentState?.movePageContent(
        pageStartY, pageEndY, shiftDown,
        targetStartY, targetEndY, shiftUp,
      );

      // Thumbnail cache remains valid for existing pages since it's ID-based.

      _recordHistory();
    });

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
      _selectedTool = DrawingTool.eraser2;
      widget.topCanvasKey.currentState?.setTool(_selectedTool);
    });
  }

  void _eraseFromBottom(Offset position) {
    bool changed = false;
    final double threshold = (widget.topCanvasKey.currentState?.penSize ?? 1.0) * 2.0;
    final int pageIdx = (position.dy / _basePageHeight).floor().clamp(0, widget.pages.length - 1);
    final page = widget.pages[pageIdx];
    final relativePos = position - Offset(0, pageIdx * _basePageHeight);

    setState(() {
      final initialStrokeCount = page.strokes.length;
      page.strokes.removeWhere((stroke) => stroke.points.any((p) => (p - relativePos).distance < threshold));
      if (page.strokes.length != initialStrokeCount) changed = true;

      final initialImageCount = page.images.length;
      page.images.removeWhere((img) => img.getBounds().contains(relativePos));
      if (page.images.length != initialImageCount) changed = true;
      
      final initialTextCount = page.texts.length;
      page.texts.removeWhere((txt) => txt.getBounds().contains(relativePos));
      if (page.texts.length != initialTextCount) changed = true;
    });

    if (changed) {
      _recordHistory();
      _updateThumbnailCache(pageIdx);
    }
  }

  List<Stroke> _selectFromBottom(Path lassoPath) {
    final List<Stroke> selected = [];
    // For lasso, we might need to check multiple pages if the lasso spans them.
    // For simplicity, we check all pages.
    for (int i = 0; i < widget.pages.length; i++) {
      final page = widget.pages[i];
      final List<Stroke> remaining = [];
      final pageOffset = Offset(0, i * _basePageHeight);
      
      for (final stroke in page.strokes) {
        // Translate stroke to global for lasso check
        final globalStroke = stroke.translate(pageOffset);
        if (globalStroke.points.any((p) => lassoPath.contains(p))) {
          selected.add(globalStroke);
        } else {
          remaining.add(stroke);
        }
      }
      if (remaining.length != page.strokes.length) {
        setState(() {
          page.strokes.clear();
          page.strokes.addAll(remaining);
        });
        _updateThumbnailCache(i);
      }
    }
    if (selected.isNotEmpty) _recordHistory();
    return selected;
  }

  List<ImageData> _selectImagesFromBottom(Path lassoPath) {
    final List<ImageData> selected = [];
    for (int i = 0; i < widget.pages.length; i++) {
      final page = widget.pages[i];
      final List<ImageData> remaining = [];
      final pageOffset = Offset(0, i * _basePageHeight);
      
      for (final img in page.images) {
        final globalImg = img.translate(pageOffset);
        final bounds = globalImg.getBounds();
        if (lassoPath.contains(bounds.center)) {
          selected.add(globalImg);
        } else {
          remaining.add(img);
        }
      }
      if (remaining.length != page.images.length) {
        setState(() {
          page.images.clear();
          page.images.addAll(remaining);
        });
        _updateThumbnailCache(i);
      }
    }
    if (selected.isNotEmpty) _recordHistory();
    return selected;
  }
  
  List<TextData> _selectTextsFromBottom(Path lassoPath) {
    final List<TextData> selected = [];
    for (int i = 0; i < widget.pages.length; i++) {
      final page = widget.pages[i];
      final List<TextData> remaining = [];
      final pageOffset = Offset(0, i * _basePageHeight);
      
      for (final txt in page.texts) {
        final globalTxt = txt.translate(pageOffset);
        final bounds = globalTxt.getBounds();
        if (lassoPath.contains(bounds.center)) {
          selected.add(globalTxt);
        } else {
          remaining.add(txt);
        }
      }
      if (remaining.length != page.texts.length) {
        setState(() {
          page.texts.clear();
          page.texts.addAll(remaining);
        });
        _updateThumbnailCache(i);
      }
    }
    if (selected.isNotEmpty) _recordHistory();
    return selected;
  }

  void _onColorChanged(Color color) {
    setState(() {
      if (_selectedTool == DrawingTool.highlighter) {
        // Standardize alpha for highlighter comparisons and storage
        final highlighterColor = color.withAlpha(77);
        
        if (highlighterColor.value == _highlighterSecondaryColor.value) {
          final temp = _highlighterPrimaryColor;
          _highlighterPrimaryColor = _highlighterSecondaryColor;
          _highlighterSecondaryColor = temp;
        } else if (highlighterColor.value == _highlighterThirdColor.value) {
          final temp = _highlighterPrimaryColor;
          _highlighterPrimaryColor = _highlighterThirdColor;
          _highlighterThirdColor = temp;
        } else if (highlighterColor.value == _highlighterFourthColor.value) {
          final temp = _highlighterPrimaryColor;
          _highlighterPrimaryColor = _highlighterFourthColor;
          _highlighterFourthColor = temp;
        } else {
          _highlighterPrimaryColor = highlighterColor;
        }
        widget.topCanvasKey.currentState?.setColor(_highlighterPrimaryColor);
      } else {
        if (color.value == _secondaryColor.value) {
          final temp = _primaryColor;
          _primaryColor = _secondaryColor;
          _secondaryColor = temp;
        } else if (color.value == _thirdColor.value) {
          final temp = _primaryColor;
          _primaryColor = _thirdColor;
          _thirdColor = temp;
        } else if (color.value == _fourthColor.value) {
          final temp = _primaryColor;
          _primaryColor = _fourthColor;
          _fourthColor = temp;
        } else {
          _primaryColor = color;
        }
        widget.topCanvasKey.currentState?.setColor(_primaryColor);
      }
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _lastScreenSize != null) {
      final newOffset = _transformationController.offset - event.scrollDelta;
      _transformationController.setOffset(
        newOffset,
        _lastScreenSize!,
        _pageWidth,
        _pageHeight,
      );
    }
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

        if (_basePageHeight <= 0) {
           _basePageHeight = safeHeight;
           _pageWidth = _basePageHeight * .707;
           _pageHeight = _basePageHeight * widget.pages.length;
           _transformationController.initialize(
              pageWidth: _pageWidth,
              viewportWidth: safeWidth,
           );
        }

        return SizedBox(
          width: safeWidth,
          height: safeHeight,
          child: ClipRect(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              onPointerSignal: _onPointerSignal,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  if (details.pointerCount >= 2 || _drawingSuspended) {
                    _isTransforming = true;
                    _transformationController.handleScaleStart(details);
                  }
                },
                onScaleUpdate: (details) {
                  if (details.pointerCount >= 2 || _drawingSuspended) {
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
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: CanvasBackground(
                                  pages: widget.pages,
                                  pageWidth: _pageWidth,
                                  basePageHeight: _basePageHeight,
                                  paperType: widget.paperType,
                                  resolvePageBackground: widget.resolvePageBackground,
                                  currentPage: _currentPageIndex,
                                ),
                              ),
                              ...List.generate(widget.pages.length, (i) {
                                if ((i - _currentPageIndex).abs() > 1) {
                                  return Positioned(
                                    top: i * _basePageHeight,
                                    child: SizedBox(width: _pageWidth, height: _basePageHeight),
                                  );
                                }
                                final page = widget.pages[i];
                                return Positioned(
                                  top: i * _basePageHeight,
                                  child: Container(
                                    width: _pageWidth,
                                    height: _basePageHeight,
                                    color: Colors.transparent, // Important: let background show through
                                    child: Stack(
                                      children: [
                                        ...page.images.map((img) => Positioned(
                                          left: img.position.dx,
                                          top: img.position.dy,
                                          child: Image.file(
                                            File(img.imagePath),
                                            width: img.width,
                                            height: img.height,
                                            fit: BoxFit.contain,
                                          ),
                                        )),
                                        ...page.texts.map((txt) => Positioned(
                                          left: txt.position.dx,
                                          top: txt.position.dy,
                                          width: txt.width,
                                          height: txt.height,
                                          child: Text(
                                            txt.text,
                                            style: TextStyle(fontSize: txt.fontSize, color: txt.color),
                                          ),
                                        )),
                                        BottomCanvas(strokes: page.strokes),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: icon_color.withAlpha(20),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: TopCanvas(
                                    key: widget.topCanvasKey,
                                    onCommit: (strokes, images, texts) {
                                      if (_basePageHeight <= 0) return;
                                      for (final s in strokes) {
                                        final centerY = s.getBounds().center.dy;
                                        final idx = (centerY / _basePageHeight).floor().clamp(0, widget.pages.length - 1);
                                        widget.pages[idx].strokes.add(s.translate(Offset(0, -idx * _basePageHeight)));
                                      }
                                      for (final img in images) {
                                        final centerY = img.getBounds().center.dy;
                                        final idx = (centerY / _basePageHeight).floor().clamp(0, widget.pages.length - 1);
                                        widget.pages[idx].images.add(img.translate(Offset(0, -idx * _basePageHeight)));
                                      }
                                      for (final txt in texts) {
                                        final centerY = txt.getBounds().center.dy;
                                        final idx = (centerY / _basePageHeight).floor().clamp(0, widget.pages.length - 1);
                                        widget.pages[idx].texts.add(txt.translate(Offset(0, -idx * _basePageHeight)));
                                      }
                                      widget.onCommit(strokes, images, texts);
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
                                    onSelectTextsFromBottom: _selectTextsFromBottom,
                                  ),
                                ),
                              ],
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
                            () {
                          // Just trigger a pop request. PopScope in HandwrittenNotePage will handle saving if needed.

                              widget.onBack?.call();
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
                          currentSize: widget.topCanvasKey.currentState?.penSize ?? 1.0,
                          onIncrementSize: () => widget.topCanvasKey.currentState?.changeSize(0.5),
                          onDecrementSize: () => widget.topCanvasKey.currentState?.changeSize(-0.5),
                          onSizeDelta: (delta) => widget.topCanvasKey.currentState?.changeSize(delta),
                          onSwitchEraserType: _switchEraserType,
                          currentPenColor: (_selectedTool == DrawingTool.highlighter)
                              ? _highlighterPrimaryColor
                              : _primaryColor,
                          quickColors: (_selectedTool == DrawingTool.highlighter)
                              ? [
                                  _highlighterSecondaryColor,
                                  _highlighterThirdColor,
                                  _highlighterFourthColor,
                                ]
                              : [
                                  _secondaryColor,
                                  _thirdColor,
                                  _fourthColor,
                                ],
                          onColorChanged: _onColorChanged,
                          onOpenColorPicker: () => setState(() => _showColorPicker = !_showColorPicker),
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                    if (_showColorPicker)
                      Padding(
                        padding: const EdgeInsets.only(left: 80),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TapRegion(
                            onTapOutside: (event) {
                              setState(() {
                                _showColorPicker = false;
                              });
                            },
                            child: CanvasColorPickerOverlay(
                              initialColor: (_selectedTool == DrawingTool.highlighter)
                                  ? _highlighterPrimaryColor
                                  : _primaryColor,
                              onColorChanged: _onColorChanged,
                              onDismiss: () => setState(() => _showColorPicker = false),
                            ),
                          ),
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
                        child: PageListView(
                          currentPage: _currentPageIndex,
                          numPages: _numPages,
                          onMovePage: _movePage,
                          onAddPageBelow: (index) => _addPage(viewportSize, atIndex: index),
                          onDuplicatePage: (index) => _duplicatePage(viewportSize, atIndex: index),
                          onDeletePage: (index) => _deletePage(viewportSize, atIndex: index),
                          onPageTap: _scrollToPage,
                          onClose: () => setState(() => _showPageManager = false),
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
          ));
      },
    );
  }
}
