import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

abstract class Note {
  String title;
  DateTime date;
  String path;

  bool isFavorite;

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

  Future<void> move_to(String targetDirectory) async {
    final oldFile = File(path);
    if (await oldFile.exists()) {
      final fileName = p.basename(path);
      final newPath = p.join(targetDirectory, fileName);
      if (newPath == path) return;
      
      final newFile = await oldFile.rename(newPath);
      path = newFile.path;
      debugPrint("Moved note to $path");
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
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').startsWith('.') ? name.substring(1) : name;
  }

  Future<Note> duplicate_note();

  String date_string() {
    return DateFormat('h:mm a - MMM d, yyyy').format(date);
  }

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
}
