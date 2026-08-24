import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;

import '../app_style.dart';
import 'Note.dart';


class Stroke {
  final List<Offset> points;
  double size;
  final Color color;

  final bool hasStartCap;
  final bool hasEndCap;

  Path? _cachedPath;

  Stroke({
    required this.points,
    required this.size,
    required this.color,
    this.hasStartCap = true,
    this.hasEndCap = true,
  });

  void translate(Offset delta) {
    for (int i = 0; i < points.length; i++) {
      points[i] = points[i] + delta;
    }
    invalidateCache();
  }

  void scale(double scale, Offset origin) {
    for (int i = 0; i < points.length; i++) {
      points[i] = origin + (points[i] - origin) * scale;
    }
    size *= scale;
    invalidateCache();
  }

  Rect getBounds() {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].dx;
    double maxX = points[0].dx;
    double minY = points[0].dy;
    double maxY = points[0].dy;

    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(size / 2);
  }

  Stroke copy() {
    return Stroke(
      points: List.from(points),
      size: size,
      color: color,
      hasStartCap: hasStartCap,
      hasEndCap: hasEndCap,
    );
  }

  void invalidateCache() => _cachedPath = null;

  Path buildPath() {

    if (_cachedPath != null) return _cachedPath!;

    final freehandPoints =
    points.map((p) => PointVector(p.dx, p.dy, 0.5)).toList();

    final outline = getStroke(
      freehandPoints,
      options: StrokeOptions(
        size: size,
        thinning: 0.5,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: false,
        start: StrokeEndOptions.start(
          cap: hasStartCap,
          taperEnabled: false,
        ),
        end: StrokeEndOptions.end(
          cap: hasEndCap,
          taperEnabled: false,
        ),
      ),
    );

    final path = Path();
    if (outline.isNotEmpty) {
      path.moveTo(outline.first.dx, outline.first.dy);
      for (final point in outline.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }

    _cachedPath = path;
    return path;
  }


  String get_string() {
    String ret = "Stroke:";
    for (final point in points) {
      ret += "${point.dx},${point.dy},";
    }
    ret += "\nsize:$size\ncolor:$color\n";
    return ret;
  }
}

class HandwrittenNote extends Note {
  String cover ="1";
  List<Stroke> strokes = [];

  HandwrittenNote({
    required super.title,
    required super.date,
    required super.path,
    required super.type,
    super.isFavorite = false,
  });


  String date_string() {
    return DateFormat('h:mm a - MMM d, yyyy').format(date);
  }

  String get_string(){
    String ret ="";
    for (int i = 0; i<strokes.length; i++) {
      ret+= strokes[i].get_string();
    }
    return ret;
  }

  static Future<HandwrittenNote> load(String path) async {
    File file = File(path);
    if (await file.exists()) {
      final strokes = await file.readAsString();
      final title = p.basenameWithoutExtension(path);
      final finalTime = await file.lastModified();
      return HandwrittenNote(title: title, path: path, date: finalTime, type: NoteType.TextNote);
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

      await file.writeAsString(get_string());

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
      if (path.endsWith('.note')) {
        newPath = path.replaceFirst(".note", "-Copy.note");
      } else {
        newPath = p.join(path, "${sanitizeFileName(title)}-Copy.note");
      }

      debugPrint("NEW PATH for duplicate: $newPath");
      final file = File(newPath);
      await file.writeAsString(get_string());
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
            color: collection_color(cover),
            border: Border.all(
              color: icon_color,
              width: 1,
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

