import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'note.dart';

Future<List<Note>> load_favorites(List<Note> all_notes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file_path = dir.path + "/.favorites.txt";
    File fav_file = File(file_path);
    if (await fav_file.exists()) {
      List<Note> ret = [];
      final contents = await fav_file.readAsString();
      final favoritePaths = contents
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toSet();

      for (final note in all_notes) {
        if( favoritePaths.contains(note.path)) {
          note.is_fav = true;
          ret.add(note);
        }
      }
      return ret;
    }
    else { await fav_file.create(recursive: true);debugPrint("Favorites file not found, creating new one.");}
    return [];
  }
  catch (e) {
    debugPrint("Could not load the favorites file: $e");
    return [];
  }
}

Future<void> save_favorites(List<Note> all_notes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/.favorites.txt";
    final favFile = File(filePath);

    final favoritePaths = all_notes
        .where((note) => note.is_fav)
        .map((note) => note.path)
        .join('\n');

    await favFile.writeAsString(
      favoritePaths.isEmpty ? '' : '$favoritePaths\n',
    );

    debugPrint(
      "Favorites saved successfully. Count: "
          "${all_notes.where((note) => note.is_fav).length}",
    );
  } catch (e) {
    debugPrint("Could not save the favorites file: $e");
  }
}


Future<List<Collection>> load_collections() async {
  try {
    List<Collection> collections = [];
    final dir = await getApplicationDocumentsDirectory();
    final file_path = dir.path + "/.collections.txt";
    File fav_file = File(file_path);
    if (await fav_file.exists()) {
      final contents = await fav_file.readAsString();
      String? currentName;
      String? currentColor;
      List<Note> currentNotes = [];

      void saveCurrentCollection() {
        if (currentName != null) {
          collections.add(
            Collection(
              currentName,
              currentColor!,
              List<Note>.from(currentNotes),
            ),
          );
        }
      }

      for (final line in contents.split('\n')) {
        final trimmed = line.trim();

        if (trimmed.isEmpty) {
          continue;
        }

        // New collection
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          saveCurrentCollection();

          currentName = trimmed.substring(1, trimmed.length - 1);
          currentColor = null;
          currentNotes = [];
        }

        // Collection color
        else if (trimmed.startsWith('color=')) {
          currentColor = trimmed.substring('color='.length);
        }

        // Collection path
        else if (trimmed.startsWith('path=')) {
          currentNotes.add(
            await Note.make_note(trimmed.substring('path='.length)),
          );
        }
      }
      saveCurrentCollection();
    }
    else { await fav_file.create(recursive: true); debugPrint("Collections file not found, creating new one.");}
    return collections;
  }
  catch (e) {
    debugPrint("Could not load the collections file: $e");
    return [];
  }
}

Future<void> save_collections(List<Collection> collections) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/.collections.txt";
    final file = File(filePath);

    String body = "";

    for (final collection in collections) {
      body += "[${collection.title}]\n";
      body += "color=${collection.color}\n";

      for (final note in collection.notes) {
        body += "path=${note.path}\n";
      }

      body += "\n";
    }

    await file.writeAsString(body);

    debugPrint(
      "Collections saved successfully. Count: ${collections.length}",
    );
  } catch (e) {
    debugPrint("Could not save the collections file: $e");
  }
}



class Collection {
  String title;
  String color;
  List<Note> notes = [];

  Collection(this.title,this.color, this.notes);

  bool add_to_collections(Note note){
    if (notes.contains(note)) {return false;}
    notes.add(note); return true;
  }
  bool remove_from_collections(Note note){
    if (!notes.contains(note)) {return false;}
    notes.remove(note); return true;
  }

  /// by: 0 means least number of notes
  /// by: 1 means most number of notes
  /// by: 2 means alphabetical order
  static List<Collection> sort_collections(List<Collection> collections, int by) {
    for (final collection in collections) {
      Note.sort_notes(collection.notes, by);
    }
    switch (by) {
      case 0:
        collections.sort(
              (a, b) => a.notes.length.compareTo(b.notes.length),
        );
        break;
      case 1:
        collections.sort(
              (a, b) => b.notes.length.compareTo(a.notes.length),
        );
        break;
      case 2:
        collections.sort(
              (a, b) => a.title.toLowerCase().compareTo(
            b.title.toLowerCase(),
          ),
        );
        break;
    }
    return collections;
  }

  void rename_collection(String new_name) {
    title = new_name;
  }
}