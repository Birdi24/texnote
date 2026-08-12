import 'package:flutter/material.dart';

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
    borderSide: BorderSide(color: Colors.blue, width: 2),
    borderRadius: BorderRadius.circular(4),
  );
}

void wrapSelection(
    TextEditingController controller,
    String before, String after,
    ) {
  final selection = controller.selection;

  if (!selection.isValid) return;

  final text = controller.text;

  if (selection.start == selection.end) {
    final newText = text.replaceRange(
      selection.start, selection.end, before + after,
    );
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + before.length,
      ),
    );
    return;
  }

  final selected = selection.textInside(text);
  final replacement = before + selected + after;

  controller.value = controller.value.copyWith(
    text: text.replaceRange(
      selection.start, selection.end, replacement,
    ),
    selection: TextSelection(
      baseOffset: selection.start,
      extentOffset: selection.start + replacement.length,
    ),
  );
}

void insertTextAtCursor(String table, TextEditingController controller,){
  wrapSelection(controller, table, "");
}