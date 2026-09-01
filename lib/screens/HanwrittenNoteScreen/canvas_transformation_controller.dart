import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

class CanvasTransformationController extends ChangeNotifier {
  static const double minZoom = 0.6;
  static const double maxZoom = 6.0;

  double _referenceScale = 1.0;
  double _zoom = 1.0;
  Offset _offset = Offset.zero;

  double _gestureStartZoom = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  double get zoom => _zoom;
  Offset get offset => _offset;
  double get scale => _referenceScale * _zoom;

  Matrix4 get matrix {
    return Matrix4.identity()
      ..translateByVector3(Vector3(_offset.dx, _offset.dy, 0))
      ..scaleByVector3(Vector3(scale, scale, 1));
  }

  void initialize({
    required double pageWidth,
    required double viewportWidth,
    double referenceScale = 1.0,
  }) {
    _referenceScale = referenceScale;
    _zoom = 1.0;
    _offset = Offset((viewportWidth - pageWidth) / 2, 0);
    notifyListeners();
  }

  void handleScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = _zoom;
    _gestureStartOffset = _offset;
    _gestureStartFocal = details.localFocalPoint;
  }

  void handleScaleUpdate(
    ScaleUpdateDetails details,
    Size viewportSize,
    double pageWidth,
    double pageHeight,
  ) {
    final newZoom = (_gestureStartZoom * details.scale).clamp(minZoom, maxZoom);
    final startScale = _referenceScale * _gestureStartZoom;
    final newScale = _referenceScale * newZoom;

    final canvasPointUnderFocal = (_gestureStartFocal - _gestureStartOffset) / startScale;
    Offset newOffset = details.localFocalPoint - canvasPointUnderFocal * newScale;

    _zoom = newZoom;
    _offset = clampOffset(newOffset, newScale, viewportSize, pageWidth, pageHeight);
    notifyListeners();
  }

  Offset clampOffset(
    Offset offset,
    double scale,
    Size viewportSize,
    double pageWidth,
    double pageHeight,
  ) {
    final scaledWidth = pageWidth * scale;
    final scaledHeight = pageHeight * scale;

    double x = offset.dx;
    double y = offset.dy;

    if (scaledWidth <= viewportSize.width) {
      x = (viewportSize.width - scaledWidth) / 2;
    } else {
      final minX = viewportSize.width - scaledWidth;
      const maxX = 0.0;
      x = x.clamp(minX, maxX);
    }

    if (scaledHeight <= viewportSize.height) {
      y = 0;
    } else {
      final minY = viewportSize.height - scaledHeight;
      const maxY = 0.0;
      y = y.clamp(minY, maxY);
    }
    return Offset(x, y);
  }

  void setOffset(Offset newOffset, Size viewportSize, double pageWidth, double pageHeight) {
    _offset = clampOffset(newOffset, scale, viewportSize, pageWidth, pageHeight);
    notifyListeners();
  }
}
