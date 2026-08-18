import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_style.dart';
import 'glass_container.dart';

Widget single_circle_button(
    IconData icon,
    double size,
    double alpha,
    String label,
    Function() function,
    BuildContext context,
    screen_width, {
      double? button_width,
    }) {
  final width = button_width ?? ((screen_width > 600) ? 68.0 : 58.0);
  return glassContainer(
    width: width, height: width, radius: width / 2,
    borderAlpha: alpha,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          debugPrint("Add button hit");
          await function();
        },
        customBorder: const CircleBorder(),
        child: Center(
          child: Icon(
            icon,
            color: icon_color,
            size: size,
          ),
        ),
      ),
    ),
  );
}