import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/canvas_options.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import '../../app_style.dart';
import '../../models/HandwrittenNote.dart' show Stroke;
import 'DualCanvas.dart';

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



  /// Reference scale is always 1.0.
  double _referenceScale = 1.0;

  /// User zoom relative to the initial page size.
  double _zoom = 1.0;

  Offset _offset = Offset.zero;

  Size? _lastScreenSize;

  double _gestureStartZoom = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  final Set<int> _activePointers = <int>{};

  bool _drawingSuspended = false;

  DrawingTool _selectedTool = DrawingTool.pen;

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
    if (widget.topCanvasKey.currentState?.canUndo == true) {
      widget.topCanvasKey.currentState?.undo();
    }
    else {
      if (widget.bottomLayerStrokes.isNotEmpty) {
        final int takeCount = widget.bottomLayerStrokes.length > 50 ? 50 : widget.bottomLayerStrokes.length;
        final List<Stroke> strokesToMove = widget.bottomLayerStrokes.sublist(widget.bottomLayerStrokes.length - takeCount);

        widget.bottomLayerStrokes.removeRange(widget.bottomLayerStrokes.length - takeCount, widget.bottomLayerStrokes.length);
        widget.topCanvasKey.currentState?.setStroke(strokesToMove);
        widget.topCanvasKey.currentState?.undo();
        widget.bottomCanvasKey.currentState?.update();
      }
    }
    setState(() {});
  }

  void _handleRedo() {
    widget.topCanvasKey.currentState?.redo();
    setState(() {});
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
                            onCommit: widget.onCommit,
                            onChanged: () => setState(() {}),
                            suspended: () => _drawingSuspended,
                            zoom: get_zoom,
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
                    canUndo: (widget.topCanvasKey.currentState?.canUndo ?? false) || widget.bottomLayerStrokes.isNotEmpty,
                    canRedo: widget.topCanvasKey.currentState?.canRedo ?? false,
                    selectedTool: _selectedTool,
                    onToolChanged: (tool) {
                      setState(() {
                        _selectedTool = tool;
                        widget.topCanvasKey.currentState?.setTool(tool);
                      });
                    },
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