import 'dart:async';
import 'package:path_provider/path_provider.dart';

import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';

import 'package:flutter/material.dart';
import 'CanvasView.dart';
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

class _HandwrittenNotePage extends State<HandwrittenNotePage> with WidgetsBindingObserver {
  // Timer for auto-saving the note
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _allowPop = false;

  // Top canvas holds frequently refreshing parts of the note, like the last 50 strokes
  final GlobalKey<TopCanvasState> _topCanvasKey = GlobalKey<TopCanvasState>();
  final GlobalKey<CanvasViewState> _canvasViewKey = GlobalKey<CanvasViewState>();

  bool changed = false;
  String old_title = "";
  LazyPdfPageStore? _pdfStore;

  Future<void> _handleBack() async {
    if (_isSaving) return;

    _isSaving = true;

    try {
      debugPrint("HandwrittenNotePage: button back - saving");

      await save();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("HandwrittenNotePage: button back save failed: $e");
    } finally {
      _isSaving = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    old_title = widget.note.title;
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) => save());

    if (widget.note.pdfSourcePath.isNotEmpty) {
      getApplicationDocumentsDirectory().then((appDir) {
        if (!mounted) return;
        setState(() {
          _pdfStore = LazyPdfPageStore(
            pdfPath: widget.note.pdfSourcePath,
            noteDir: appDir,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pdfStore?.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      save();
    }
  }

  void _markChanged() {
    if (!changed) {setState(() {changed = true;});}
  }

  Future<String?> _resolvePageBackground(NotePage page) async {
    if (_pdfStore == null) return null;
    
    int? pdfPageNum;
    
    if (page.source.type == PageSourceType.pdf && page.source.originalIndex != null) {
      pdfPageNum = page.source.originalIndex;
    } else if (page.background != null && page.background!.startsWith("pdf_page:")) {
      pdfPageNum = int.tryParse(page.background!.split(":").last);
    }
    
    if (pdfPageNum == null) return null;

    final path = await _pdfStore!.pathForPage(pdfPageNum);
    page.background = path; // cache result back onto the model
    return path;
  }

  Future<void> save() async {
    // Flush any pending volatile content from TopCanvas to NotePages before saving
    _topCanvasKey.currentState?.flush();

    if (!changed) return;
    
    await widget.note.save(old_title);
    
    if (mounted) {
      setState(() {
        changed = false;
      });
      _canvasViewKey.currentState?.refreshPartitions();
    }
    old_title = widget.note.title;
  }

  /// commit top layer to the bottom layer
  void _commitToBottom(List<Stroke> strokes, List<ImageData> images, List<TextData> texts) {
    // In the new architecture, CanvasView handles the partitioning.
    // This callback is now mainly for marking the note as changed.
    _markChanged();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!_isSaving) {
          _isSaving = true;
          debugPrint("HandwrittenNotePage: onPopInvoked - saving before pop");
          try {
            await save();
          } catch (e) {
            debugPrint("HandwrittenNotePage: error saving before pop: $e");
          } finally {
            _isSaving = false;
          }
          if (mounted) {
            setState(() {
              _allowPop = true;
            });
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
              pages: widget.note.pages,
              onCommit: _commitToBottom,
              topCanvasKey: _topCanvasKey,
              onSave: save,
              changed: changed,
              onChanged: _markChanged,
              paperType: widget.note.paperType,
              resolvePageBackground: _resolvePageBackground,
              onPageChanged: (index) {
                _pdfStore?.onCurrentPageChanged(index + 1);
              },
              onBack: _handleBack,
            );
            },
          ),
        ),
      ),
    );
  }
}

