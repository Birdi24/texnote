import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;

class Note {
  String title;
  String body;
  String path;
  DateTime date;
  bool is_fav = false;

  Note(this.title, this.body,  this.path, this.date);

  String date_string() {
    return DateFormat('h:mm a - MMM d, yyyy').format(date);
  }

  static Future<Note> make_note(String path) async {

    File file = File(path);
    if (await file.exists()) {
      final body = await file.readAsString();
      final title = p.basenameWithoutExtension(path);
      final finalTime = await file.lastModified();
      return Note(title, body, path, finalTime);
    }
    throw Exception("File does not exist at $path");
  }

  static Future<List<Note>> collectNotes() async {
    final directory = await getApplicationDocumentsDirectory();

    debugPrint("Directory: ${directory.path}");

    ///final files = directory .listSync() .where((file) => file.path.endsWith('.txt')) .map((file) => File(file.path)) .toList();

    final files = directory.listSync().where((file) => file.path.endsWith('.txt') &&   !file.uri.pathSegments.last.startsWith('.')).map((file) => File(file.path)).toList();

    debugPrint("Files found: ${files.length}");

    List<Note> notes = [];
    var i = 0;
    while (i < files.length) {
      String path = files[i].path;
      debugPrint("Processing file: $path");
      String title = path.split('/').last.replaceAll('.txt', '');
      String body = await files[i].readAsString();
      DateTime date = await files[i].lastModified();
      notes.add(Note(title,body,path, date ));
      i++;
    }
    return notes;
  }

  Future<void> saveNote(String time, String oldTitle) async {
    try {
      String newTitle = sanitizeFileName(title.trim());

      if (newTitle.isEmpty) {
        newTitle = sanitizeFileName(time);
      }

      if (path.startsWith('content://')) {
        final saf = Saf();

        debugPrint("Saving imported file");
        debugPrint("Original URI: $path");

        final uri = Uri.parse(path);

        // If the title changed, rename the ORIGINAL Android document.
        if (oldTitle.isNotEmpty && newTitle != oldTitle) {
          debugPrint("Imported file title changed");

          final renamedFile = await saf.rename(
            uri.toString(),
            '$newTitle.txt',
          );

          // SAF can return a new URI after a rename.
          path = renamedFile.uri;

          debugPrint("Renamed file");
          debugPrint("New URI: $path");
        }

        final existingFile = await saf.stat(
          uri.toString()
        );

        if (existingFile == null) {
          throw Exception("Could not find imported file.");
        }

        // The current saf API writes a file by URI through the
        // document's URI.
        debugPrint("SAF status: ${Saf().writeFileStream}");

        title = newTitle;

        debugPrint("Imported file updated successfully.");
        debugPrint("Final URI: $path");

        return;
      }


      // Determine the directory
      String directoryPath;
      if (await Directory(path).exists()) {
        directoryPath = path;
      } else {
        directoryPath = p.dirname(path);
      }

      final newPath = p.join(directoryPath, '$newTitle.txt');

      debugPrint("NewPath: $newPath");

      // Rename an existing Texnote file
      if (oldTitle.isNotEmpty && newTitle != oldTitle) {
        debugPrint("Title has changed");

        final oldPath = p.join(directoryPath, '$oldTitle.txt');
        final oldFile = File(oldPath);

        if (await oldFile.exists()) {
          await oldFile.delete();
          debugPrint("$oldPath deleted!");
        }
      }

      final file = File(newPath);

      await file.writeAsString(body);

      title = newTitle;
      path = file.path;
      date = DateTime.now();

      debugPrint("Saved: ${file.path}");
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }


  String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> deleteNote() async {
    final file = File(path);
    debugPrint("Deleting file at path: $path");

    if (await file.exists()) {
      await file.delete();
      debugPrint("$path deleted!");
    }
  }

  Future<void> duplicate_note( Future<void> Function() onNoteCreated ) async {
    try {
      String newPath;
      if (path.endsWith('.txt')) {
        newPath = path.replaceFirst(".txt", "-Copy.txt");
      } else {
        newPath = p.join(path, "${sanitizeFileName(title)}-Copy.txt");
      }

      debugPrint("NEW PATH for duplicate: $newPath");
      final file = File(newPath);
      await file.writeAsString(body);
      await onNoteCreated();

    }
    catch (e) {
      debugPrint("Error duplicating note: $e");
    }
  }

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