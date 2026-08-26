import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:texnote/widgets/glass_container.dart';
import '../../app_style.dart';

Widget note_body(BuildContext context, QuillController bodyController, double font_size) {
  return Expanded(
    child: rich_text_view(context, bodyController, font_size),
  );
}

Widget rich_text_view(BuildContext context, QuillController bodyController, double font_size) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: accent), borderRadius: BorderRadius.circular(5)
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: QuillEditor.basic(
        controller: bodyController,
        config: QuillEditorConfig(
          autoFocus: false,
          expands: true,
          padding: EdgeInsets.zero,
          placeholder: 'Start your note here...',
          customStyles: DefaultStyles(
            placeHolder: DefaultTextBlockStyle(
              AppStyles.bodytext.copyWith(fontSize: font_size, color: Colors.grey),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              null,
            ),
            paragraph: DefaultTextBlockStyle(
              AppStyles.bodytext.copyWith(fontSize: font_size),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    ),
  );
}
