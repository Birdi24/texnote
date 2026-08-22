import 'package:flutter/material.dart';
import '../../models/HandwrittenNote.dart';


class HandwritingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  HandwritingPainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      currentStroke!.invalidateCache(); // it's still changing — force recompute
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final path = stroke.buildPath(); // cached for finished strokes
    if (path.getBounds().isEmpty && stroke.points.length > 1) return;

    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    return true;
  }
}