import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';

class FileOpenerScreen {
  final Saf _saf = Saf(); Future<Note?> browseFiles() async {
    try {
      // Open Android's native file picker
      final pickedFile = await _saf.pickFile( mimeTypes: ['text/plain'], );
      // User cancelled
      if (pickedFile == null) {
        print("User cancelled the file picker.");
        return null;
      }
      print("Selected File Name: ${pickedFile.name}");
      print("Selected File Size: ${pickedFile.length} bytes");
      // Store the Android SAF URI, NOT a temporary file path.
      final String fileUri = pickedFile.uri;
      print("Original File URI: $fileUri"); // Read the file directly from its original location
      final bytes = await _saf.readFileBytes(fileUri);
      final body = utf8.decode(bytes);
      final title = pickedFile.name.replaceFirst( RegExp(r'\.[^.]+$'), '', );
      final finalTime = DateTime.fromMillisecondsSinceEpoch(pickedFile.lastModified);
      return TextNote(title: title, body: body, path: fileUri, date: finalTime, type: NoteType.TextNote);
    } catch (e) {
      print("Error while executing browseFiles: $e"); return null;
    }
  }
}

Future<List<TextNote>> collect() async {
  final directory = await getApplicationDocumentsDirectory();

  debugPrint("Directory: ${directory.path}");

  //final files = directory .listSync() .where((file) => file.path.endsWith('.txt')) .map((file) => File(file.path)) .toList();

  //final files = directory.listSync().where((file) => file.path.endsWith('.txt') &&   !file.uri.pathSegments.last.startsWith('.')).map((file) => File(file.path)).toList();

  final files = directory
      .listSync(recursive: true)
      .where((file) =>
  (file.path.endsWith('.txt') || file.path.endsWith('.tex')) &&
  !file.uri.pathSegments.last.startsWith('.'))
      .map((file) => File(file.path))
      .toList();
  debugPrint("Files found: ${files.length}");

  List<TextNote> notes = [];
  var i = 0;
  while (i < files.length) {
  String path = files[i].path;
  debugPrint("Processing file: $path");
  String title = path.split('/').last.replaceAll('.txt', '');
  String body = await files[i].readAsString();
  DateTime date = await files[i].lastModified();
  notes.add(TextNote(title: title, body: body, path: path, date: date, type: NoteType.TextNote));
  i++;
  }
  return notes;
}
