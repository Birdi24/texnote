import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../app_style.dart';
import 'note_body_helper_functions.dart';

Widget note_body(context, bodyController, font_size, markdown_enabled,markdownkey, markdownData) {
  return Expanded(
    child: markdown_enabled ?
        markdown_view(context, bodyController, font_size, markdown_enabled,markdownkey, markdownData)
        :plain_text_view(context, bodyController, font_size)
  );
}

Widget plain_text_view(context, bodyController, font_size) {
  return Expanded(
    child: Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab) {

          final text = bodyController.text;
          final selection = bodyController.selection;

          final newText = text.replaceRange(
            selection.start,
            selection.end,
            '\t',
          );

          bodyController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: selection.start + 1,
            ),
          );

          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          final text = bodyController.text;
          final selection = bodyController.selection;

          final newText = text.replaceRange(
            selection.start,
            selection.end,
            '\n',
          );

          bodyController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: selection.start + 1,
            ),
          );
        }

        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: bodyController,

        maxLines: null,
        expands: true,

        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,

        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: "Start your note here...",
          hintStyle: AppStyles.bodytext,
          border: note_border(),
          enabledBorder: note_border(),
          focusedBorder: note_border(),
        ),
        style: AppStyles.bodytext.copyWith(fontSize: font_size),
      ),
    ),
  );
}

Widget markdown_view(context, bodyController, font_size, markdown_enabled,markdownkey, markdownData){
  double width = MediaQuery.of(context).size.width;
  print("width of screen $width");
  return width > 900 ?
    Row(
      children: [
        plain_text_view( context, bodyController, font_size,),
        SizedBox(width: 25),
        markdown_render(context, bodyController, markdown_enabled,font_size,markdownkey, markdownData),
      ],
    ):
    Column(
      children: [
        markdown_render(context, bodyController, markdown_enabled,font_size,markdownkey, markdownData),
        SizedBox(height:25),
        plain_text_view( context, bodyController, font_size,),
        ],
    );

}

Widget markdown_render(context, bodyController, markdown_enabled,font_size,markdownkey, markdownData){
  return Expanded(
    child: Align(
      alignment: Alignment.topLeft,
      child:SingleChildScrollView(
            child: MarkdownBody(
              key: ValueKey(markdownkey),
              data: markdownData,
              selectable: true,
              styleSheet: markdown_style(font_size)
            ),
      )
    )
  );
}

