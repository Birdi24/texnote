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

  const TopCanvas({super.key, required this.onCommit, this.onChanged, required this.suspended,required this.zoom});
  @override
  State<TopCanvas> createState() => TopCanvasState();
}

class TopCanvasState extends State<TopCanvas> {
  Stroke? _currentStroke;
  List<Stroke> _toplayer = [];

  static const int kMaxPointsPerSegment = 300;
  static const int kSegmentOverlap = 8;

  double penSize = .5;
  Color penColor = icon_color;
  int topStrokeLen = 0;

  void setTool(DrawingTool tool) {
    setState(() {
      if (tool == DrawingTool.pen) {
        penColor = icon_color;
        penSize = .5;
      } else {
        penColor = BG;
        penSize = 10.0;
      }
    });
  }

  final List<Stroke> _redoStack = [];

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
    _redoStack.clear();

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
  void setStroke(strokes) {
    setState(() {
      _toplayer = strokes;
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
    });
  }

  bool get canUndo => _toplayer.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_toplayer.isEmpty) return;

    setState(() {
      final stroke = _toplayer.removeLast();
      _redoStack.add(stroke);
      if (stroke.hasEndCap) {
        topStrokeLen--;
      }
    });

    widget.onChanged?.call();
    // Signal commit to sync the full stroke list if necessary
    widget.onCommit([]);
  }

  void redo() {
    if (_redoStack.isEmpty) {
      debugPrint("redo empty");
      return;
    }

    setState(() {
      final stroke = _redoStack.removeLast();
      _toplayer.add(stroke);
      if (stroke.hasEndCap) {
        topStrokeLen++;
      }
    });

    widget.onChanged?.call();
    widget.onCommit([]);
  }
  void update(){
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        onPointerDown: (event) {_startStroke(event.localPosition);},
        onPointerMove: (event) {_updateStroke(event.localPosition);},
        onPointerUp: (_) {_endStroke();},
        onPointerCancel: (_) {_endStroke();},

        child: CustomPaint(
          painter: HandwritingPainter(strokes: _toplayer, currentStroke: _currentStroke,),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}