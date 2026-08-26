import 'dart:io';

import 'package:flutter/cupertino.dart';

abstract class Note {
  String title;
  DateTime date;
  String path;

  bool isFavorite;
  String? collectionId;

  NoteType type;

  void rename_note(String title){this.title = title;}

  Future<void> delete() async {
    final file = File(path);
    debugPrint("Deleting file at path: $path");

    if (await file.exists()) {
      await file.delete();
      debugPrint("$path deleted!");
    }
  }

  Note({
    required this.title,
    required this.type,
    required this.date,
    required this.path,
    this.isFavorite = false,
  });

  Widget display();

  Future<void> export();
  Future<void> exportAsPdf();

  String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<Note> duplicate_note();

  Future<void> save(String oldTitle);

  /// by: 0 means newest date first
  /// by: 1 means oldest date first
  /// by: 2 means alphabetical order
  static List<Note> sort_notes(List<Note> current, int by) {
    switch (by) {
      case 0:
        current.sort((a, b) => b.date.compareTo(a.date));
        break;

      case 1:
        current.sort((a, b) => a.date.compareTo(b.date));
        break;

      case 2:
        current.sort((a, b) => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ));
        break;
    }
    return current;
  }
}

enum NoteType {
  HandwrittenNote,
  TextNote,
  latex,
}