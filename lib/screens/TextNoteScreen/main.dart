import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/TextNote.dart';
import 'note_body.dart';
import 'note_botton.dart';
import 'note_top.dart';
import 'note_body_helper_functions.dart';

class TextNoteScreen extends StatefulWidget {
  TextNote note;
  
  TextNoteScreen(this.note);

  @override
  State<TextNoteScreen> createState() => _TextNoteScreenState();
}

class _TextNoteScreenState extends State<TextNoteScreen> {
  Timer? _autoSaveTimer;
  var titleController = TextEditingController();
  late QuillController bodyController;
  String old_title = "";
  bool changed = false;
  String? _lastSaved;
  final _currentTime = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());
  double font_size = 16;
  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title,);
    bodyController = QuillController(
      document: Document.fromDelta(markdownToDelta(widget.note.body)),
      selection: const TextSelection.collapsed(offset: 0),
    );
    titleController.addListener(_markChanged);
    bodyController.addListener(_markChanged);
    old_title = widget.note.title;
    _autoSaveTimer = Timer.periodic( const Duration(minutes: 1), (_) => save(),);

  }

  void _markChanged() {
    if (!changed) {
      setState(() {
        changed = true;
      });
    }
  }

  void onFontSizeChanged(double size) {
    setState(() {
      font_size = size;
    });
  }

  Future<void> save() async {
    if (!changed) {
      debugPrint("Save skipped: no changes");
      return;
    }
    debugPrint("Saving...");

    String newTitle = titleController.text.trim();
    if (newTitle.isEmpty) {
      // If the note already has a title (e.g. from a previous save), keep it.
      // Otherwise, generate a timestamped title.
      if (widget.note.title.isEmpty) {
        newTitle = DateFormat('MMM d, yyyy - h:mm:ss a').format(DateTime.now());
      } else {
        newTitle = widget.note.title;
      }
    }

    widget.note.title = newTitle;
    widget.note.body = jsonEncode(bodyController.document.toDelta().toJson());

    await widget.note.save(old_title);
    if (!mounted) return;

    setState(() {
      changed = false;
      _lastSaved = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());
    });
    old_title = widget.note.title;
    debugPrint("Auto-saved at $_lastSaved");
  }

  Future<String> getDirectory() async {
    var dir = await getApplicationDocumentsDirectory(); return dir.path;
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (changed){
          await save();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 25,
              right: 25,
            ),
            child: Column(
              children: [
                note_top(context, changed, save, titleController,
                    bodyController, font_size,
                    onFontSizeChanged),

                const SizedBox(height: 10),
                Expanded( child: note_body(context, bodyController,font_size,)),
                note_bottom(_currentTime, bodyController),
              ],
            ),
          ),
        ),
      )
    );
  }
}