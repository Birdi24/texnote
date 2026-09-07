import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'Note.dart';

/// loads the favorites from the app directory
Future<List<Note>> load_favorites(List<Note> notes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file_path = "${dir.path}/.favorites.json";
    File fav_file = File(file_path);

    if (await fav_file.exists()) {
      final contents = await fav_file.readAsString();
      if (contents.trim().isNotEmpty) {
        final List<dynamic> paths = jsonDecode(contents);

        return notes.where((note) => paths.contains(note.path)).toList();
      }
    } else {
      await fav_file.create(recursive: true);
      await fav_file.writeAsString('[]');
      debugPrint("Favorites file not found, creating new one.");
    }
    return [];
  } catch (e) {
    debugPrint("Could not load the favorites file: $e");
    return [];
  }
}

/// saves the favorites to the app directory
Future<void> save_favorites(List<Note> notes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/.favorites.json";
    final file = File(filePath);

    final paths = notes
        .where((note) => note.isFavorite)
        .map((note) => note.path)
        .toList();

    await file.writeAsString(jsonEncode(paths));

    debugPrint(
      "Favorites saved successfully. Count: ${paths.length}",
    );
  } catch (e) {
    debugPrint("Could not save the favorites file: $e");
  }
}
