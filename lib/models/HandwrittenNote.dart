import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:saf/saf.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as px;
import 'dart:math';
import './stroke.dart';
import '../app_style.dart';
import 'Note.dart';
import './ImageData.dart';
import './TextData.dart';

enum PageSourceType { pdf, blank, duplicate }

class PageSource {
  final PageSourceType type;
  final int? originalIndex; // 1-based index from source PDF

  PageSource({required this.type, this.originalIndex});

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'originalIndex': originalIndex,
  };

  factory PageSource.fromMap(Map<String, dynamic> map) {
    return PageSource(
      type: PageSourceType.values.byName(map['type'] as String),
      originalIndex: map['originalIndex'] as int?,
    );
  }

  factory PageSource.pdf(int index) => PageSource(type: PageSourceType.pdf, originalIndex: index);
  factory PageSource.blank() => PageSource(type: PageSourceType.blank);
  factory PageSource.duplicate() => PageSource(type: PageSourceType.duplicate);
}

class NotePage {
  final String id;
  List<Stroke> strokes;
  List<ImageData> images;
  List<TextData> texts;
  String? background;
  PageSource source;

  NotePage({
    String? id,
    List<Stroke>? strokes,
    List<ImageData>? images,
    List<TextData>? texts,
    this.background,
    required this.source,
  })  : id = id ?? "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}",
        strokes = strokes ?? [],
        images = images ?? [],
        texts = texts ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'strokes': strokes.map((s) => s.toMap()).toList(),
    'images': images.map((i) => i.toMap()).toList(),
    'texts': texts.map((t) => t.toMap()).toList(),
    'background': background,
    'source': source.toMap(),
  };

  factory NotePage.fromMap(Map<String, dynamic> map) {
    return NotePage(
      id: map['id'] as String?,
      strokes: (map['strokes'] as List?)?.map((s) => Stroke.fromMap(s as Map<String, dynamic>)).toList(),
      images: (map['images'] as List?)?.map((i) => ImageData.fromMap(i as Map<String, dynamic>)).toList(),
      texts: (map['texts'] as List?)?.map((t) => TextData.fromMap(t as Map<String, dynamic>)).toList(),
      background: map['background'] as String?,
      source: PageSource.fromMap(map['source'] as Map<String, dynamic>),
    );
  }
}

class HandwrittenNote extends Note {
  String cover = "1";
  String paperType = "blank";
  List<NotePage> pages = [];
  String pdfSourcePath;

  HandwrittenNote({
    required super.title,
    required super.date,
    required super.path,
    required super.type,
    this.paperType = "blank",
    super.isFavorite = false,
    List<NotePage>? pages,
    this.pdfSourcePath = "",
  }) : pages = pages ?? [NotePage(source: PageSource.blank())];

  /// json representation of the note
  String get_json() {
    return jsonEncode({
      'pages': pages.map((p) => p.toMap()).toList(),
      'cover': cover,
      'paperType': paperType,
      'pdfSourcePath': pdfSourcePath,
    });
  }

  /// loads a HandwrittenNote from a file
  static Future<HandwrittenNote> load(String path) async {
    debugPrint("HandwrittenNote.load(path: $path) started");

    File file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      final finalTime = await file.lastModified();

      final note = _parseNoteData({
        'content': content,
        'path': path,
        'finalTime': finalTime,
      });

      debugPrint("HandwrittenNote.load(): Loaded '${note.title}' with ${note.pages.length} pages");
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
      pdfSourcePath: data['pdfSourcePath'] ?? "",
    );

    if (data['pages'] != null) {
      note.pages = (data['pages'] as List)
          .map((p) => NotePage.fromMap(p as Map<String, dynamic>))
          .toList();
    } else {
      // MIGRATION: Old flat format
      debugPrint("Migrating legacy flat HandwrittenNote: $title");
      
      const double logicalPageHeight = 1188.0;
      final List<String?> pageBackgrounds = (data['pageBackgrounds'] as List<dynamic>?)?.map((e) => e?.toString()).toList() ?? [];
      final List<Stroke> strokes = (data['strokes'] as List?)
          ?.map((s) => Stroke.fromMap(s as Map<String, dynamic>))
          .toList() ?? [];
      final List<ImageData> images = (data['images'] as List?)
          ?.map((e) => ImageData.fromMap(e as Map<String, dynamic>)).toList() ?? [];
      final List<TextData> texts = (data['texts'] as List?)
          ?.map((e) => TextData.fromMap(e as Map<String, dynamic>)).toList() ?? [];

      int numPages = pageBackgrounds.length;
      if (numPages == 0) {
        double maxY = 0;
        for (final s in strokes) {
          final b = s.getBounds();
          if (b.bottom > maxY) maxY = b.bottom;
        }
        numPages = (maxY / logicalPageHeight).ceil();
        if (numPages == 0) numPages = 1;
      }

      note.pages = List.generate(numPages, (i) {
        final pageStartY = i * logicalPageHeight;
        final pageEndY = (i + 1) * logicalPageHeight;
        
        String? bg = pageBackgrounds.length > i ? pageBackgrounds[i] : null;
        PageSource source;
        if (bg != null && bg.startsWith("pdf_page:")) {
          source = PageSource.pdf(int.parse(bg.split(":").last));
        } else if (bg != null && bg.contains("page_")) {
          // Try to recover page number from legacy absolute path
          final match = RegExp(r'page_(\d+)').firstMatch(bg);
          if (match != null) {
            int pageNum = int.parse(match.group(1)!);
            source = PageSource.pdf(pageNum);
            bg = "pdf_page:$pageNum"; // Convert back to marker to force new cache usage
          } else {
            source = PageSource.blank();
          }
        } else {
          source = PageSource.blank();
        }

        final pageStrokes = strokes.where((s) {
          final centerY = s.getBounds().center.dy;
          return centerY >= pageStartY && centerY < pageEndY;
        }).map((s) => s.translate(Offset(0, -pageStartY))).toList();

        final pageImages = images.where((img) {
          final centerY = img.getBounds().center.dy;
          return centerY >= pageStartY && centerY < pageEndY;
        }).map((img) => img.translate(Offset(0, -pageStartY))).toList();

        final pageTexts = texts.where((txt) {
          final centerY = txt.getBounds().center.dy;
          return centerY >= pageStartY && centerY < pageEndY;
        }).map((txt) => txt.translate(Offset(0, -pageStartY))).toList();

        return NotePage(
          strokes: pageStrokes,
          images: pageImages,
          texts: pageTexts,
          background: bg,
          source: source,
        );
      });
    }

    note.cover = data['cover'] ?? "1";
    return note;
  }

  @override
  Future<void> move_to(String targetDirectory) async {
    final oldPath = path;
    final oldPdfPath = pdfSourcePath;
    
    await super.move_to(targetDirectory);
    
    // If the PDF is a separate file in the same directory, move it too.
    // Avoid double-moving if path and pdfSourcePath were the same (raw PDF case).
    if (oldPdfPath.isNotEmpty && oldPdfPath != oldPath) {
      final oldDir = p.dirname(oldPath);
      if (p.dirname(oldPdfPath) == oldDir) {
        final pdfFile = File(oldPdfPath);
        if (await pdfFile.exists()) {
          final pdfName = p.basename(oldPdfPath);
          final newPdfPath = p.join(targetDirectory, pdfName);
          await pdfFile.rename(newPdfPath);
          pdfSourcePath = newPdfPath;
        }
      }
    } else if (oldPdfPath == oldPath && path.endsWith('.pdf')) {
      // Raw PDF was moved by super.move_to, update pdfSourcePath to new path
      pdfSourcePath = path;
    }
  }

  Future<void> _syncPdfBackground(String directoryPath, String newTitle) async {
    if (pdfSourcePath.isEmpty) return;

    final newPdfPath = p.join(directoryPath, '${newTitle}_bg.pdf');

    // Check if we need to regenerate
    bool needsUpdate = !File(newPdfPath).existsSync() || pdfSourcePath != newPdfPath;
    if (!needsUpdate) return;

    debugPrint("Syncing PDF background to $newPdfPath");

    try {
      final sourceFile = File(pdfSourcePath);
      if (await sourceFile.exists()) {
        if (pdfSourcePath != newPdfPath) {
          await sourceFile.copy(newPdfPath);
        }
        pdfSourcePath = newPdfPath;
      }
    } catch (e) {
      debugPrint("Error syncing PDF background: $e");
    }
  }

  @override
  Future<void> save(String oldTitle) async {
    debugPrint("HandwrittenNote.save(oldTitle: '$oldTitle') started for '$title'");
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

      // Sync PDF background first so get_json() uses updated paths/markers
      await _syncPdfBackground(directoryPath, newTitle);

      // Rename an existing BirdWrite file
      if (oldTitle.isNotEmpty && newTitle != oldTitle) {
        debugPrint("Title has changed");

        final oldPath = p.join(directoryPath, '$oldTitle.note');
        final oldFile = File(oldPath);

        if (await oldFile.exists()) {
          await oldFile.delete();
          debugPrint("$oldPath deleted!");
        }

        // Also delete old PDF background
        final oldPdfPath = p.join(directoryPath, '${oldTitle}_bg.pdf');
        final oldPdfFile = File(oldPdfPath);
        if (await oldPdfFile.exists()) {
          await oldPdfFile.delete();
          debugPrint("$oldPdfPath deleted!");
        }
      }

      final file = File(newPath);

      await file.writeAsString(get_json());

      title = newTitle;
      path = p.canonicalize(file.path);
      date = DateTime.now();

      debugPrint("HandwrittenNote.save(): Saved to ${file.path}. Path updated to $path");
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }


  @override
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

      List<NotePage> duplicatedPages = pages.map((page) => NotePage(
        id: "${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}",
        strokes: page.strokes.map((s) => s.copy()).toList(),
        images: page.images.map((i) => i.copy()).toList(),
        texts: page.texts.map((t) => t.copy()).toList(),
        background: page.background,
        source: PageSource(type: page.source.type, originalIndex: page.source.originalIndex),
      )).toList();

      HandwrittenNote dup = HandwrittenNote(
        title: "$title-Copy",
        date: DateTime.now(),
        path: newPath,
        type: type,
        paperType: paperType,
        pages: duplicatedPages,
        pdfSourcePath: pdfSourcePath,
      );
      dup.cover = cover;
      return dup;
    } catch (e) {
      debugPrint("Error duplicating note: $e");
      return HandwrittenNote(title: "INVALID", type: type, date: date, path: path);
    }
  }

  @override
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
    px.PdfDocument? bgPdf;
    try {
      final pdf = pw.Document();

      const double logicalPageHeight = 1188.0;
      const double logicalPageWidth = 840.0;

      if (pdfSourcePath.isNotEmpty) {
        try {
          bgPdf = await px.PdfDocument.openFile(pdfSourcePath);
        } catch (e) {
          debugPrint("Could not open PDF source for export: $e");
        }
      }

      for (var pageObj in pages) {
        // Pre-render background if it's a PDF page
        pw.MemoryImage? bgImage;
        final bg = pageObj.background;
        PdfPageFormat pageFormat = PdfPageFormat.a4;

        if (bg != null) {
          if (bg.startsWith("pdf_page:")) {
            if (bgPdf != null) {
              try {
                final pageNum = int.parse(bg.split(":").last);
                final page = await bgPdf.getPage(pageNum);
                final img = await page.render(
                  width: page.width * 2,
                  height: page.height * 2,
                  format: px.PdfPageImageFormat.jpeg,
                );
                if (img != null) bgImage = pw.MemoryImage(img.bytes);

                // Match exported PDF page format to the source PDF page size
                pageFormat = PdfPageFormat(page.width.toDouble(), page.height.toDouble());
                await page.close();
              } catch (e) {
                debugPrint("Error rendering PDF page for export: $e");
              }
            }
          } else if (bg != "blank") {
            try {
              final file = File(bg);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                bgImage = pw.MemoryImage(bytes);
                try {
                  final codec = await ui.instantiateImageCodec(bytes);
                  final frameInfo = await codec.getNextFrame();
                  final decodedImage = frameInfo.image;
                  pageFormat = PdfPageFormat(decodedImage.width.toDouble(), decodedImage.height.toDouble());
                  decodedImage.dispose();
                  codec.dispose();
                } catch (e) {
                  debugPrint("Error decoding image dimensions for export: $e");
                }
              }
            } catch (e) {
              debugPrint("Error loading image background for export: $e");
            }
          }
        }

        final scaleX = pageFormat.width / logicalPageWidth;
        final scaleY = pageFormat.height / logicalPageHeight;

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Stack(
                  children: [
                    // Background Image
                    if (bgImage != null)
                      pw.Positioned.fill(
                        child: pw.Image(
                          bgImage,
                          fit: pw.BoxFit.fill,
                        ),
                      ),

                    // User-added Images
                    ...pageObj.images.map((img) {
                      return pw.Positioned(
                        left: img.position.dx * scaleX,
                        top: img.position.dy * scaleY,
                        child: pw.Image(
                          pw.MemoryImage(File(img.imagePath).readAsBytesSync()),
                          width: img.width * scaleX,
                          height: img.height * scaleY,
                        ),
                      );
                    }),

                    // User-added Texts
                    ...pageObj.texts.map((txt) {
                      return pw.Positioned(
                        left: txt.position.dx * scaleX,
                        top: txt.position.dy * scaleY,
                        child: pw.SizedBox(
                          width: txt.width * scaleX,
                          height: txt.height * scaleY,
                          child: pw.Text(
                            txt.text,
                            style: pw.TextStyle(
                              fontSize: txt.fontSize * scaleY,
                              color: PdfColor.fromInt(txt.color.toARGB32()),
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
                          final strokeScaleX = size.x / logicalPageWidth;
                          final strokeScaleY = size.y / logicalPageHeight;

                          for (final stroke in pageObj.strokes) {
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
                              canvas.moveTo(outline.first.dx * strokeScaleX, size.y - outline.first.dy * strokeScaleY);
                              for (final p in outline.skip(1)) {
                                canvas.lineTo(p.dx * strokeScaleX, size.y - p.dy * strokeScaleY);
                              }
                              canvas.closePath();
                              final adaptiveColor = getAdaptiveStrokeColor(stroke.color, WHITE);
                              canvas.setFillColor(PdfColor.fromInt(adaptiveColor.toARGB32()));
                              canvas.fillPath();
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
    } finally {
      await bgPdf?.close();
    }
  }
}
