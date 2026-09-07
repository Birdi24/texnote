import 'dart:ui';
import 'package:flutter/material.dart';

/// Represents text in a handwritten note.
class TextData {
  Offset position;
  String text;
  double width;
  double height;
  double fontSize;
  Color color;

  TextData({
    required this.position,
    this.text = "",
    this.width = 200.0,
    this.height = 100.0,
    this.fontSize = 20.0,
    this.color = Colors.indigo,
  });

  TextData translate(Offset delta) {
    return TextData(
      position: position + delta,
      text: text,
      width: width,
      height: height,
      fontSize: fontSize,
      color: color,
    );
  }

  TextData scaleFromOrigin(double scaleFactor, Offset origin) {
    return TextData(
      position: origin + (position - origin) * scaleFactor,
      text: text,
      width: width * scaleFactor,
      height: height * scaleFactor,
      fontSize: fontSize * scaleFactor,
      color: color,
    );
  }

  Rect getBounds() {
    return Rect.fromLTWH(position.dx, position.dy, width, height);
  }

  TextData copy() {
    return TextData(
      position: position,
      text: text,
      width: width,
      height: height,
      fontSize: fontSize,
      color: color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'position': {'dx': position.dx, 'dy': position.dy},
      'text': text,
      'width': width,
      'height': height,
      'fontSize': fontSize,
      'color': color.value,
    };
  }

  factory TextData.fromMap(Map<String, dynamic> map) {
    return TextData(
      position: Offset(
        (map['position']['dx'] as num).toDouble(),
        (map['position']['dy'] as num).toDouble(),
      ),
      text: map['text'] as String,
      width: (map['width'] as num?)?.toDouble() ?? 200.0,
      height: (map['height'] as num?)?.toDouble() ?? 100.0,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 20.0,
      color: Color(map['color'] as int? ?? 0xFF000000),
    );
  }
}