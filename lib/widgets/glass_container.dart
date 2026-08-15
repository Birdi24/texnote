

import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../app_style.dart';

Widget glassContainer({
  required Widget child,
  double width = double.infinity,
  double height = 70,
  double radius = 38,
  double sigmaX = 12,
  double sigmaY = 12,
  Color? borderColor,
  double borderAlpha = 17,
  Color shadowColor = BG,
  int bgAlpha = 10

}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: sigmaX,
        sigmaY: sigmaY,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? accent.withAlpha(borderAlpha.toInt()),
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withAlpha(bgAlpha),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}