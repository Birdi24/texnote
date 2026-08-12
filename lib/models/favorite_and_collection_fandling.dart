import 'dart:io';
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
    return [];
  }
  catch (e) {
    print("Could not load the favorites file: $e");
    return [];
  }
}

Future<void> save_favorites(List<Note> all_notes) async{
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file_path = dir.path + "/.favorites.txt";
    File fav_file = File(file_path);
    String body = "";
    if (await fav_file.exists()) {
      for (final note in all_notes) {
        if (note.is_fav) {
          body += "${note.path}\n";
        }
      }
      fav_file.writeAsString(body);
    }
  } catch (e) {
    print("Could not save the favorites file: $e");
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
              currentName!,
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
    }
    return collections;
  }
  catch (e) {
    print("Could not load the collections file: $e");
    return [];
  }
}

Future<void> save_collections(List<Collection> collections) async {
  try {
    String body = "";
    for (int i = 0; i < collections.length; i++) {
      body += "[${collections[i].title}]\n";
      body += "color=${collections[i].color}\n";
      for (int j = 0; j < collections[i].notes.length; j++) {
        body += "path=${collections[i]}\n";
      }
      body += "\n";
    }
    final dir = await getApplicationDocumentsDirectory();
    final file_path = dir.path + "/.collections.txt";
    File fav_file = File(file_path);

    fav_file.writeAsString(body);
  }
  catch (e) {
    print("Could not save the collections file: $e");
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

  void rename_collection(String new_name) {
    title = new_name;
  }
}