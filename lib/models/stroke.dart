import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';


/// Represents a stroke of the pen in a handwritten note.
class Stroke {
  final List<Offset> points;
  double size;
  final Color color;

  /// the package I use rounds the corners of the stroke
  /// it is on and off depending on whether I have split a stroke into many pieces
  final bool hasStartCap;
  final bool hasEndCap;

  Path? _cachedPath;

  Stroke({
    required this.points,
    required this.size,
    required this.color,
    this.hasStartCap = true,
    this.hasEndCap = true,
  });

  /// translates the stroke by the given delta during the lasso move
  Stroke translate(Offset delta) {
    return Stroke(
      points: points.map((p) => p + delta).toList(),
      size: size,
      color: color,
      hasStartCap: hasStartCap,
      hasEndCap: hasEndCap,
    );
  }

  /// scales the stroke from the origin by the given scale factor during the lasso scale
  Stroke scale(double scaleFactor, Offset origin) {
    return Stroke(
      points: points.map((p) => origin + (p - origin) * scaleFactor).toList(),
      size: size * scaleFactor,
      color: color,
      hasStartCap: hasStartCap,
      hasEndCap: hasEndCap,
    );
  }

  /// returns the bounding box of the stroke for lasso selection
  Rect getBounds() {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(size / 2);
  }

  /// returns a copy of the stroke with the same points, size, color, and options
  Stroke copy() {
    return Stroke(
      points: List.from(points),
      size: size,
      color: color,
      hasStartCap: hasStartCap,
      hasEndCap: hasEndCap,
    );
  }

  /// clear the cache of the stroke
  void invalidateCache() => _cachedPath = null;

  /// returns the stroke as a path for drawing
  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'size': size,
      'color': color.value,
      'hasStartCap': hasStartCap,
      'hasEndCap': hasEndCap,
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      points: (map['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList(),
      size: (map['size'] as num).toDouble(),
      color: Color(map['color'] as int),
      hasStartCap: map['hasStartCap'] ?? true,
      hasEndCap: map['hasEndCap'] ?? true,
    );
  }

  Path buildPath() {
    if (_cachedPath != null) return _cachedPath!;

    final freehandPoints =
    points.map((p) => PointVector(p.dx, p.dy, 0.5)).toList();

    final outline = getStroke(
      freehandPoints,
      options: StrokeOptions(
        size: size,
        thinning: 0.5,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
        start: StrokeEndOptions.start(
          cap: hasStartCap,
          taperEnabled: false,
        ),
        end: StrokeEndOptions.end(
          cap: hasEndCap,
          taperEnabled: false,
        ),
      ),
    );

    final path = Path();

    /// This renders a closed polygon instead of a simple line because
    /// stroke thickness can change in different places or
    /// strokes can have curved or straight ends, making a closed polygon a
    /// better representation of the stroke than a line
    if (outline.isNotEmpty) {
      path.moveTo(outline.first.dx, outline.first.dy);
      for (final point in outline.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }

    _cachedPath = path;
    return path;
  }
}