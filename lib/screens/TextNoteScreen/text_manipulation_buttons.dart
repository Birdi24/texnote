
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:texnote/widgets/color_picker.dart';
import 'package:texnote/widgets/glass_container.dart';
import 'package:texnote/widgets/single_circle_button.dart';
import 'package:texnote/widgets/table_picker.dart';
import '../../../app_style.dart';

final List<Color> textHistory = [];
final List<Color> highlightHistory = [];

Color _getColorFromAttr(Attribute? attr, Color defaultColor) {
  if (attr == null || attr.value == null) return defaultColor;
  final val = attr.value.toString();
  try {
    if (val.startsWith('#')) {
      return Color(int.parse(val.replaceFirst('#', 'ff'), radix: 16));
    }
  } catch (_) {}
  return defaultColor;
}

Widget base_button(QuillController bodyController, Attribute attribute, IconData icon, BuildContext context) {
  return ListenableBuilder(
    listenable: bodyController,
    builder: (context, _) {
      bool isSelected = false;
      final style = bodyController.getSelectionStyle();
      if (attribute.key == Attribute.list.key) {
        isSelected = style.containsKey(Attribute.list.key) && style.attributes[Attribute.list.key]?.value == attribute.value;
      } else {
        isSelected = style.containsKey(attribute.key);
      }

      return single_circle_button(
        icon,
        20.0,
        isSelected ? 90 : 40,
        attribute.key,
        () {
          if (isSelected) {
            bodyController.formatSelection(Attribute.clone(attribute, null));
          } else {
            bodyController.formatSelection(attribute);
          }
        },
        context,
        MediaQuery.of(context).size.width,
        button_width: 35.0,
        bgAlpha: 160,
      );
    },
  );
}

Widget bold_button(BuildContext context, QuillController bodyController){
  return base_button(bodyController, Attribute.bold, LucideIcons.bold, context);
}

Widget italic_button(BuildContext context, QuillController bodyController) {
  return base_button(bodyController, Attribute.italic, LucideIcons.italic, context);
}

Widget checklist_button(BuildContext context, QuillController bodyController) {
  return base_button(bodyController, Attribute.unchecked, LucideIcons.list_check, context);
}

Widget numbered_list_button(BuildContext context, QuillController bodyController) {
  return base_button(bodyController, Attribute.ol, LucideIcons.list_ordered, context);
}

Widget dot_list_button(BuildContext context, QuillController bodyController) {
  return base_button(bodyController, Attribute.ul, LucideIcons.list, context);
}

Widget color_button(BuildContext context, QuillController bodyController) {
  return ListenableBuilder(
    listenable: bodyController,
    builder: (context, _) {
      final style = bodyController.getSelectionStyle();
      final currentColor = _getColorFromAttr(style.attributes[Attribute.color.key], icon_color);

      return single_circle_button(
        LucideIcons.baseline,
        20.0,
        40,
        "color",
        () {
          showDialog(
            context: context,
            builder: (context) {
              Color selectedColor = currentColor;
              return AlertDialog(
                backgroundColor: BG,
                title: Text('Text Color', style: AppStyles.bodytext.copyWith(color: icon_color)),
                content: SizedBox(
                  height: 420,
                  width: 300,
                  child: ColorPicker(
                    initialColor: selectedColor,
                    history: textHistory,
                    onColorChanged: (color, identifier) {
                      selectedColor = color;
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (!textHistory.contains(selectedColor)) {
                        textHistory.insert(0, selectedColor);
                        if (textHistory.length > 6) textHistory.removeLast();
                      }
                      bodyController.formatSelection(ColorAttribute('#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'));
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
        context,
        MediaQuery.of(context).size.width,
        button_width: 35.0,
        bgAlpha: 160,
        iconColor: currentColor,
      );
    }
  );
}

Widget highlight_button(BuildContext context, QuillController bodyController) {
  return ListenableBuilder(
    listenable: bodyController,
    builder: (context, _) {
      final style = bodyController.getSelectionStyle();
      final currentColor = _getColorFromAttr(style.attributes[Attribute.background.key], Colors.transparent);

      return single_circle_button(
        LucideIcons.highlighter,
        20.0,
        40,
        "highlight",
        () {
          showDialog(
            context: context,
            builder: (context) {
              Color selectedColor = currentColor == Colors.transparent ? Colors.yellow : currentColor;
              return AlertDialog(
                backgroundColor: BG,
                title: Text('Highlight Color', style: AppStyles.bodytext.copyWith(color: icon_color)),
                content: SizedBox(
                  height: 420,
                  width: 300,
                  child: ColorPicker(
                    initialColor: selectedColor,
                    history: highlightHistory,
                    onColorChanged: (color, identifier) {
                      selectedColor = color;
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      bodyController.formatSelection(Attribute.clone(Attribute.background, null));
                      Navigator.pop(context);
                    },
                    child: const Text('Remove Highlighter'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (!highlightHistory.contains(selectedColor)) {
                        highlightHistory.insert(0, selectedColor);
                        if (highlightHistory.length > 6) highlightHistory.removeLast();
                      }
                      bodyController.formatSelection(BackgroundAttribute('#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'));
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
        context,
        MediaQuery.of(context).size.width,
        button_width: 35.0,
        bgAlpha: 160,
        iconColor: currentColor == Colors.transparent ? icon_color : currentColor,
      );
    }
  );
}

Widget font_size_picker(
    BuildContext context,
    QuillController bodyController,
    double defaultFontSize,
    Function(double) onDefaultFontSizeChanged,
) {
  return ListenableBuilder(
    listenable: bodyController,
    builder: (context, _) {
      final style = bodyController.getSelectionStyle();
      String? attrSize;
      if (style.containsKey('size')) {
        attrSize = style.attributes['size']?.value.toString();
      }

      double currentSize = attrSize != null ? double.tryParse(attrSize) ?? defaultFontSize : defaultFontSize;

      void updateFontSize(double newSize) {
        newSize = newSize.clamp(8, 100);
        bodyController.formatSelection(
          Attribute.fromKeyValue('size', newSize.toStringAsFixed(0)),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          single_circle_button(
            LucideIcons.minus,
            15.0,
            40,
            "decrease",
            () => updateFontSize(currentSize - 1),
            context,
            MediaQuery.of(context).size.width,
            button_width: 30,
            bgAlpha: 160,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onVerticalDragUpdate: (details) {
              updateFontSize(currentSize - details.delta.dy * 0.1);
            },
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  final sizes = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0, 64.0, 72.0, 96.0];
                  return AlertDialog(
                    backgroundColor: BG,
                    title: Text('Select Font Size', style: AppStyles.bodytext.copyWith(color: icon_color)),
                    content: SizedBox(
                      width: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sizes.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              '${sizes[index].toStringAsFixed(0)} px',
                              style: TextStyle(color: icon_color, fontSize: sizes[index] > 24 ? 24 : sizes[index]),
                            ),
                            onTap: () {
                              updateFontSize(sizes[index]);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
            child: glassContainer(
              width: 35,
              height: 35,
              radius: 17.5,
              bgAlpha: 160,
              borderAlpha: 90,
              child: Center(
                child: Text(
                  currentSize.toStringAsFixed(0),
                  style: AppStyles.bodytext.copyWith(
                    color: icon_color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          single_circle_button(
            LucideIcons.plus,
            15.0,
            40,
            "increase",
            () => updateFontSize(currentSize + 1),
            context,
            MediaQuery.of(context).size.width,
            button_width: 30,
            bgAlpha: 160,
          ),
        ],
      );
    },
  );
}
