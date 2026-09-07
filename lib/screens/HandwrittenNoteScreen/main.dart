import 'dart:async';
import 'dart:io';

import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:birdwrite/screens/HandwrittenNoteScreen/CanvasView.dart';
import '../../app_style.dart';
import '../../io/LazyPdfPageStore.dart';
import '../../models/HandwrittenNote.dart';
import 'BottomCanvas.dart';
import 'TopCanvas.dart';

class HandwrittenNotePage extends StatefulWidget {
  final HandwrittenNote note;

  const HandwrittenNotePage({
    super.key,
    required this.note,
  });

  @override
  State<HandwrittenNotePage> createState() => _HandwrittenNotePage();
}

class _HandwrittenNotePage extends State<HandwrittenNotePage> {
  // Timer for auto-saving the note
  Timer? _autoSaveTimer;

  // Bottom canvas holds rarely refreshing parts of the note
  final GlobalKey<BottomCanvasState> _bottomCanvasKey = GlobalKey<BottomCanvasState>();

  // Top canvas holds frequently refreshing parts of the note, like the last 50 strokes
  final GlobalKey<TopCanvasState> _topCanvasKey = GlobalKey<TopCanvasState>();

  final List<Stroke> bottomlayer = [];
  bool changed = false;
  String old_title = "";
  LazyPdfPageStore? _pdfStore;

  @override
  void initState() {
    super.initState();
    old_title = widget.note.title;
    bottomlayer.addAll(widget.note.strokes);
    _autoSaveTimer = Timer.periodic( const Duration(minutes: 1), (_) => save(),);

    if (widget.note.pdfSourcePath.isNotEmpty) {
      _pdfStore = LazyPdfPageStore(
        pdfPath: widget.note.pdfSourcePath,
        noteDir: Directory(p.dirname(widget.note.pdfSourcePath)),
      );
    }
  }

  @override
  void dispose() {
    _pdfStore?.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _markChanged() {
    if (!changed) {setState(() {changed = true;});}
  }

  Future<String?> _resolvePageBackground(int pageIndex) async {
    if (_pdfStore == null) return null;

    // Page explicitly marked blank.
    if (pageIndex < widget.note.pageBackgrounds.length &&
        widget.note.pageBackgrounds[pageIndex] == "blank") {
      return "blank";
    }

    // No entry means blank/new page.
    if (pageIndex >= widget.note.pageBackgrounds.length) {
      return "blank";
    }

    // Count PDF-backed pages before this page.
    int pdfPageIndex = 0;

    // Skip blank pages as they were added by the user
    for (int i = 0; i < pageIndex; i++) {
      final background = widget.note.pageBackgrounds[i];
      if (background != "blank") {pdfPageIndex++;}
    }

    // if its a PDF page, then try to resolve it
    try {
      final path = await _pdfStore!.pathForPage(pdfPageIndex + 1);
      widget.note.pageBackgrounds[pageIndex] = path;

      return path;
    } catch (e) {
      debugPrint("PDF page resolution failed: note page=$pageIndex, pdf page=${pdfPageIndex + 1}: $e",);
      return "blank";
    }
  }

  Future<void> save() async {
    if (!changed) return;
    
    // Move everything from the volatile top layer to the persistent bottom layer
    final topStrokes = _topCanvasKey.currentState?.getStrokes() ?? [];
    final topImages = _topCanvasKey.currentState?.getImages() ?? [];
    final topTexts = _topCanvasKey.currentState?.getTexts() ?? [];
    
    if (topStrokes.isNotEmpty || topImages.isNotEmpty || topTexts.isNotEmpty) {
      _topCanvasKey.currentState?.setStrokes([]);
      _topCanvasKey.currentState?.setImages([]);
      _topCanvasKey.currentState?.setTexts([]);
      
      bottomlayer.addAll(topStrokes);
      widget.note.images.addAll(topImages);
      widget.note.texts.addAll(topTexts);
    }
    
    // Synchronize the note model with our local bottom layer
    widget.note.strokes = List<Stroke>.from(bottomlayer);
    
    await widget.note.save(old_title);
    
    if (mounted) {
      setState(() {
        changed = false;
        _bottomCanvasKey.currentState?.updateStrokes(List<Stroke>.from(bottomlayer));
      });
    }
    old_title = widget.note.title;
  }

  /// add everything from the top layer to the bottom layer
  void _commitToBottom(List<Stroke> strokes, List<ImageData> images, List<TextData> texts) {
    setState(() {
      bottomlayer.addAll(strokes);
      widget.note.images.addAll(images);
      widget.note.texts.addAll(texts);
    });
    _bottomCanvasKey.currentState?.updateStrokes(List<Stroke>.from(bottomlayer));
    _markChanged();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (changed) {
          debugPrint("Handwritten note saved at: ${widget.note.path}");
          await save();
        }
      },
      child: Scaffold(
        backgroundColor: BG.withAlpha(252),
  
          body: SafeArea(
            child: LayoutBuilder(builder: (context, safeAreaConstraints) {
            return CanvasView(
              bottomLayerStrokes: bottomlayer,
              images: widget.note.images,
              texts: widget.note.texts,
              onCommit: _commitToBottom,
              bottomCanvasKey: _bottomCanvasKey,
              topCanvasKey: _topCanvasKey,
              onSave: save,
              changed: changed,
              onChanged: _markChanged,
              paperType: widget.note.paperType,
              pageBackgrounds: widget.note.pageBackgrounds,
              resolvePageBackground: _resolvePageBackground,
            );
            },
          ),
        ),
      ),
    );
  }
}

