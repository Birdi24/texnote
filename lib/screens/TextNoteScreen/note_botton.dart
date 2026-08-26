
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../app_style.dart';
import 'note_body_helper_functions.dart';

Widget note_bottom(String currentTime, QuillController bodyController) {
  return ListenableBuilder(
    listenable: bodyController,
    builder: (context, child) {
      final text = bodyController.document.toPlainText();

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Ln ${getLineCount(text)}',
                style: AppStyles.timefont,
              ),
              const SizedBox(width: 20),
              Text(
                '${getWordCount(text)} words',
                style: AppStyles.timefont,
              ),
              const SizedBox(width: 20),
              Text(
                '${getCharacterCount(text)} chars',
                style: AppStyles.timefont,
              ),
              const SizedBox(width: 20),
              Text(
                '~${getReadingTime(text)} min read',
                style: AppStyles.timefont,
              ),
              const SizedBox(width: 20),
              Text(
                'Opened $currentTime',
                style: AppStyles.timefont,
              ),
            ],
          ),
        ),
      );
    },
  );
}