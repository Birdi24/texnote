import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/canvas_options.dart';

import '../../app_style.dart';
import '../../models/HandwrittenNote.dart';
import 'HandwritingPainter.dart';

class BottomCanvas extends StatefulWidget {
  final List<Stroke> strokes;

  const BottomCanvas({super.key, required this.strokes,});

  @override
  State<BottomCanvas> createState() => BottomCanvasState();
}

class BottomCanvasState extends State<BottomCanvas> {

  void updateStrokes(List<Stroke> strokes) {setState(() {});}

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HandwritingPainter( strokes: widget.strokes, currentStroke: null,),
      child: const SizedBox.expand(),
    );
  }

  void update(){
    setState(() {
    });
  }

}

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

enum _LassoMode { lassoing, moving, resizing, none }

class TopCanvasState extends State<TopCanvas> {
  Stroke? _currentStroke;
  List<Stroke> _toplayer = [];
  List<Stroke> _selectedStrokes = [];
  List<Offset> _lassoPoints = [];
  Path? _lassoPath;
  Rect? _selectionRect;
  Offset? _lastPointerPos;
  _LassoMode _currentLassoMode = _LassoMode.none;

  double _penSize = 3.0;
  double _eraserSize = 10.0;
  double _highlighterSize = 10.0;
  DrawingTool _selectedTool = DrawingTool.pen;
  int kMaxPointsPerSegment = 300;
  int kSegmentOverlap = 8;

  double penSize = 3.0;
  Color penColor = icon_color;
  int topStrokeLen = 0;

  void setTool(DrawingTool tool) {
    if (tool == DrawingTool.duplicate) {
      duplicateSelectedStrokes();
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
      
      // If switching from lasso to a drawing tool, commit selection
      bool wasLassoTool = oldTool == DrawingTool.lasso;
      bool isDrawingTool = tool == DrawingTool.pen || tool == DrawingTool.eraser || tool == DrawingTool.eraser2 || tool == DrawingTool.highlighter;
      
      if (wasLassoTool && isDrawingTool && _selectedStrokes.isNotEmpty) {
        _toplayer.addAll(_selectedStrokes);
        _selectedStrokes = [];
        _selectionRect = null;
      }
    });
  }

  void duplicateSelectedStrokes() {
    if (_selectedStrokes.isEmpty) return;

    final List<Stroke> copies = _selectedStrokes.map((s) => s.copy()).toList();
    const Offset offset = Offset(20, 20);
    for (final stroke in copies) {
      stroke.translate(offset);
    }

    setState(() {
      _toplayer.addAll(_selectedStrokes);
      _selectedStrokes = copies;
      _updateSelectionRect();
    });
    widget.onChanged?.call();
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

  void _updateSelectionRect() {
    if (_selectedStrokes.isEmpty) {
      _selectionRect = null;
      return;
    }
    
    Rect bounds = _selectedStrokes.first.getBounds();
    for (final stroke in _selectedStrokes.skip(1)) {
      bounds = bounds.expandToInclude(stroke.getBounds());
    }
    _selectionRect = bounds.inflate(5.0);
  }

  void _selectStrokesInLasso() {
    if (_lassoPath == null) return;
    
    final selectionPath = Path.from(_lassoPath!)..close();
    
    // Select from top layer
    final List<Stroke> newlySelected = [];
    final List<Stroke> remainingTop = [];
    
    for (final stroke in _toplayer) {
      bool isInside = stroke.points.any((p) => selectionPath.contains(p));
      if (isInside) {
        newlySelected.add(stroke);
      } else {
        remainingTop.add(stroke);
      }
    }
    
    // Select from bottom layer via callback
    final fromBottom = widget.onSelectFromBottom?.call(selectionPath) ?? [];
    newlySelected.addAll(fromBottom);
    
    setState(() {
      _toplayer = remainingTop;
      _selectedStrokes.addAll(newlySelected);
      _updateSelectionRect();
      _lassoPath = null;
      _lassoPoints = [];
    });
    
    if (newlySelected.isNotEmpty) {
      widget.onChanged?.call();
    }
  }

  void clearSelection() {
    setState(() {
      _toplayer.addAll(_selectedStrokes);
      _selectedStrokes = [];
      _selectionRect = null;
    });
    widget.onChanged?.call();
  }

  void setColor(Color color) {
    setState(() {
      penColor = color;
    });
    widget.onChanged?.call();
  }

  void _startLasso(Offset position) {
    if (_selectedStrokes.isNotEmpty) {
      _toplayer.addAll(_selectedStrokes);
      _selectedStrokes = [];
      _selectionRect = null;
    }
    setState(() {
      _lassoPoints = [position];
      _lassoPath = Path()..moveTo(position.dx, position.dy);
    });
  }

  void _updateLasso(Offset position) {
    setState(() {
      _lassoPoints.add(position);
      _lassoPath!.lineTo(position.dx, position.dy);
    });
  }

  void _handleMove(Offset delta) {
    if (_selectedStrokes.isEmpty) return;
    setState(() {
      for (final stroke in _selectedStrokes) {
        stroke.translate(delta);
      }
      _updateSelectionRect();
    });
    widget.onChanged?.call();
  }

  void _handleResize(Offset position, Offset delta) {
    if (_selectedStrokes.isEmpty || _selectionRect == null) return;
    
    // Basic scaling around center of selection rect
    final center = _selectionRect!.center;
    final oldDist = (position - delta - center).distance;
    final newDist = (position - center).distance;
    
    if (oldDist > 0) {
      final scaleFactor = newDist / oldDist;
      setState(() {
        for (final stroke in _selectedStrokes) {
          stroke.scale(scaleFactor, center);
        }
        _updateSelectionRect();
      });
      widget.onChanged?.call();
    }
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
      
      _selectedStrokes.removeWhere((stroke) {
        bool hit = stroke.points.any((p) => (p - position).distance < threshold);
        if (hit) {
          changed = true;
        }
        return hit;
      });
      if (changed) _updateSelectionRect();
    });

    if (changed) {
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
      widget.onChanged?.call();
      widget.onCommit([]);
    }

    widget.onEraseFromBottom?.call(position);
  }


  void cancelCurrentStroke() {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke = null;
    });
  }
  void _updateStroke(Offset position) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(position);
      if (_currentStroke!.points.length >= kMaxPointsPerSegment) {_splitCurrentStroke();}
    });
  }
  void _splitCurrentStroke() {
    final pts = _currentStroke!.points;
    final overlap = pts.sublist(pts.length - kSegmentOverlap);

    final finishedSegment = Stroke(
      points: pts, size: _currentStroke!.size, color: _currentStroke!.color, hasStartCap: _currentStroke!.hasStartCap, hasEndCap: false,
    );
    if (topStrokeLen >= 49) {
      _currentStroke = finishedSegment;
      _endStroke();
    }
    else {
      _toplayer.add(finishedSegment);
    }

    _currentStroke = Stroke(
      points: List<Offset>.from(overlap),
      size: _currentStroke!.size,
      color: _currentStroke!.color,
      hasStartCap: false,
      hasEndCap: true,
    );
  }
  void _startStroke(Offset position) {
    //double s = 0.04 *widget.zoom() +.6;

    setState(() {
      _currentStroke = Stroke(
        points: [position],
        size:  penSize ,
        color: penColor,
      );
    });
  }
  void _endStroke() {
    if (_currentStroke == null) return;
    topStrokeLen++;

    if (topStrokeLen >= 50) {
      final strokesToCommit = [..._toplayer, _currentStroke!,];
      _toplayer.clear();
      _currentStroke = null;
      topStrokeLen = 0;
      widget.onCommit(strokesToCommit);
      setState(() {});
      widget.onChanged?.call();
    }
    else {
      _toplayer.add(_currentStroke!);
      _currentStroke = null;
      setState(() {});
    }

    widget.onChanged?.call();
    debugPrint("top layer: ${_toplayer.length}");
  }
  void setStrokes(List<Stroke> strokes) {
    setState(() {
      _toplayer = List.from(strokes);
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
    });
  }

  List<Stroke> getStrokes() => List.from(_toplayer);

  bool get isTopLayerEmpty => _toplayer.isEmpty;

  void update(){
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        onPointerDown: (event) {
          _lastPointerPos = event.localPosition;
          
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else if (_selectedTool == DrawingTool.lasso) {
            if (_selectionRect != null) {
              const handleHitSize = 24.0;
              bool onHandle = Rect.fromCenter(center: _selectionRect!.topLeft, width: handleHitSize, height: handleHitSize).contains(event.localPosition) ||
                  Rect.fromCenter(center: _selectionRect!.topRight, width: handleHitSize, height: handleHitSize).contains(event.localPosition) ||
                  Rect.fromCenter(center: _selectionRect!.bottomLeft, width: handleHitSize, height: handleHitSize).contains(event.localPosition) ||
                  Rect.fromCenter(center: _selectionRect!.bottomRight, width: handleHitSize, height: handleHitSize).contains(event.localPosition);
              
              if (onHandle) {
                _currentLassoMode = _LassoMode.resizing;
              } else if (_selectionRect!.contains(event.localPosition)) {
                _currentLassoMode = _LassoMode.moving;
              } else {
                _currentLassoMode = _LassoMode.lassoing;
                _startLasso(event.localPosition);
              }
            } else {
              _currentLassoMode = _LassoMode.lassoing;
              _startLasso(event.localPosition);
            }
          } else {
            _startStroke(event.localPosition);
          }
        },
        onPointerMove: (event) {
          final delta = event.localPosition - (_lastPointerPos ?? event.localPosition);
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else if (_selectedTool == DrawingTool.lasso) {
            switch (_currentLassoMode) {
              case _LassoMode.lassoing:
                _updateLasso(event.localPosition);
                break;
              case _LassoMode.moving:
                _handleMove(delta);
                break;
              case _LassoMode.resizing:
                _handleResize(event.localPosition, delta);
                break;
              case _LassoMode.none:
                break;
            }
          } else {
            _updateStroke(event.localPosition);
          }
          _lastPointerPos = event.localPosition;
        },
        onPointerUp: (_) {
          if (_selectedTool == DrawingTool.lasso) {
            if (_currentLassoMode == _LassoMode.lassoing) {
              _selectStrokesInLasso();
            }
            _currentLassoMode = _LassoMode.none;
          } else if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
            _endStroke();
          }
          _lastPointerPos = null;
        },
        onPointerCancel: (_) {
          if (_selectedTool == DrawingTool.lasso) {
            if (_currentLassoMode == _LassoMode.lassoing) {
              setState(() {
                _lassoPath = null;
                _lassoPoints = [];
              });
            }
            _currentLassoMode = _LassoMode.none;
          } else if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
            _endStroke();
          }
          _lastPointerPos = null;
        },

        child: CustomPaint(
          painter: HandwritingPainter(
            strokes: _toplayer, 
            currentStroke: _currentStroke,
            selectedStrokes: _selectedStrokes,
            selectionRect: _selectionRect,
            lassoPath: _lassoPath,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
