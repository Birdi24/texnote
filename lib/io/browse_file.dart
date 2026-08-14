import 'dart:convert';
import 'package:saf/saf.dart';
import '../models/note.dart';

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
      final preview = body.length > 100 ? "${body.substring(0, 97)}..." : body;
      final finalTime = DateTime.fromMillisecondsSinceEpoch(pickedFile.lastModified);
      return Note( title, body, fileUri,finalTime);
    } catch (e) {
      print("Error while executing browseFiles: $e"); return null;
    }
  }
}