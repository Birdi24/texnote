import 'package:flutter/material.dart';
import '../../models/HandwrittenNote.dart';


class HandwritingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final List<Stroke> selectedStrokes;
  final Rect? selectionRect;
  final Path? lassoPath;

  HandwritingPainter({
    required this.strokes,
    required this.currentStroke,
    this.selectedStrokes = const [],
    this.selectionRect,
    this.lassoPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    
    // Draw selected strokes with a slight highlight if needed, or just normal
    for (final stroke in selectedStrokes) {
      _drawStroke(canvas, stroke, isSelected: true);
    }

    if (currentStroke != null) {
      currentStroke!.invalidateCache(); // it's still changing — force recompute
      _drawStroke(canvas, currentStroke!);
    }

    if (lassoPath != null) {
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      
      // Draw dashed line for lasso
      _drawDashedPath(canvas, lassoPath!, paint);
    }

    if (selectionRect != null) {
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawRect(selectionRect!, paint);
      
      // Draw handles
      final handlePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      
      const handleSize = 8.0;
      canvas.drawRect(Rect.fromCenter(center: selectionRect!.topLeft, width: handleSize, height: handleSize), handlePaint);
      canvas.drawRect(Rect.fromCenter(center: selectionRect!.topRight, width: handleSize, height: handleSize), handlePaint);
      canvas.drawRect(Rect.fromCenter(center: selectionRect!.bottomLeft, width: handleSize, height: handleSize), handlePaint);
      canvas.drawRect(Rect.fromCenter(center: selectionRect!.bottomRight, width: handleSize, height: handleSize), handlePaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke, {bool isSelected = false}) {
    if (stroke.points.isEmpty) return;

    final path = stroke.buildPath(); // cached for finished strokes
    if (path.getBounds().isEmpty && stroke.points.length > 1) return;

    final paint = Paint()
      ..color = isSelected ? stroke.color.withOpacity(0.7) : stroke.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
    
    if (isSelected) {
       final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.size + 2
      ..isAntiAlias = true;
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    return true;
  }
}