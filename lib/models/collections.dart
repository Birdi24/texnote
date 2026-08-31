import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../app_style.dart';
import 'Note.dart';
import 'TextNote.dart';

class Collection {
  String title;
  String color;
  List<Note> notes = [];

  Collection(this.title,this.color, this.notes);

  bool add_to_collections(Note note){
    if (notes.contains(note)) {return false;}
    notes.add(note); return true;
  }
  bool remove_from_collections(TextNote note){
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

  static Future<List<Collection>> load_collections(List<Note> notes) async {
    try {
      List<Collection> collections = [];
      final dir = await getApplicationDocumentsDirectory();
      final file_path = dir.path + "/.collections.json";
      File fav_file = File(file_path);

      if (await fav_file.exists()) {
        final contents = await fav_file.readAsString();
        if (contents.trim().isNotEmpty) {
          final List<dynamic> data = jsonDecode(contents);

          for (final entry in data) {
            final String name = entry['name'];
            final String color = entry['color'];
            final List<dynamic> paths = entry['paths'] ?? [];

            final collectionNotes =
            notes.where((note) => paths.contains(note.path)).toList();

            collections.add(Collection(name, color, collectionNotes));
          }
        }
      } else {
        await fav_file.create(recursive: true);
        await fav_file.writeAsString('[]');
        debugPrint("Collections file not found, creating new one.");
      }

      return collections;
    } catch (e) {
      debugPrint("Could not load the collections file: $e");
      return [];
    }
  }

  static Future<void> save_collections(List<Collection> collections) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/.collections.json";
      final file = File(filePath);

      final data = collections.map((collection) {
        return {
          "name": collection.title,
          "color": collection.color,
          "paths": collection.notes.map((note) => note.path).toList(),
        };
      }).toList();

      await file.writeAsString(jsonEncode(data));

      debugPrint(
        "Collections saved successfully. Count: ${collections.length}",
      );
    } catch (e) {
      debugPrint("Could not save the collections file: $e");
    }
  }

  Widget display() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 250,
          padding: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: collection_color(color),
            border: Border.all(
              color: icon_color,
              width: 2,
            ),
          ),
          child: Container(
            alignment: Alignment.bottomCenter,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: icon_color,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: icon_color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          "${notes.length} Notes",
          style: TextStyle(
            color: accent,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}