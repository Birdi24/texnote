import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;

import '../app_style.dart';
import 'Note.dart';

class TextNote extends Note {
  String body;
  
  TextNote({
    required super.title,
    required super.date,
    required super.path,
    required super.type,
    required this.body,
    super.isFavorite = false,
  });
  
  
  String date_string() {
    return DateFormat('h:mm a - MMM d, yyyy').format(date);
  }

  static Future<TextNote> load(String path) async {
    File file = File(path);
    if (await file.exists()) {
      final body = await file.readAsString();
      final title = p.basenameWithoutExtension(path);
      final finalTime = await file.lastModified();
      return TextNote(title: title, body: body, path: path, date: finalTime, type: NoteType.TextNote);
    }
    throw Exception("File does not exist at $path");
  }


  Future<void> save(String oldTitle) async {
    try {
      String newTitle = sanitizeFileName(title.trim());

      if (newTitle.isEmpty) {
        newTitle = sanitizeFileName(DateFormat('h:mm a - MMM d, yyyy').format(DateTime.now()));
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

  Widget display() {
    return Column(
      children: [
        Container(
          width: 180,
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: icon_color,
              width: 1,
            ),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              body,
              maxLines: 10,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: icon_color,
                fontSize: 13,
                height: 1.5,
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
          style: const TextStyle(
            color: icon_color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          date_string(),
          style: TextStyle(
            color: accent,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}