
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/single_circle_button.dart';

enum DrawingTool { pen, eraser,eraser2, highlighter, lasso, move, copy, paste }

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
        width: 520,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IgnorePointer(
              ignoring: !canUndo,
              child: single_circle_button(LucideIcons.undo_2, 20.0, canUndo ? 90 : 40, "undo", undo, context, screen_width, button_width: 40.0,bgAlpha: 160),
            ),
            IgnorePointer(
              ignoring: !canRedo,
              child: single_circle_button(LucideIcons.redo_2, 20.0, canRedo ? 90 : 40, "redo", redo, context, screen_width, button_width: 40.0,bgAlpha: 160),
            ),

            const VerticalDivider(width: 1, indent: 15, endIndent: 15, color: icon_color),

            single_circle_button(LucideIcons.pen_tool, 20.0, selectedTool == DrawingTool.pen ? 90 : 40, "pen", () => onToolChanged?.call(DrawingTool.pen), context, screen_width, button_width: 40.0, rotation: -pi / 2,bgAlpha: 160,),
            single_circle_button(LucideIcons.eraser, 20.0, selectedTool == DrawingTool.eraser ? 90 : 40, "eraser", () => onToolChanged?.call(DrawingTool.eraser), context, screen_width, button_width: 40.0,bgAlpha: 160),
            single_circle_button(LucideIcons.highlighter, 20.0, selectedTool == DrawingTool.eraser ? 90 : 40, "highlighter", () => onToolChanged?.call(DrawingTool.eraser), context, screen_width, button_width: 40.0,bgAlpha: 160),

            const VerticalDivider(width: 1, indent: 15, endIndent: 15, color: icon_color),

            single_circle_button(LucideIcons.lasso, 20.0, selectedTool == DrawingTool.lasso ? 90 : 40, "lasso", () => onToolChanged?.call(DrawingTool.eraser), context, screen_width, button_width: 40.0,bgAlpha: 160),
            single_circle_button(LucideIcons.move, 20.0, selectedTool == DrawingTool.move ? 90 : 40, "move", () => onToolChanged?.call(DrawingTool.eraser), context, screen_width, button_width: 40.0,bgAlpha: 160),
            single_circle_button(LucideIcons.copy, 20.0, selectedTool == DrawingTool.copy ? 90 : 40, "copy", () => onToolChanged?.call(DrawingTool.eraser), context, screen_width, button_width: 40.0,bgAlpha: 160),
            single_circle_button(LucideIcons.clipboard, 20.0, selectedTool == DrawingTool.paste ? 90 : 40, "paste", () => onToolChanged?.call(DrawingTool.eraser), context, screen_width, button_width: 40.0,bgAlpha: 160),


          ],
        ),
      ),
    ],
  );
}


Widget left_button_array(
    context, {
      DrawingTool selectedTool = DrawingTool.pen,
      double currentSize = 0.5,
      VoidCallback? onIncrementSize,
      VoidCallback? onDecrementSize,
      Function(double)? onSizeDelta,
      VoidCallback? onSwitchEraserType,
      Color currentPenColor = Colors.black,
      Color secondaryPenColor = Colors.blue,
      Function(Color)? onColorChanged,
      VoidCallback? onOpenColorPicker,
    }) {
  final screen_width = MediaQuery.of(context).size.width;
  return glassContainer(
      width: 60,
      height: 380,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            single_circle_button(
                LucideIcons.plus,
                20.0,
                90,
                "plus",
                () => onIncrementSize?.call(),
                context,
                screen_width,
                button_width: 40.0,
                bgAlpha: 160
            ),

            GestureDetector(
              onVerticalDragUpdate: (details) {
                onSizeDelta?.call(-details.delta.dy * 0.05);
              },
              child: glassContainer(
                width: 40, height: 40, radius: 20,
                borderAlpha: 90,
                bgAlpha: 160,
                child: Center(
                  child: Text(
                    currentSize.toStringAsFixed(1),
                    style: AppStyles.icon_text.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            single_circle_button(
                LucideIcons.minus,
                20.0,
                90,
                "minus",
                () => onDecrementSize?.call(),
                context,
                screen_width,
                button_width: 40.0,
                bgAlpha: 160),



            (selectedTool == DrawingTool.eraser || selectedTool == DrawingTool.eraser2)
                ? eraser_further_options(context,screen_width, selectedTool, onSwitchEraserType)
                : pen_further_options(context, screen_width, currentPenColor, secondaryPenColor, onColorChanged, onOpenColorPicker)
          ]
      )
    );
  }

Widget eraser_further_options(context,screen_width, selectedTool, onSwitchEraserType) {

  return Column(
    children: [
      const Divider(height: 1, indent: 15, endIndent: 15, color: icon_color),
      const SizedBox(height: 14,),
      single_circle_button(
        (selectedTool == DrawingTool.eraser) ? LucideIcons.circle_dashed : LucideIcons.circle,
        20.0,
        90,
        "eraser_type",
            () => onSwitchEraserType?.call(),
        context,
        screen_width,
        button_width: 40.0,
        bgAlpha: 160
      )
    ]
  );
}

Widget color_button(Color color, VoidCallback onTap, {bool hasOutline = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: hasOutline ? Border.all(color: Colors.black, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ]
      ),
    ),
  );
}

Widget pen_further_options(context, screen_width, currentPenColor, secondaryPenColor, onColorChanged, onOpenColorPicker) {
  return Column(
      children: [
        const Divider(height: 1, indent: 15, endIndent: 15, color: icon_color),
        const SizedBox(height: 14,),
        color_button(
            currentPenColor,
            () {}, // Already selected
            hasOutline: true
        ),
        const SizedBox(height: 14,),
        color_button(
            secondaryPenColor,
            () => onColorChanged?.call(secondaryPenColor)
        ),
        const SizedBox(height: 14,),
        single_circle_button(
            LucideIcons.palette,
            20.0,
            90,
            "color wheel",
            () => onOpenColorPicker?.call(),
            context,
            screen_width,
            button_width: 40.0,
            bgAlpha: 160
        )
      ]
  );
}
