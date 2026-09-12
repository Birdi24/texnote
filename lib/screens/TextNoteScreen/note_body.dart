import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../app_style.dart';

Widget note_body(BuildContext context, QuillController bodyController, double fontSize) {
  return Expanded(
    child: rich_text_view(context, bodyController, fontSize),
  );
}

Widget rich_text_view(BuildContext context, QuillController bodyController, double fontSize) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: accent), borderRadius: BorderRadius.circular(10),
      color: BG
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: QuillEditor.basic(
        controller: bodyController,
        config: QuillEditorConfig(
          autoFocus: true,
          expands: true,
          padding: EdgeInsets.zero,
          placeholder: 'Start your note here...',
          customStyles: DefaultStyles(
            placeHolder: DefaultTextBlockStyle(
              AppStyles.bodytext.copyWith(fontSize: fontSize, color: text),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              null,
            ),
            paragraph: DefaultTextBlockStyle(
              AppStyles.bodytext.copyWith(fontSize: fontSize),
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
