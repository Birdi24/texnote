
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/single_circle_button.dart';

enum DrawingTool { pen, eraser, eraser2, highlighter, lasso, duplicate, text }

Widget history_button_array(
    context,
    undo,
    redo, {
      bool canUndo = true,
      bool canRedo = true,
    }) {
  final screen_width = MediaQuery.of(context).size.width;
  return glassContainer(
    width: 110,
    height: 60,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IgnorePointer(
          ignoring: !canUndo,
          child: single_circle_button(LucideIcons.undo_2, 20.0, canUndo ? 90 : 40, "undo", undo, context, screen_width, button_width: 35.0, bgAlpha: 160),
        ),
        IgnorePointer(
          ignoring: !canRedo,
          child: single_circle_button(LucideIcons.redo_2, 20.0, canRedo ? 90 : 40, "redo", redo, context, screen_width, button_width: 35.0, bgAlpha: 160),
        ),
      ],
    ),
  );
}

Widget tool_button_array(
    context, {
      DrawingTool selectedTool = DrawingTool.pen,
      Function(DrawingTool)? onToolChanged,
      Function()? onAddPage,
      Function()? onImportImage,
    }) {
  final screen_width = MediaQuery.of(context).size.width;
  return glassContainer(
    width: 430,
    height: 60,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        single_circle_button(LucideIcons.pen_tool, 20.0, selectedTool == DrawingTool.pen ? 90 : 40, "pen", () => onToolChanged?.call(DrawingTool.pen), context, screen_width, button_width: 35.0, rotation: -pi / 2, bgAlpha: 160,),
        single_circle_button(LucideIcons.type, 20.0, selectedTool == DrawingTool.text ? 90 : 40, "text", () => onToolChanged?.call(DrawingTool.text), context, screen_width, button_width: 35.0, bgAlpha: 160),
        single_circle_button(LucideIcons.eraser, 20.0, (selectedTool == DrawingTool.eraser || selectedTool == DrawingTool.eraser2) ? 90 : 40, "eraser", () => onToolChanged?.call(DrawingTool.eraser2), context, screen_width, button_width: 35.0, bgAlpha: 160),
        single_circle_button(LucideIcons.highlighter, 20.0, selectedTool == DrawingTool.highlighter ? 90 : 40, "highlighter", () => onToolChanged?.call(DrawingTool.highlighter), context, screen_width, button_width: 35.0, bgAlpha: 160),

         VerticalDivider(width: 1, indent: 15, endIndent: 15, color: icon_color),

        single_circle_button(LucideIcons.lasso, 20.0, selectedTool == DrawingTool.lasso ? 90 : 40, "lasso", () => onToolChanged?.call(DrawingTool.lasso), context, screen_width, button_width: 35.0, bgAlpha: 160),
        single_circle_button(LucideIcons.copy, 20.0, selectedTool == DrawingTool.duplicate ? 40 : 40, "duplicate", () => onToolChanged?.call(DrawingTool.duplicate), context, screen_width, button_width: 35.0, bgAlpha: 160),
        single_circle_button(LucideIcons.image, 20.0, 90, "import image", () => onImportImage?.call(), context, screen_width, button_width: 35.0, bgAlpha: 160),

         VerticalDivider(width: 1, indent: 15, endIndent: 15, color: icon_color),
        
        single_circle_button(LucideIcons.file_plus, 20.0, 90, "add page", onAddPage!, context, screen_width, button_width: 35.0, bgAlpha: 160),
      ],
    ),
  );
}

Widget consolidated_tool_array(
    context,
    undo,
    redo, {
      bool canUndo = true,
      bool canRedo = true,
      DrawingTool selectedTool = DrawingTool.pen,
      Function(DrawingTool)? onToolChanged,
      Function()? onAddPage,
      Function()? onImportImage,
    }) {
  final screen_width = MediaQuery.of(context).size.width;

  List<Widget> buttons = [
    IgnorePointer(
      ignoring: !canUndo,
      child: single_circle_button(LucideIcons.undo_2, 20.0, canUndo ? 90 : 40, "undo", undo, context, screen_width, button_width: 35.0, bgAlpha: 160),
    ),
    IgnorePointer(
      ignoring: !canRedo,
      child: single_circle_button(LucideIcons.redo_2, 20.0, canRedo ? 90 : 40, "redo", redo, context, screen_width, button_width: 35.0, bgAlpha: 160),
    ),
    single_circle_button(LucideIcons.pen_tool, 20.0, selectedTool == DrawingTool.pen ? 90 : 40, "pen", () => onToolChanged?.call(DrawingTool.pen), context, screen_width, button_width: 35.0, rotation: -pi / 2, bgAlpha: 160,),
    single_circle_button(LucideIcons.type, 20.0, selectedTool == DrawingTool.text ? 90 : 40, "text", () => onToolChanged?.call(DrawingTool.text), context, screen_width, button_width: 35.0, bgAlpha: 160),
    single_circle_button(LucideIcons.eraser, 20.0, (selectedTool == DrawingTool.eraser || selectedTool == DrawingTool.eraser2) ? 90 : 40, "eraser", () => onToolChanged?.call(DrawingTool.eraser2), context, screen_width, button_width: 35.0, bgAlpha: 160),
    single_circle_button(LucideIcons.highlighter, 20.0, selectedTool == DrawingTool.highlighter ? 90 : 40, "highlighter", () => onToolChanged?.call(DrawingTool.highlighter), context, screen_width, button_width: 35.0, bgAlpha: 160),
    single_circle_button(LucideIcons.lasso, 20.0, selectedTool == DrawingTool.lasso ? 90 : 40, "lasso", () => onToolChanged?.call(DrawingTool.lasso), context, screen_width, button_width: 35.0, bgAlpha: 160),
    single_circle_button(LucideIcons.copy, 20.0, selectedTool == DrawingTool.duplicate ? 40 : 40, "duplicate", () => onToolChanged?.call(DrawingTool.duplicate), context, screen_width, button_width: 35.0, bgAlpha: 160),
    single_circle_button(LucideIcons.image, 20.0, 90, "import image", () => onImportImage?.call(), context, screen_width, button_width: 35.0, bgAlpha: 160),
    single_circle_button(LucideIcons.file_plus, 20.0, 90, "add page", onAddPage!, context, screen_width, button_width: 35.0, bgAlpha: 160),
  ];

  return glassContainer(
    width: MediaQuery.of(context).size.width > 340 ? 280 : MediaQuery.of(context).size.width - 60,
    height: 60,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child:Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            spacing: 10,
            children: buttons,
        ),
      ),
    ),
  );
}



Widget left_button_array(
    context, {
      DrawingTool selectedTool = DrawingTool.pen,
      double currentSize = 3.0,
      VoidCallback? onIncrementSize,
      VoidCallback? onDecrementSize,
      Function(double)? onSizeDelta,
      VoidCallback? onSwitchEraserType,
      Color currentPenColor = BLACK,
      Color secondaryPenColor = Colors.indigo,
      Function(Color)? onColorChanged,
      VoidCallback? onOpenColorPicker,
    }) {
  final screen_width = MediaQuery.of(context).size.width;
  return (DrawingTool.duplicate != selectedTool ) ? glassContainer(
      width: 55,
      height: (selectedTool == DrawingTool.eraser || selectedTool == DrawingTool.eraser2 ) ? 218 : 318,
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
                button_width: 35.0,
                bgAlpha: 160
            ),

            GestureDetector(
              onVerticalDragUpdate: (details) {
                onSizeDelta?.call(-details.delta.dy * 0.05);
              },
              child: glassContainer(
                width: 35, height: 35, radius: 20,
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
                button_width: 35.0,
                bgAlpha: 160),



            (selectedTool == DrawingTool.eraser || selectedTool == DrawingTool.eraser2)
                ? eraser_further_options(context,screen_width, selectedTool, onSwitchEraserType)
                : pen_further_options(context, screen_width, currentPenColor, secondaryPenColor, onColorChanged, onOpenColorPicker)
          ]
      )
    ) : SizedBox.shrink();
  }

Widget eraser_further_options(context,screen_width, selectedTool, onSwitchEraserType) {

  return Column(
    children: [
       Divider(height: 1, indent: 15, endIndent: 15, color: icon_color),
      const SizedBox(height: 14,),
      single_circle_button(
        (selectedTool == DrawingTool.eraser) ? LucideIcons.circle_dashed : LucideIcons.circle,
        20.0,
        90,
        "eraser_type",
            () => onSwitchEraserType?.call(),
        context,
        screen_width,
        button_width: 35.0,
        bgAlpha: 160
      )
    ]
  );
}

Widget color_button(Color color, VoidCallback onTap, {bool hasOutline = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: hasOutline ? Border.all(color: icon_color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: icon_color.withAlpha(25),
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
         Divider(height: 1, indent: 15, endIndent: 15, color: icon_color),
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
            button_width: 35.0,
            bgAlpha: 160
        )
      ]
  );
}
