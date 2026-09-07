import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Represents an image in a handwritten note.
class ImageData {
  Offset position;
  String imagePath;
  double scale;
  double width;
  double height;

  ImageData({
    required this.position,
    required this.imagePath,
    this.scale = 1.0,
    this.width = 200.0,
    this.height = 200.0,
  });

  ImageData translate(Offset delta) {
    return ImageData(
      position: position + delta,
      imagePath: imagePath,
      scale: scale,
      width: width,
      height: height,
    );
  }

  ImageData scaleFromOrigin(double scaleFactor, Offset origin) {
    return ImageData(
      position: origin + (position - origin) * scaleFactor,
      imagePath: imagePath,
      scale: scale,
      width: width * scaleFactor,
      height: height * scaleFactor,
    );
  }

  Rect getBounds() {
    return Rect.fromLTWH(position.dx, position.dy, width, height);
  }

  ImageData copy() {
    return ImageData(
      position: position,
      imagePath: imagePath,
      scale: scale,
      width: width,
      height: height,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'position': {'dx': position.dx, 'dy': position.dy},
      'imagePath': imagePath,
      'scale': scale,
      'width': width,
      'height': height,
    };
  }

  factory ImageData.fromMap(Map<String, dynamic> map) {
    return ImageData(
      position: Offset(
        (map['position']['dx'] as num).toDouble(),
        (map['position']['dy'] as num).toDouble(),
      ),
      imagePath: map['imagePath'] as String,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      width: (map['width'] as num?)?.toDouble() ?? 200.0,
      height: (map['height'] as num?)?.toDouble() ?? 200.0,
    );
  }
}
