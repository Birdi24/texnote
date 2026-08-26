import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';
import '../models/HandwrittenNote.dart';

class FileOpenerScreen {
  final Saf _saf = Saf(); 

  Future<Note?> browseFiles() async {
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

  Future<HandwrittenNote?> importPdf() async {
    try {
      final pickedFile = await _saf.pickFile(mimeTypes: ['application/pdf']);
      if (pickedFile == null) return null;

      final bytes = await _saf.readFileBytes(pickedFile.uri);

      final appDocDir = await getApplicationDocumentsDirectory();
      final title = pickedFile.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final noteDir = Directory(
        p.join(appDocDir.path, 'pdf_imports', '${title}_$timestamp'),
      );
      await noteDir.create(recursive: true);

      // Copy the source PDF locally — we keep it around and reopen it
      // lazily whenever a page needs rendering.
      final pdfPath = p.join(noteDir.path, 'source.pdf');
      await File(pdfPath).writeAsBytes(bytes);

      // Just peek at page count, then close immediately. No rendering.
      final document = await PdfDocument.openFile(pdfPath);
      final pagesCount = document.pagesCount;
      await document.close();

      final notePath = p.join(appDocDir.path, '$title.note');
      final note = HandwrittenNote(
        title: title,
        date: DateTime.now(),
        path: notePath,
        type: NoteType.HandwrittenNote,
        pdfSourcePath: pdfPath,          // new field
        pageBackgrounds: List<String?>.filled(pagesCount, null), // rendered lazily
      );

      await note.save("");
      return note;
    } catch (e) {
      debugPrint("Error importing PDF: $e");
      return null;
    }
  }
}

Future<List<Note>> collect() async {
  final directory = await getApplicationDocumentsDirectory();

  debugPrint("Directory: ${directory.path}");

  final files = directory
      .listSync(recursive: true)
      .where((file) =>
  (file.path.endsWith('.txt') || file.path.endsWith('.json') || file.path.endsWith('.note')) &&
  !file.uri.pathSegments.last.startsWith('.'))
      .map((file) => File(file.path))
      .toList();
  debugPrint("Files found: ${files.length}");
  for (var f in files) {
    debugPrint("Found file: ${f.path}");
  }

  List<Note> notes = [];
  var i = 0;
  while (i < files.length) {
    String path = files[i].path;
    debugPrint("Processing file: $path");
    
    try {
      if (path.endsWith('.note')) {
        notes.add(await HandwrittenNote.load(path));
      } else {
        notes.add(await TextNote.load(path));
      }
    } catch (e) {
      debugPrint("Error loading note at $path: $e");
    }
    i++;
  }
  return notes;
}
