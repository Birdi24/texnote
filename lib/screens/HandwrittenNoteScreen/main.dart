import 'dart:async';
import 'dart:io';

import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'CanvasView.dart';
import 'BottomCanvas.dart';
import '../../app_style.dart';
import '../../io/LazyPdfPageStore.dart';
import '../../models/HandwrittenNote.dart';
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
  bool _isSaving = false;

  // Top canvas holds frequently refreshing parts of the note, like the last 50 strokes
  final GlobalKey<TopCanvasState> _topCanvasKey = GlobalKey<TopCanvasState>();
  final GlobalKey<CanvasViewState> _canvasViewKey = GlobalKey<CanvasViewState>();

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

    if (pageIndex >= widget.note.pageBackgrounds.length) return "blank";

    final background = widget.note.pageBackgrounds[pageIndex];

    // 1. Explicitly blank page
    if (background == "blank") return "blank";

    // 2. Symbolic PDF page marker (Robust for reordering)
    if (background != null && background.startsWith("pdf_page:")) {
      try {
        final pdfPageNum = int.parse(background.split(":").last);
        return await _pdfStore!.pathForPage(pdfPageNum);
      } catch (e) {
        debugPrint("Error parsing PDF page marker: $background - $e");
      }
    }

    // 3. Fallback for legacy notes or newly added slots (Counting logic)
    int pdfPageIndex = 0;
    for (int i = 0; i < pageIndex; i++) {
      final bg = widget.note.pageBackgrounds[i];
      // Anything not marked "blank" is assumed to be a PDF page slot in sequence
      if (bg != "blank") {
        pdfPageIndex++;
      }
    }

    try {
      final path = await _pdfStore!.pathForPage(pdfPageIndex + 1);
      
      // Upgrade the marker in memory if it was null/legacy
      if (widget.note.pageBackgrounds[pageIndex] == null || 
          widget.note.pageBackgrounds[pageIndex]!.startsWith("/")) {
         widget.note.pageBackgrounds[pageIndex] = "pdf_page:${pdfPageIndex + 1}";
         _markChanged();
      }

      return path;
    } catch (e) {
      debugPrint("PDF page resolution failed: note page=$pageIndex, pdf page=${pdfPageIndex + 1}: $e");
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
      });
      _canvasViewKey.currentState?.refreshPartitions();
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
    _markChanged();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !changed || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (changed && !_isSaving) {
          setState(() => _isSaving = true);
          debugPrint("HandwrittenNotePage: onPopInvoked - saving before pop");
          await save();
          if (mounted) {
            debugPrint("HandwrittenNotePage: save completed, popping");
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: BG.withAlpha(252),
  
          body: SafeArea(
            child: LayoutBuilder(builder: (context, safeAreaConstraints) {
            return CanvasView(
              key: _canvasViewKey,
              bottomLayerStrokes: bottomlayer,
              images: widget.note.images,
              texts: widget.note.texts,
              onCommit: _commitToBottom,
              topCanvasKey: _topCanvasKey,
              onSave: save,
              changed: changed,
              onChanged: _markChanged,
              paperType: widget.note.paperType,
              bottomCanvasKey: GlobalKey<BottomCanvasState>(),
              pageBackgrounds: widget.note.pageBackgrounds,
              resolvePageBackground: _resolvePageBackground,
              onPageChanged: (index) {
                _pdfStore?.onCurrentPageChanged(index + 1);
              },
            );
            },
          ),
        ),
      ),
    );
  }
}

