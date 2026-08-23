import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/canvas_options.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import '../../app_style.dart';
import '../../models/HandwrittenNote.dart' show Stroke;
import '../../widgets/glass_container.dart';
import '../../widgets/full_color_picker.dart';
import 'DualCanvas.dart';

class CanvasHistoryState {
  final List<Stroke> bottomLayer;
  final List<Stroke> topLayer;

  CanvasHistoryState({required this.bottomLayer, required this.topLayer});

  factory CanvasHistoryState.capture(List<Stroke> bottom, List<Stroke> top) {
    return CanvasHistoryState(
      bottomLayer: List.from(bottom),
      topLayer: List.from(top),
    );
  }
}

class CanvasView extends StatefulWidget {
  final List<Stroke> bottomLayerStrokes;
  final void Function(List<Stroke> strokes) onCommit;

  final GlobalKey<BottomCanvasState> bottomCanvasKey;
  final GlobalKey<TopCanvasState> topCanvasKey;

  const CanvasView({
    super.key,
    required this.bottomLayerStrokes,
    required this.onCommit,
    required this.bottomCanvasKey,
    required this.topCanvasKey,
  });

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {

  static const double _minZoom = 1.0;
  static const double _maxZoom = 6.0;

  double _referenceScale = 1.0;
  double _zoom = 1.0;
  Offset _offset = Offset.zero;
  Size? _lastScreenSize;
  double _gestureStartZoom = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  final Set<int> _activePointers = <int>{};

  bool _drawingSuspended = false;

  DrawingTool _selectedTool = DrawingTool.pen;
  Color _primaryColor = Colors.black;
  Color _secondaryColor = Colors.blue;
  bool _showColorPicker = false;

  final List<CanvasHistoryState> _history = [];
  int _historyIndex = -1;

  late double _pageWidth;
  late double _pageHeight;

  double get _scale => _referenceScale * _zoom;

  double get_zoom(){
    return _zoom;
  }

  Matrix4 get _matrix {
    return Matrix4.identity()
      ..translateByVector3(Vector3(_offset.dx, _offset.dy, 0,),)
      ..scaleByVector3(Vector3(_scale, _scale, 1,),);
  }

  Size _getSafeAreaSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Size(
      mediaQuery.size.width -mediaQuery.padding.left - mediaQuery.padding.right,
      mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom,
    );
  }

  void _initializeFit(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _pageHeight = mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
    _pageWidth = _pageHeight * .707;

    _referenceScale = 1.0;
    _zoom = 1.0;

    final viewportWidth = mediaQuery.size.width;

    _offset = Offset(
      (viewportWidth - _pageWidth) / 2,
      0,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordHistory();
    });
  }

  void _recordHistory() {
    final bottom = widget.bottomLayerStrokes;
    final top = widget.topCanvasKey.currentState?.getStrokes() ?? [];

    final newState = CanvasHistoryState.capture(bottom, top);

    // Don't record duplicate states
    if (_historyIndex >= 0) {
      final lastState = _history[_historyIndex];
      if (_areStatesEqual(lastState, newState)) {
        return;
      }
    }

    // If we're not at the end of the history, remove the "future"
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(newState);
    _historyIndex++;

    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  bool _areStatesEqual(CanvasHistoryState a, CanvasHistoryState b) {
    if (a.bottomLayer.length != b.bottomLayer.length) return false;
    if (a.topLayer.length != b.topLayer.length) return false;
    
    // Simple check: compare list references if possible, but they are copied.
    // We could check if the elements are the same.
    for (int i = 0; i < a.bottomLayer.length; i++) {
      if (a.bottomLayer[i] != b.bottomLayer[i]) return false;
    }
    for (int i = 0; i < a.topLayer.length; i++) {
      if (a.topLayer[i] != b.topLayer[i]) return false;
    }
    return true;
  }

  void _applyHistoryState(CanvasHistoryState state) {
    widget.bottomLayerStrokes.clear();
    widget.bottomLayerStrokes.addAll(state.bottomLayer);
    widget.bottomCanvasKey.currentState?.update();

    widget.topCanvasKey.currentState?.setStrokes(state.topLayer);
  }

  Offset _clampOffset(Offset offset, double scale, Size viewportSize,) {
    final pageWidth = _pageWidth * scale;
    final pageHeight = _pageHeight * scale;

    double x = offset.dx;
    double y = offset.dy;

    if (pageWidth <= viewportSize.width) {
      x = (viewportSize.width - pageWidth) / 2;
    } else {
      final minX = viewportSize.width - pageWidth;
      const maxX = 0.0;
      x = x.clamp(minX, maxX);
    }

    if (pageHeight <= viewportSize.height) {
      y = 0;
    } else {
      final minY = viewportSize.height - pageHeight;
      const maxY = 0.0;
      y = y.clamp(minY, maxY);
    }
    return Offset(x, y);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointers == 0) {_drawingSuspended = false;}
    if (_activePointers.length > 1) {
      _drawingSuspended = true;
      return;
    }
    _activePointers.add(event.pointer);

    if (_activePointers.length == 2) {
      _drawingSuspended = true;
      widget.topCanvasKey.currentState?.cancelCurrentStroke();
      return;
    }

  }

  void _onPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length != 2) {
      _drawingSuspended = false;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_activePointers.length != 2) {
      return;
    }
    _drawingSuspended = true;
    _gestureStartZoom = _zoom;
    _gestureStartOffset = _offset;
    _gestureStartFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_activePointers.length != 2) {return;}

    final newZoom = (_gestureStartZoom * details.scale).clamp(_minZoom, _maxZoom);

    final startScale = _referenceScale * _gestureStartZoom;

    final newScale = _referenceScale * newZoom;

     final canvasPointUnderFocal = ( _gestureStartFocal - _gestureStartOffset ) / startScale;

    Offset newOffset = details.localFocalPoint - canvasPointUnderFocal * newScale;

    final viewportSize = _getSafeAreaSize(context);

    newOffset = _clampOffset(newOffset, newScale, viewportSize,);

    setState(() {_zoom = newZoom;_offset = newOffset;});
  }

  void _handleUndo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _applyHistoryState(_history[_historyIndex]);
      setState(() {});
      // Inform parent of the change
      widget.onCommit([]);
    }
  }

  void _handleRedo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _applyHistoryState(_history[_historyIndex]);
      setState(() {});
      widget.onCommit([]);
    }
  }

  void _switchEraserType() {
    setState(() {
      if (_selectedTool == DrawingTool.eraser) {
        _selectedTool = DrawingTool.eraser2;
      } else {
        _selectedTool = DrawingTool.eraser;
      }
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

  void _onColorChanged(Color color) {
    setState(() {
      if (color == _secondaryColor) {
        final temp = _primaryColor;
        _primaryColor = _secondaryColor;
        _secondaryColor = temp;
      } else {
        _primaryColor = color;
      }
      widget.topCanvasKey.currentState?.setColor(_primaryColor);
    });
  }

  void _openColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenSize = mediaQuery.size;

    if (_lastScreenSize != screenSize) {_initializeFit(context);_lastScreenSize = screenSize;}

    final safeWidth = screenSize.width - mediaQuery.padding.left - mediaQuery.padding.right;

    final safeHeight = screenSize.height - mediaQuery.padding.top -mediaQuery.padding.bottom;

    return SizedBox(
      width: safeWidth, height: safeHeight,
      child: ClipRect(
        child: Listener(
          onPointerDown: _onPointerDown, onPointerUp: _onPointerUp, onPointerCancel: _onPointerUp,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, onScaleStart: _onScaleStart, onScaleUpdate: _onScaleUpdate,
            child: Stack(
              children: [
                Transform(
                  alignment: Alignment.topLeft, transform: _matrix,
                  child: SizedBox(
                    width: _pageWidth, height: _pageHeight,
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: BG),
                          RepaintBoundary(child: BottomCanvas(key: widget.bottomCanvasKey, strokes: widget.bottomLayerStrokes,),),
                          TopCanvas(
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
                            zoom: get_zoom,
                            onEraseFromBottom: _eraseFromBottom,
                          ),

                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: top_button_array(
                    context,
                    _handleUndo,
                    _handleRedo,
                    canUndo: _historyIndex > 0,
                    canRedo: _historyIndex < _history.length - 1,
                    selectedTool: _selectedTool,
                    onToolChanged: (tool) {
                      setState(() {
                        _selectedTool = tool;
                        widget.topCanvasKey.currentState?.setTool(tool);
                        if (tool == DrawingTool.pen) {
                          widget.topCanvasKey.currentState?.setColor(_primaryColor);
                        }
                      });
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: left_button_array(
                      context,
                      selectedTool: _selectedTool,
                      currentSize: widget.topCanvasKey.currentState?.penSize ?? 0.5,
                      onIncrementSize: () {
                        widget.topCanvasKey.currentState?.changeSize(0.5);
                      },
                      onDecrementSize: () {
                        widget.topCanvasKey.currentState?.changeSize(-0.5);
                      },
                      onSizeDelta: (delta) {
                        widget.topCanvasKey.currentState?.changeSize(delta);
                      },
                      onSwitchEraserType: _switchEraserType,
                      currentPenColor: _primaryColor,
                      secondaryPenColor: _secondaryColor,
                      onColorChanged: _onColorChanged,
                      onOpenColorPicker: _openColorPicker,
                    ),
                  ),
                ),
                if (_showColorPicker)
                  Positioned(
                    left: 80,
                    bottom: 20,
                    child: glassContainer(
                      width: 250,
                      height: 350,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: FullColorPicker(
                                initialColor: _primaryColor,
                                onColorChanged: _onColorChanged,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Quick presets
                            SizedBox(
                              height: 30,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Colors.black, Colors.white, Colors.red, Colors.blue,
                                  Colors.green, Colors.orange, Colors.purple, Colors.yellow,
                                ].map((color) => GestureDetector(
                                  onTap: () => _onColorChanged(color),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => setState(() => _showColorPicker = false),
                              child: Text("Done", style: AppStyles.icon_text.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}