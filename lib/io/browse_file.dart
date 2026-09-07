import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:saf/saf.dart';

import '../models/HandwrittenNote.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';

class FileOpenerScreen {
  final Saf _saf = Saf();

  // For importing PDFs into the app
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
        pdfSourcePath: pdfPath,
        pageBackgrounds: List<String?>.filled(
          pagesCount,
          null,
        ), // rendered lazily
      );

      await note.save("");
      return note;
    } catch (e) {
      debugPrint("Error importing PDF: $e");
      return null;
    }
  }
}

// collects the notes from the directory to display on the home screen
Future<List<Note>> collect() async {
  final stopwatch = Stopwatch()..start();
  final directory = await getApplicationDocumentsDirectory();

  debugPrint("Directory: ${directory.path}");

  final files = directory
      .listSync(recursive: true)
      .where(
        (file) =>
            (file.path.endsWith('.txt') ||
                file.path.endsWith('.note')) &&
            !file.uri.pathSegments.last.startsWith('.'),
      )
      .map((file) => File(file.path))
      .toList();
  debugPrint("Files found: ${files.length}");

  final noteFutures = files.map((file) async {
    final path = file.path;
    debugPrint("Processing file: $path");
    try {
      if (path.endsWith('.note')) {
        return await HandwrittenNote.load(path);
      } else {
        return await TextNote.load(path);
      }
    } catch (e) {
      debugPrint("Error loading note at $path: $e");
      return null;
    }
  });

  final loadedNotes = await Future.wait(noteFutures);
  final notes = loadedNotes.whereType<Note>().toList();
  debugPrint(
    "Loaded ${notes.length} notes in ${stopwatch.elapsedMilliseconds}ms",
  );
  return notes;
}
