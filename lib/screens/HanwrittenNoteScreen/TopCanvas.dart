import 'package:flutter/material.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/canvas_options.dart';
import '../../app_style.dart';
import '../../models/HandwrittenNote.dart';
import 'HandwritingPainter.dart';
import 'lasso_manager.dart';

class TopCanvas extends StatefulWidget {
  final void Function(List<Stroke> strokes) onCommit;
  final VoidCallback? onChanged;
  final bool Function() suspended;
  final double Function() zoom;
  final void Function(Offset position)? onEraseFromBottom;
  final List<Stroke> Function(Path lassoPath)? onSelectFromBottom;

  const TopCanvas({
    super.key,
    required this.onCommit,
    this.onChanged,
    required this.suspended,
    required this.zoom,
    this.onEraseFromBottom,
    this.onSelectFromBottom,
  });

  @override
  State<TopCanvas> createState() => TopCanvasState();
}

class TopCanvasState extends State<TopCanvas> {
  Stroke? _currentStroke;
  List<Stroke> _toplayer = [];
  final LassoManager _lassoManager = LassoManager();
  Offset? _lastPointerPos;

  double _penSize = 3.0;
  double _eraserSize = 10.0;
  double _highlighterSize = 10.0;
  DrawingTool _selectedTool = DrawingTool.pen;
  
  static const int kMaxPointsPerSegment = 300;
  static const int kSegmentOverlap = 8;

  double penSize = 3.0;
  Color penColor = icon_color;
  int topStrokeLen = 0;

  void setTool(DrawingTool tool) {
    if (tool == DrawingTool.duplicate) {
      setState(() {
        _lassoManager.duplicateSelectedStrokes(_toplayer, widget.onChanged ?? () {});
      });
      return;
    }

    DrawingTool oldTool = _selectedTool;
    _selectedTool = tool;

    setState(() {
      if (tool == DrawingTool.pen) {
        penColor = icon_color;
        penSize = _penSize;
      } else if (tool == DrawingTool.eraser || tool == DrawingTool.eraser2) {
        penColor = BG;
        penSize = _eraserSize;
      } else if (tool == DrawingTool.highlighter) {
        penColor = Colors.yellow.withAlpha(77);
        penSize = _highlighterSize;
      }

      bool wasLassoTool = oldTool == DrawingTool.lasso;
      bool isDrawingTool = tool == DrawingTool.pen ||
          tool == DrawingTool.eraser ||
          tool == DrawingTool.eraser2 ||
          tool == DrawingTool.highlighter;

      if (wasLassoTool && isDrawingTool) {
        _lassoManager.clearSelection(_toplayer, widget.onChanged ?? () {});
      }
    });
  }

  void changeSize(double delta) {
    setState(() {
      if (_selectedTool == DrawingTool.pen) {
        _penSize = (_penSize + delta).clamp(0.1, 50.0);
        penSize = _penSize;
      } else if (_selectedTool == DrawingTool.eraser || _selectedTool == DrawingTool.eraser2) {
        _eraserSize = (_eraserSize + delta).clamp(0.1, 50.0);
        penSize = _eraserSize;
      } else if (_selectedTool == DrawingTool.highlighter) {
        _highlighterSize = (_highlighterSize + delta).clamp(0.1, 50.0);
        penSize = _highlighterSize;
      }
    });
    widget.onChanged?.call();
  }

  void setColor(Color color) {
    setState(() {
      penColor = color;
    });
    widget.onChanged?.call();
  }

  void _eraseStrokeAt(Offset position) {
    bool changed = false;
    final double threshold = penSize * 2.0;

    setState(() {
      _toplayer.removeWhere((stroke) {
        bool hit = stroke.points.any((p) => (p - position).distance < threshold);
        if (hit) changed = true;
        return hit;
      });

      _lassoManager.removeSelectedStrokes((stroke) {
        bool hit = stroke.points.any((p) => (p - position).distance < threshold);
        if (hit) changed = true;
        return hit;
      });
    });

    if (changed) {
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
      widget.onChanged?.call();
      widget.onCommit([]);
    }

    widget.onEraseFromBottom?.call(position);
  }

  void cancelCurrentStroke() {
    setState(() {
      _currentStroke = null;
      if (_lassoManager.currentMode == LassoMode.lassoing) {
        _lassoManager.lassoPath = null;
        _lassoManager.lassoPoints = [];
      }
      _lassoManager.currentMode = LassoMode.none;
    });
  }

  void _updateStroke(Offset position) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(position);
      if (_currentStroke!.points.length >= kMaxPointsPerSegment) {
        _splitCurrentStroke();
      }
    });
  }

  void _splitCurrentStroke() {
    final pts = _currentStroke!.points;
    final overlap = pts.sublist(pts.length - kSegmentOverlap);

    final finishedSegment = Stroke(
      points: pts,
      size: _currentStroke!.size,
      color: _currentStroke!.color,
      hasStartCap: _currentStroke!.hasStartCap,
      hasEndCap: false,
    );

    if (topStrokeLen >= 49) {
      _currentStroke = finishedSegment;
      _endStroke();
    } else {
      _toplayer.add(finishedSegment);
    }

    _currentStroke = Stroke(
      points: List<Offset>.from(overlap),
      size: penSize,
      color: penColor,
      hasStartCap: false,
      hasEndCap: true,
    );
  }

  void _startStroke(Offset position) {
    setState(() {
      _currentStroke = Stroke(
        points: [position],
        size: penSize,
        color: penColor,
      );
    });
  }

  void _endStroke() {
    if (_currentStroke == null) return;
    topStrokeLen++;

    if (topStrokeLen >= 50) {
      final strokesToCommit = [..._toplayer, _currentStroke!];
      _toplayer.clear();
      _currentStroke = null;
      topStrokeLen = 0;
      widget.onCommit(strokesToCommit);
    } else {
      _toplayer.add(_currentStroke!);
      _currentStroke = null;
    }
    setState(() {});
    widget.onChanged?.call();
  }

  void setStrokes(List<Stroke> strokes) {
    setState(() {
      _toplayer = List.from(strokes);
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
    });
  }

  List<Stroke> getStrokes() => List.from(_toplayer);

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        onPointerDown: (event) {
          if (widget.suspended()) return;
          _lastPointerPos = event.localPosition;

          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else if (_selectedTool == DrawingTool.lasso) {
            setState(() {
              if (_lassoManager.selectionRect != null) {
                const handleHitSize = 24.0;
                bool onHandle = Rect.fromCenter(
                  center: _lassoManager.selectionRect!.topLeft,
                  width: handleHitSize,
                  height: handleHitSize,
                ).contains(event.localPosition) ||
                Rect.fromCenter(
                  center: _lassoManager.selectionRect!.topRight,
                  width: handleHitSize,
                  height: handleHitSize,
                ).contains(event.localPosition) ||
                Rect.fromCenter(
                  center: _lassoManager.selectionRect!.bottomLeft,
                  width: handleHitSize,
                  height: handleHitSize,
                ).contains(event.localPosition) ||
                Rect.fromCenter(
                  center: _lassoManager.selectionRect!.bottomRight,
                  width: handleHitSize,
                  height: handleHitSize,
                ).contains(event.localPosition);

                if (onHandle) {
                  _lassoManager.currentMode = LassoMode.resizing;
                } else if (_lassoManager.selectionRect!.contains(event.localPosition)) {
                  _lassoManager.currentMode = LassoMode.moving;
                } else {
                  _lassoManager.startLasso(event.localPosition, _toplayer);
                }
              } else {
                _lassoManager.startLasso(event.localPosition, _toplayer);
              }
            });
          } else {
            _startStroke(event.localPosition);
          }
        },
        onPointerMove: (event) {
          if (widget.suspended()) return;
          final delta = event.localPosition - (_lastPointerPos ?? event.localPosition);
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else if (_selectedTool == DrawingTool.lasso) {
            setState(() {
              switch (_lassoManager.currentMode) {
                case LassoMode.lassoing:
                  _lassoManager.updateLasso(event.localPosition);
                  break;
                case LassoMode.moving:
                  _lassoManager.handleMove(delta, widget.onChanged ?? () {});
                  break;
                case LassoMode.resizing:
                  _lassoManager.handleResize(event.localPosition, delta, widget.onChanged ?? () {});
                  break;
                case LassoMode.none:
                  break;
              }
            });
          } else {
            _updateStroke(event.localPosition);
          }
          _lastPointerPos = event.localPosition;
        },
        onPointerUp: (_) {
          if (_selectedTool == DrawingTool.lasso) {
            setState(() {
              if (_lassoManager.currentMode == LassoMode.lassoing) {
                _lassoManager.selectStrokesInLasso(
                  topLayer: _toplayer,
                  onSelectFromBottom: widget.onSelectFromBottom ?? (p) => [],
                  onChanged: widget.onChanged ?? () {},
                );
              }
              _lassoManager.currentMode = LassoMode.none;
            });
          } else if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
            _endStroke();
          }
          _lastPointerPos = null;
        },
        onPointerCancel: (_) {
          if (_selectedTool == DrawingTool.lasso) {
            setState(() {
              if (_lassoManager.currentMode == LassoMode.lassoing) {
                _lassoManager.lassoPath = null;
                _lassoManager.lassoPoints = [];
              }
              _lassoManager.currentMode = LassoMode.none;
            });
          } else if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
            _endStroke();
          }
          _lastPointerPos = null;
        },
        child: CustomPaint(
          painter: HandwritingPainter(
            strokes: _toplayer,
            currentStroke: _currentStroke,
            selectedStrokes: _lassoManager.selectedStrokes,
            selectionRect: _lassoManager.selectionRect,
            lassoPath: _lassoManager.lassoPath,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
