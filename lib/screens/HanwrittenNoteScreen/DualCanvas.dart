import 'package:flutter/cupertino.dart';
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

  const TopCanvas({super.key, required this.onCommit, this.onChanged, required this.suspended,required this.zoom, this.onEraseFromBottom});
  @override
  State<TopCanvas> createState() => TopCanvasState();
}

class TopCanvasState extends State<TopCanvas> {
  Stroke? _currentStroke;
  List<Stroke> _toplayer = [];

  double _penSize = .5;
  double _eraserSize = 1.0;
  DrawingTool _selectedTool = DrawingTool.pen;
  int kMaxPointsPerSegment = 300;
  int kSegmentOverlap = 8;

  double penSize = .5;
  Color penColor = icon_color;
  int topStrokeLen = 0;

  void setTool(DrawingTool tool) {
    _selectedTool = tool;
    setState(() {
      if (tool == DrawingTool.pen) {
        penColor = icon_color;
        penSize = _penSize;
      } else if (tool == DrawingTool.eraser || tool == DrawingTool.eraser2) {
        penColor = BG;
        penSize = _eraserSize;
      }
    });
  }

  void changeSize(double delta) {
    setState(() {
      if (_selectedTool == DrawingTool.pen) {
        _penSize = (_penSize + delta).clamp(0.1, 50.0);
        penSize = _penSize;
      } else {
        _eraserSize = (_eraserSize + delta).clamp(0.1, 50.0);
        penSize = _eraserSize;
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
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else {
            _startStroke(event.localPosition);
          }
        },
        onPointerMove: (event) {
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else {
            _updateStroke(event.localPosition);
          }
        },
        onPointerUp: (_) {
          if (_selectedTool != DrawingTool.eraser2) {
            _endStroke();
          }
        },
        onPointerCancel: (_) {
          if (_selectedTool != DrawingTool.eraser2) {
            _endStroke();
          }
        },

        child: CustomPaint(
          painter: HandwritingPainter(strokes: _toplayer, currentStroke: _currentStroke,),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}