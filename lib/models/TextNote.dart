import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dart_quill_delta/dart_quill_delta.dart';

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


  /// loads a TextNote from a file
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

  /// saves a TextNote to a file
  @override
  Future<void> save(String oldTitle) async {
    debugPrint("TextNote.save(oldTitle: '$oldTitle') started for '$title'");
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

      // Rename an existing BirdWrite file
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
      path = p.canonicalize(file.path);
      date = DateTime.now();

      debugPrint("TextNote.save(): Saved to ${file.path}. Path updated to $path");
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }

  /// creates a duplicate of a TextNote
  @override
  Future<Note> duplicate_note() async {
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
      TextNote dup = TextNote(title :"$title-Copy",date: DateTime.now(),path: newPath, body: body, type: NoteType.TextNote);
      return dup;
    }
    catch (e) {
      debugPrint("Error duplicating note: $e");
      return TextNote(title: "INVALID", type: type, date: date,path: path,body: "");
    }
  }

  /// returns a preview of the note's body
  String getPreviewText() {
    try {
      if (body.startsWith('[') || body.startsWith('{')) {
        final decoded = jsonDecode(body);
        if (decoded is List) {
          final delta = Delta.fromJson(decoded);
          return delta.operations
                      .where((op) => op.isInsert && op.data is String)
                      .map((op) => op.data as String)
                      .join('');
        }
      }
    } catch (_) {}
    return body;
  }

  /// returns a widget representing the note
  @override
  Widget display() {
    return Column(
      children: [
        AspectRatio(aspectRatio: 0.72, child :Container(
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
          getPreviewText(),
          maxLines: 10,
          overflow: TextOverflow.fade,
          style: TextStyle(

            color: icon_color,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    ),),
        

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
          date_string(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: accent,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Future<void> export() async {
    try {
      final saf = Saf();
      final dir = await saf.pickDirectory();
      if (dir == null) return;

      final bytes = Uint8List.fromList(utf8.encode(getPreviewText()));

      await saf.writeFileBytes(
        dir.uri,
        '$title.txt',
        'text/plain',
        bytes,
      );
    } catch (e) {
      debugPrint("Error exporting note: $e");
    }
  }

  @override
  Future<void> exportAsPdf() async {
    try {
      final pdf = pw.Document();

      List<pw.Widget> content = [];
      content.add(pw.Header(level: 0, text: title));

      try {
        if (body.startsWith('[') || body.startsWith('{')) {
          final decoded = jsonDecode(body);
          if (decoded is List) {
            final delta = Delta.fromJson(decoded);

            for (var op in delta.operations) {
              if (op.isInsert && op.data is String) {
                final text = op.data as String;
                final bool isBold = op.attributes != null && op.attributes!['bold'] == true;
                final bool isItalic = op.attributes != null && op.attributes!['italic'] == true;

                content.add(
                  pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                    ),
                  ),
                );
              }
            }
          } else {
            content.add(pw.Paragraph(text: getPreviewText()));
          }
        } else {
          content.add(pw.Paragraph(text: getPreviewText()));
        }
      } catch (e) {
        debugPrint("Error parsing rich text for PDF: $e");
        content.add(pw.Paragraph(text: getPreviewText()));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Wrap(
                children: content,
              )
            ];
          },
        ),
      );

      final saf = Saf();
      final dir = await saf.pickDirectory();
      if (dir == null) return;

      final bytes = await pdf.save();

      await saf.writeFileBytes(
        dir.uri,
        '$title.pdf',
        'application/pdf',
        bytes,
      );
    } catch (e) {
      debugPrint("Error exporting PDF: $e");
    }
  }
}