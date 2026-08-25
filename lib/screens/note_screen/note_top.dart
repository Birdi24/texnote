

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:texnote/screens/note_screen/text_manipulation_buttons.dart';
import 'package:texnote/widgets/single_circle_button.dart';
import '../../app_style.dart';
import '../../widgets/options_button.dart';
import '../../widgets/title_label.dart';

Widget note_top(context, changed, Future<void> Function() save,
    titleController, bodyController, double font_size,
    Function(double) onFontSizeChanged,
    void Function() on_markdown_toggle_changed,
    void Function() reload_markdown){

  return mobile_view(context, changed, save, titleController, bodyController, font_size, onFontSizeChanged, on_markdown_toggle_changed, reload_markdown)
  ;
}

Widget markdown_refresh_button(context, void Function() reload_markdown) {
  return Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: SizedBox(
      width: 190,
      height: 35,
      child: OutlinedButton.icon(
        onPressed: () {
          reload_markdown();
        },
        style: OutlinedButton.styleFrom(
          iconColor: icon_color,
          side: const BorderSide(
            color: icon_color,
            width: 1,
          ),
        ),
        icon: const Icon(Icons.refresh),
        label: Text("Reload Markdown",style: AppStyles.bodytext.copyWith(color: icon_color),),
      ),
    ),
  );
}

Widget tablet_view(context, changed, Future<void> Function() save,
    titleController, bodyController, double font_size,
    Function(double) onFontSizeChanged,
    void Function() on_markdown_toggle_changed,
    void Function() reload_markdown){
  return Row(

    children: [
      
      single_circle_button(LucideIcons.chevron_left, 30.0, 90, "back",
          () async {if (changed){ await save();}Navigator.pop(context,true);},
          context, MediaQuery.of(context).size.width,button_width: 40),

      const SizedBox(width: 12),

      Expanded(child: title_label(context, titleController),),

      const SizedBox(width: 12),
      bold_button(context, bodyController),
      const SizedBox(width: 12),
      italic_button(context, bodyController),
      const SizedBox(width: 12),
      dot_list_button(context, bodyController),
      const SizedBox(width: 12),
      numbered_list_button(context, bodyController),
      const SizedBox(width: 12),
      checklist_button(context,bodyController),
      const SizedBox(width: 12),
      headings_dropdown(bodyController),
      const SizedBox(width: 12,),
      table_button(context, bodyController),
      const SizedBox(width: 12),
      block_button(context,bodyController),
      const SizedBox(width: 12),
      code_button(context, bodyController),
      const SizedBox(width: 12),
      markdown_refresh_button(context,  reload_markdown),
      const SizedBox(width: 12),
      options_button(context, save,font_size, onFontSizeChanged, on_markdown_toggle_changed),
    ],
  );
}

Widget mobile_view(context, changed, Future<void> Function() save,
    titleController, bodyController, double font_size,
    Function(double) onFontSizeChanged,
    void Function() on_markdown_toggle_changed,
    void Function() reload_markdown){
  return Column(
    children: [
      Row(
        children: [
          single_circle_button(LucideIcons.chevron_left, 30.0, 40, "back",
                  () async {if (changed){ await save();}Navigator.pop(context,true);},
              context, MediaQuery.of(context).size.width,button_width: 40),
          const SizedBox(width: 12),
          Expanded(child: title_label(context, titleController),),
          const SizedBox(width:12),
          options_button(context, save,font_size, onFontSizeChanged, on_markdown_toggle_changed),

        ],
      ),
      Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              bold_button(context, bodyController),
              const SizedBox(width: 12),

              italic_button(context, bodyController),
              const SizedBox(width: 12),

              dot_list_button(context, bodyController),
              const SizedBox(width: 12),

              numbered_list_button(context, bodyController),
              const SizedBox(width: 12),

              checklist_button(context, bodyController),
              const SizedBox(width: 12),

              headings_dropdown(bodyController),
              const SizedBox(width: 12),

              table_button(context, bodyController),
              const SizedBox(width: 12),

              block_button(context, bodyController),
              const SizedBox(width: 12),

              code_button(context, bodyController),
              const SizedBox(width: 12),

              markdown_refresh_button(context, reload_markdown),
            ],
          ),
        ),
      )
    ]
  );
}

