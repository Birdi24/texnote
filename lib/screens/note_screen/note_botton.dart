
import 'package:flutter/cupertino.dart';

import '../../app_style.dart';
import 'note_body_helper_functions.dart';
Widget note_bottom(String currentTime,_lastSaved, TextEditingController bodyController) {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: bodyController,
    builder: (context, value, child) {
      final text = value.text;

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
              const SizedBox(width: 20),
              _lastSaved != null
                  ? Text('Last saved $_lastSaved', style: AppStyles.timefont,)
                  : Text('Note not saved', style: AppStyles.timefont,),
            ],
          ),
        ),
      );
    },
  );
}