import 'package:flutter/material.dart';
import '../app_style.dart';
import 'glass_container.dart';

Widget single_circle_button(
    icon,
    double size,
    double alpha,
    String label,
    Function() function,
    BuildContext context,
    screenWidth, {
      double? button_width,
      double rotation = 0,
      int bgAlpha = 10,
      Color? iconColor,
    }) {
  final width = button_width ?? ((screenWidth > 600) ? 68.0 : 58.0);
  return glassContainer(
    width: width, height: width, radius: width / 2, bgAlpha: bgAlpha,
    borderAlpha: alpha,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await function();
        },
        customBorder: const CircleBorder(),
        child: Center(
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              icon,
              color: iconColor ?? icon_color,
              size: size,
            ),
          ),
        ),
      ),
    ),
  );
}