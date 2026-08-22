
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/single_circle_button.dart';

enum DrawingTool { pen, eraser }

Widget top_button_array(
    context,
    undo,
    redo, {
      bool canUndo = true,
      bool canRedo = true,
      DrawingTool selectedTool = DrawingTool.pen,
      Function(DrawingTool)? onToolChanged,
    }) {
  final screen_width = MediaQuery.of(context).size.width;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      glassContainer(
        width: 250,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IgnorePointer(
              ignoring: !canUndo,
              child: single_circle_button(LucideIcons.undo_2, 20.0, canUndo ? 90 : 40, "undo", undo, context, screen_width, button_width: 40.0),
            ),
            IgnorePointer(
              ignoring: !canRedo,
              child: single_circle_button(LucideIcons.redo_2, 20.0, canRedo ? 90 : 40, "redo", redo, context, screen_width, button_width: 40.0),
            ),
            const VerticalDivider(width: 1, indent: 15, endIndent: 15, color: icon_color),
            single_circle_button(
              LucideIcons.pen_tool,
              20.0,
              selectedTool == DrawingTool.pen ? 90 : 40,
              "pen",
                  () => onToolChanged?.call(DrawingTool.pen),
              context,
              screen_width,
              button_width: 40.0,
              rotation: -pi / 2,
            ),
            single_circle_button(
              LucideIcons.eraser,
              20.0,
              selectedTool == DrawingTool.eraser ? 90 : 40,
              "eraser",
              () => onToolChanged?.call(DrawingTool.eraser),
              context,
              screen_width,
              button_width: 40.0,
            ),
          ],
        ),
      ),
    ],
  );
}
