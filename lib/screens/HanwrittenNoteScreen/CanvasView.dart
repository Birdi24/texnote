import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/canvas_options.dart';

import '../../app_style.dart';
import '../../models/HandwrittenNote.dart' show Stroke;
import '../../widgets/single_circle_button.dart';
import 'BottomCanvas.dart';
import 'TopCanvas.dart';
import 'CanvasBackground.dart';
import 'CanvasColorPickerOverlay.dart';
import 'canvas_history.dart';
import 'canvas_transformation_controller.dart';
import 'CanvasScrollbar.dart';

class CanvasView extends StatefulWidget {
  final List<Stroke> bottomLayerStrokes;
  final void Function(List<Stroke> strokes) onCommit;
  final GlobalKey<BottomCanvasState> bottomCanvasKey;
  final GlobalKey<TopCanvasState> topCanvasKey;
  final Future<void> Function() onSave;
  final bool changed;
  final VoidCallback onChanged;

  const CanvasView({
    super.key,
    required this.bottomLayerStrokes,
    required this.onCommit,
    required this.bottomCanvasKey,
    required this.topCanvasKey,
    required this.onSave,
    required this.changed,
    required this.onChanged,
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
  Color _primaryColor = Colors.black;
  Color _secondaryColor = Colors.indigo.shade900;
  Color _highlighterPrimaryColor = Colors.yellow.withAlpha(77);
  Color _highlighterSecondaryColor = Colors.green.withAlpha(77);
  bool _showColorPicker = false;

  late double _pageWidth;
  late double _pageHeight;
  double _basePageHeight = 0;
  int _numPages = 1;
  bool _isTransforming = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordHistory();
    });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    setState(() {});
  }

  void _recordHistory() {
    final top = widget.topCanvasKey.currentState?.getStrokes() ?? [];
    _historyManager.record(widget.bottomLayerStrokes, top, _numPages);
    setState(() {});
    widget.onChanged();
  }

  void _applyHistoryState(CanvasHistoryState state) {
    _numPages = state.numPages;
    _pageHeight = _basePageHeight * _numPages;
    
    widget.bottomLayerStrokes.clear();
    widget.bottomLayerStrokes.addAll(state.bottomLayer);
    widget.bottomCanvasKey.currentState?.update();
    widget.topCanvasKey.currentState?.setStrokes(state.topLayer);
  }

  Size _getSafeAreaSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Size(
      mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right,
      mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom,
    );
  }

  void _initializeFit(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _basePageHeight = mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
    _pageWidth = _basePageHeight * .707;
    _pageHeight = _basePageHeight * _numPages;

    _transformationController.initialize(
      pageWidth: _pageWidth,
      viewportWidth: mediaQuery.size.width,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointers.isEmpty) {
      _drawingSuspended = false;
    }
    _activePointers.add(event.pointer);

    if (_activePointers.length >= 2) {
      _drawingSuspended = true;
      widget.topCanvasKey.currentState?.cancelCurrentStroke();
    }
  }

  void _onPointerUp(PointerEvent event) {
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
      widget.onCommit([]);
    }
  }

  void _handleRedo() {
    final state = _historyManager.redo();
    if (state != null) {
      _applyHistoryState(state);
      setState(() {});
      widget.onCommit([]);
    }
  }

  void _onToolChanged(DrawingTool tool) {
    if (tool == DrawingTool.duplicate) {
      widget.topCanvasKey.currentState?.setTool(tool);
      return;
    }
    setState(() {
      _selectedTool = tool;
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
      _numPages++;
      _pageHeight = _basePageHeight * _numPages;
      _transformationController.setOffset(
        Offset(_transformationController.offset.dx, -_pageHeight),
        viewportSize,
        _pageWidth,
        _pageHeight,
      );
    });
    _recordHistory();
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
    });

    if (changed) {
      widget.bottomCanvasKey.currentState?.update();
      widget.onCommit([]);
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
      });
      widget.bottomCanvasKey.currentState?.update();
      widget.onCommit([]);
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
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
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
                      child: Transform(
                        alignment: Alignment.topLeft,
                        transform: _transformationController.matrix,
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
                                ),
                                RepaintBoundary(
                                  child: BottomCanvas(
                                    key: widget.bottomCanvasKey,
                                    strokes: widget.bottomLayerStrokes,
                                  ),
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
                                    onCommit: (strokes) {
                                      widget.onCommit(strokes);
                                      _recordHistory();
                                    },
                                    onChanged: () {
                                      setState(() {});
                                      _recordHistory();
                                    },
                                    suspended: () => _drawingSuspended,
                                    zoom: () => _transformationController.zoom,
                                    onEraseFromBottom: _eraseFromBottom,
                                    onSelectFromBottom: _selectFromBottom,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          single_circle_button(LucideIcons.chevron_left, 30.0, 90, "back",
                                  () async {if (widget.changed){ await widget.onSave();}Navigator.pop(context,true);},
                                  context, MediaQuery.of(context).size.width,button_width: 40, bgAlpha: 255),
                          const SizedBox(width: 10),
                          (MediaQuery.of(context).size.width < 750) ?
                          SizedBox.shrink():
                          history_button_array(
                            context,
                            _handleUndo,
                            _handleRedo,
                            canUndo: _historyManager.canUndo,
                            canRedo: _historyManager.canRedo,
                          ),
                        ],
                      ),
                    ),

                      Align(
                        alignment: Alignment.topCenter,
                        child: (MediaQuery.of(context).size.width >= 750)? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: tool_button_array(
                            context,
                            selectedTool: _selectedTool,
                            onToolChanged: _onToolChanged,
                            onAddPage: () => _addPage(viewportSize) )
                          ) : consolidated_tool_array(
                          context,
                          _handleUndo,
                          _handleRedo,
                          canUndo: _historyManager.canUndo,
                          canRedo: _historyManager.canRedo,
                          selectedTool: _selectedTool,
                          onToolChanged: _onToolChanged,
                          onAddPage: () => _addPage(viewportSize),
                        )
                        ),


                    Align(
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
                          currentPenColor: (_selectedTool == DrawingTool.highlighter) ? _highlighterPrimaryColor : _primaryColor,
                          secondaryPenColor: (_selectedTool == DrawingTool.highlighter) ? _highlighterSecondaryColor : _secondaryColor,
                          onColorChanged: _onColorChanged,
                          onOpenColorPicker: () => setState(() => _showColorPicker = !_showColorPicker),
                        ),
                      ),
                    ),
                    if (_showColorPicker)
                      Positioned(
                        left: 80,
                        bottom: 20,
                        child: CanvasColorPickerOverlay(
                          initialColor: (_selectedTool == DrawingTool.highlighter) ? _highlighterPrimaryColor : _primaryColor,
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
                    ),
                    Align(alignment: AlignmentGeometry.center, child: Text("width: ${MediaQuery.of(context).size.width}"),)
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
