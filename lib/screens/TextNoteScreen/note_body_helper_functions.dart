import 'package:flutter/material.dart';

import '../../app_style.dart';

int getWordCount(String text) {
  if (text.trim().isEmpty) return 0;
  return text.trim().split(RegExp(r'\s+')).length;
}

int getLineCount(String text) {
  if (text.isEmpty) return 1;
  return '\n'.allMatches(text).length + 1;
}

int getCharacterCount(String text) {
  return text.length;
}

int getReadingTime(String text) {
  final words = getWordCount(text);
  return (words / 200).ceil();
}

OutlineInputBorder note_border() {
  return OutlineInputBorder(
    borderSide: BorderSide(color: accent, width: 2),
    borderRadius: BorderRadius.circular(4),
  );
}
