import 'dart:async';
import 'dart:convert';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/TextNote.dart';
import 'note_body.dart';
import 'note_botton.dart';
import 'note_top.dart';

/// Stateful because the text changes and the theme changes
class TextNoteScreen extends StatefulWidget {
  TextNote note;
  TextNoteScreen(this.note, {super.key});
  @override
  State<TextNoteScreen> createState() => _TextNoteScreenState();
}

class _TextNoteScreenState extends State<TextNoteScreen> {
  // Timer for auto-saving the note
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  // Controller for the title of the note
  var titleController = TextEditingController();

  // Rich text controller for the body of the note
  late QuillController bodyController;

  // old title of the note, if title was changed, it deletes the previous note
  String old_title = "";

  // Whether the note has been changed, if so, it will be saved
  bool changed = false;

  String? _lastSaved;
  final _currentTime = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());

  double font_size = 16;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);

    Delta delta;
    if (widget.note.body.isNotEmpty && widget.note.body != "\n") {
      delta = Delta.fromJson(jsonDecode(widget.note.body));
    } else {
      delta = Delta()..insert("\n");
    }

    bodyController = QuillController(
      document: Document.fromDelta(delta),
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
      canPop: !changed || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (changed && !_isSaving) {
          setState(() => _isSaving = true);
          debugPrint("TextNoteScreen: onPopInvoked - saving before pop");
          await save();
          if (mounted) {
            debugPrint("TextNoteScreen: save completed, popping");
            Navigator.of(context).pop();
          }
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