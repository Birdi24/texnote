

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:texnote/screens/TextNoteScreen/text_manipulation_buttons.dart';
import 'package:texnote/widgets/glass_container.dart';
import 'package:texnote/widgets/single_circle_button.dart';

import '../../widgets/title_label.dart';

Widget note_top(context, changed, Future<void> Function() save,
    titleController, QuillController bodyController, double font_size,
    Function(double) onFontSizeChanged,){

  return text_view(context, changed, save, titleController, bodyController, font_size, onFontSizeChanged,)
  ;
}

Widget text_view(context, changed, Future<void> Function() save,
    titleController, QuillController bodyController, double font_size,
    Function(double) onFontSizeChanged){
  return Column(
    children: [
      Row(
        children: [
          single_circle_button(LucideIcons.chevron_left, 30.0, 40, "back",
                  () async {if (changed){ await save();}Navigator.pop(context,true);},
              context, MediaQuery.of(context).size.width,button_width: 50, bgAlpha: 160),
          const SizedBox(width: 10),
          Align(
            alignment: Alignment.topCenter,
            child: glassContainer(
              width: MediaQuery.of(context).size.width - 110,
              height: 60,
              bgAlpha: 160,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    spacing: 10,
                    children: [
                      bold_button(context, bodyController),
                      italic_button(context, bodyController),
                      color_button(context, bodyController),
                      highlight_button(context, bodyController),
                      dot_list_button(context, bodyController),
                      numbered_list_button(context, bodyController),
                      checklist_button(context, bodyController),
                      font_size_picker(context, bodyController, font_size, onFontSizeChanged),
                    ],
                  ),
                ),
              ),
            ),
          )


        ],
      ),
      title_label(context, titleController),

    ]
  );
}

