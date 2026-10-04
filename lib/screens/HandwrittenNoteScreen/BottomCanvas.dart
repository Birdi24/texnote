import 'package:flutter/material.dart';
import '../../models/stroke.dart';
import 'HandwritingPainter.dart';

class BottomCanvas extends StatelessWidget {
  final List<Stroke> strokes;

  const BottomCanvas({
    super.key,
    required this.strokes,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HandwritingPainter(
        strokes: strokes,
        currentStroke: null,
      ),
      child: const SizedBox.expand(),
    );
  }
}
