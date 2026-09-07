import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import './stroke.dart';
import '../app_style.dart';
import 'Note.dart';
import './ImageData.dart';
import './TextData.dart';

class HandwrittenNote extends Note {
  String cover ="1";
  String paperType = "blank";
  List<Stroke> strokes = [];
  List<String?> pageBackgrounds = [];
  String pdfSourcePath;
  List<ImageData> images = [];
  List<TextData> texts = [];

  HandwrittenNote({
    required super.title,
    required super.date,
    required super.path,
    required super.type,
    this.paperType = "blank",
    super.isFavorite = false,
    List<String?> pageBackgrounds = const [],
    this.pdfSourcePath = "",
    List<ImageData> images = const [],
    List<TextData> texts = const [],
  })  : pageBackgrounds = List<String?>.from(pageBackgrounds),
        images = List<ImageData>.from(images),
        texts = List<TextData>.from(texts);


  /// json representation of the note
  String get_json() {
    return jsonEncode({
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'cover': cover,
      'paperType': paperType,
      'pageBackgrounds': pageBackgrounds,
      'images': images.map((i) => i.toMap()).toList(),
      'texts': texts.map((t) => t.toMap()).toList(),
    });
  }

  /// loads a HandwrittenNote from a file
  static Future<HandwrittenNote> load(String path) async {
    debugPrint("Loading HandwrittenNote from $path");

    File file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      final finalTime = await file.lastModified();
      
      final note = await compute(_parseNoteData, {
        'content': content,
        'path': path,
        'finalTime': finalTime,
      });
      
      debugPrint("HandwrittenNote loaded: ${note.title} with ${note.strokes.length} strokes");
      return note;
    }
    throw Exception("File does not exist at $path");
  }


  static HandwrittenNote _parseNoteData(Map<String, dynamic> params) {
    final content = params['content'] as String;
    final path = params['path'] as String;
    final finalTime = params['finalTime'] as DateTime;

    final Map<String, dynamic> data = jsonDecode(content);
    final title = p.basenameWithoutExtension(path);

    final note = HandwrittenNote(
        title: title,
        path: path,
        date: finalTime,
        type: NoteType.HandwrittenNote,
        paperType: data['paperType'] ?? "blank",
        pageBackgrounds: (data['pageBackgrounds'] as List<dynamic>?)?.map((e) => e?.toString()).toList() ?? [],
        images: (data['images'] as List<dynamic>?)?.map((e) => ImageData.fromMap(e as Map<String, dynamic>)).toList() ?? [],
        texts: (data['texts'] as List<dynamic>?)?.map((e) => TextData.fromMap(e as Map<String, dynamic>)).toList() ?? []
    );
    if (data['strokes'] != null) {
      note.strokes = (data['strokes'] as List)
          .map((s) => Stroke.fromMap(s as Map<String, dynamic>))
          .toList();
    }
    
    // Ensure pageBackgrounds is never empty and covers all strokes/images/texts
    double maxY = 0;
    for (final stroke in note.strokes) {
      final b = stroke.getBounds();
      if (b.bottom > maxY) maxY = b.bottom;
    }
    for (final img in note.images) {
      final b = img.getBounds();
      if (b.bottom > maxY) maxY = b.bottom;
    }
    for (final txt in note.texts) {
      final b = txt.getBounds();
      if (b.bottom > maxY) maxY = b.bottom;
    }
    
    // Use 1000.0 as a default logical page height if we don't know the screen size
    int requiredPages = (maxY / 1000.0).ceil();
    if (requiredPages > note.pageBackgrounds.length) {
      while (note.pageBackgrounds.length < requiredPages) {
        note.pageBackgrounds.add(null);
      }
    }
    
    if (note.pageBackgrounds.isEmpty) {
      note.pageBackgrounds.add(null);
    }

    note.cover = data['cover'] ?? "1";
    return note;
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
            '$newTitle.note',
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

      final newPath = p.join(directoryPath, '$newTitle.note');

      debugPrint("NewPath: $newPath");

      // Rename an existing BirdWrite file
      if (oldTitle.isNotEmpty && newTitle != oldTitle) {
        debugPrint("Title has changed");

        final oldPath = p.join(directoryPath, '$oldTitle.note');
        final oldFile = File(oldPath);

        if (await oldFile.exists()) {
          await oldFile.delete();
          debugPrint("$oldPath deleted!");
        }
      }

      final file = File(newPath);

      await file.writeAsString(get_json());

      title = newTitle;
      path = file.path;
      date = DateTime.now();

      debugPrint("Saved: ${file.path}");
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }


  Future<Note> duplicate_note() async {
    try {
      String newPath;
      if (path.endsWith('.note')) {
        newPath = path.replaceFirst(".note", "-Copy.note");
      } else {
        newPath = p.join(path, "${sanitizeFileName(title)}-Copy.note");
      }

      debugPrint("NEW PATH for duplicate: $newPath");
      final file = File(newPath);
      await file.writeAsString(get_json());
      HandwrittenNote dup = HandwrittenNote(
          title: title + "-Copy",
          date: DateTime.now(),
          path: newPath,
          type: type,
          paperType: paperType,
          pageBackgrounds: List.from(pageBackgrounds),
          images: images.map((i) => i.copy()).toList(),
          texts: texts.map((t) => t.copy()).toList(),
      );
      dup.strokes = strokes.map((s) => s.copy()).toList();
      dup.cover = cover;
      return dup;

    }
    catch (e) {
      debugPrint("Error duplicating note: $e");
      return HandwrittenNote(title: "INVALID", type: type, date: date,path: path);
    }
  }

  Widget display() {
    return Column(
      children: [
      AspectRatio(aspectRatio: 0.72, child :Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: collection_color(cover),
            border: Border.all(
              color: icon_color,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0, left: 0, bottom: 0, width: 16,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: ColoredBox(color: BLACK.withAlpha(25)),
                ),
              ),
              Positioned(
                  top: 0, left: 16, bottom: 0, width: 2,
                  child: ColoredBox(color: WHITE.withAlpha(50))
              )
            ],
          )
        )),

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

      final bytes = Uint8List.fromList(utf8.encode(get_json()));

      await saf.writeFileBytes(
        dir.uri,
        '$title.note',
        'application/octet-stream',
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
      
      const double logicalPageHeight = 1000.0;
      const double logicalPageWidth = 707.0;

      int numPages = pageBackgrounds.length;
      if (numPages == 0) {
        double maxY = 0;
        for (final stroke in strokes) {
          final bounds = stroke.getBounds();
          if (bounds.bottom > maxY) maxY = bounds.bottom;
        }
        numPages = (maxY / logicalPageHeight).ceil();
        if (numPages == 0) numPages = 1;
      }

      for (int i = 0; i < numPages; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Stack(
                  children: [
                    // Background Image
                    if (pageBackgrounds.length > i && pageBackgrounds[i] != null && pageBackgrounds[i] != "blank")
                      pw.Positioned.fill(
                        child: pw.Image(
                          pw.MemoryImage(File(pageBackgrounds[i]!).readAsBytesSync()),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    
                    // User-added Images
                    ...images.where((img) {
                      final startY = i * logicalPageHeight;
                      final endY = (i + 1) * logicalPageHeight;
                      // Simple check: if top of image is on this page
                      return img.position.dy >= startY && img.position.dy < endY;
                    }).map((img) {
                      final startY = i * logicalPageHeight;
                      final scaleX = PdfPageFormat.a4.width / logicalPageWidth;
                      final scaleY = PdfPageFormat.a4.height / logicalPageHeight;
                      return pw.Positioned(
                        left: img.position.dx * scaleX,
                        top: (img.position.dy - startY) * scaleY,
                        child: pw.Image(
                          pw.MemoryImage(File(img.imagePath).readAsBytesSync()),
                          width: img.width * scaleX,
                          height: img.height * scaleY,
                        ),
                      );
                    }),
                    
                    // User-added Texts
                    ...texts.where((txt) {
                      final startY = i * logicalPageHeight;
                      final endY = (i + 1) * logicalPageHeight;
                      return txt.position.dy >= startY && txt.position.dy < endY;
                    }).map((txt) {
                      final startY = i * logicalPageHeight;
                      final scaleX = PdfPageFormat.a4.width / logicalPageWidth;
                      final scaleY = PdfPageFormat.a4.height / logicalPageHeight;
                      return pw.Positioned(
                        left: txt.position.dx * scaleX,
                        top: (txt.position.dy - startY) * scaleY,
                        child: pw.SizedBox(
                          width: txt.width * scaleX,
                          height: txt.height * scaleY,
                          child: pw.Text(
                            txt.text,
                            style: pw.TextStyle(
                              fontSize: txt.fontSize * scaleY,
                              color: PdfColor.fromInt(txt.color.value),
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    // Paper Type & Strokes
                    pw.Positioned.fill(
                      child: pw.CustomPaint(
                        painter: (PdfGraphics canvas, PdfPoint size) {
                          // Paper Background
                          if (paperType != "blank") {
                            canvas.setStrokeColor(PdfColor.fromInt(0xFFEEEEEE));
                            canvas.setLineWidth(0.5);
                            if (paperType == "lined") {
                              for (double y = 30; y < size.y; y += 30) {
                                canvas.drawLine(0, size.y - y, size.x, size.y - y);
                              }
                            } else if (paperType == "dot-grid") {
                              for (double x = 25; x < size.x; x += 25) {
                                for (double y = 25; y < size.y; y += 25) {
                                  canvas.drawEllipse(x, size.y - y, 0.5, 0.5);
                                }
                              }
                            } else if (paperType == "full-grid") {
                              for (double x = 25; x < size.x; x += 25) {
                                canvas.drawLine(x, 0, x, size.y);
                              }
                              for (double y = 25; y < size.y; y += 25) {
                                canvas.drawLine(0, size.y - y, size.x, size.y - y);
                              }
                            }
                            canvas.strokePath();
                          }

                          // Strokes
                          final scaleX = size.x / logicalPageWidth;
                          final scaleY = size.y / logicalPageHeight;

                          for (final stroke in strokes) {
                            final bounds = stroke.getBounds();
                            final startY = i * logicalPageHeight;
                            final endY = (i + 1) * logicalPageHeight;

                            if (bounds.bottom > startY && bounds.top < endY) {
                              final freehandPoints = stroke.points.map((p) => PointVector(p.dx, p.dy, 0.5)).toList();
                              final outline = getStroke(
                                freehandPoints,
                                options: StrokeOptions(
                                  size: stroke.size,
                                  thinning: 0.5,
                                  smoothing: 0.5,
                                  streamline: 0.5,
                                  simulatePressure: false,
                                  start: StrokeEndOptions.start(
                                    cap: stroke.hasStartCap,
                                    taperEnabled: false,
                                  ),
                                  end: StrokeEndOptions.end(
                                    cap: stroke.hasEndCap,
                                    taperEnabled: false,
                                  ),
                                ),
                              );

                              if (outline.isNotEmpty) {
                                canvas.moveTo(outline.first.dx * scaleX, size.y - (outline.first.dy - startY) * scaleY);
                                for (final p in outline.skip(1)) {
                                  canvas.lineTo(p.dx * scaleX, size.y - (p.dy - startY) * scaleY);
                                }
                                canvas.closePath();
                                final adaptiveColor = getAdaptiveStrokeColor(stroke.color, WHITE);
                                canvas.setFillColor(PdfColor.fromInt(adaptiveColor.toARGB32()));
                                canvas.fillPath();
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

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

