import 'package:flutter/material.dart';
import '../../models/stroke.dart';
import 'HandwritingPainter.dart';

class BottomCanvas extends StatefulWidget {
  final List<Stroke> strokes;

  const BottomCanvas({
    super.key,
    required this.strokes,
  });

  @override
  State<BottomCanvas> createState() => BottomCanvasState();
}

class BottomCanvasState extends State<BottomCanvas> {
  void updateStrokes(List<Stroke> strokes) {
    setState(() {});
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HandwritingPainter(
        strokes: widget.strokes,
        currentStroke: null,
      ),
      child: const SizedBox.expand(),
    );
  }
}
