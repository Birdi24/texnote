import 'dart:async';
import 'dart:convert';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import '../../models/TextNote.dart';
import 'note_body.dart';
import 'note_botton.dart';
import 'note_top.dart';

/// Stateful because the text changes and the theme changes
class TextNoteScreen extends StatefulWidget {
  final TextNote note;
  const TextNoteScreen(this.note, {super.key});
  @override
  State<TextNoteScreen> createState() => _TextNoteScreenState();
}

class _TextNoteScreenState extends State<TextNoteScreen> with WidgetsBindingObserver {
  // Timer for auto-saving the note
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _allowPop = false;

  // Controller for the title of the note
  var titleController = TextEditingController();

  // Rich text controller for the body of the note
  late QuillController bodyController;

  // old title of the note, if title was changed, it deletes the previous note
  String old_title = "";

  // Whether the note has been changed, if so, it will be saved
  bool changed = false;

  final _currentTime = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());

  double font_size = 16;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    titleController = TextEditingController(text: widget.note.title);
    old_title = widget.note.title;

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

    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) => save());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    titleController.dispose();
    bodyController.dispose();
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
    if (!changed) {
      setState(() {
        changed = true;
      });
    }
  }

  void onFontSizeChanged(double newSize) {
    setState(() {
      font_size = newSize;
    });
  }

  Future<void> save() async {
    if (!changed) return;
    final jsonString = jsonEncode(bodyController.document.toDelta().toJson());
    widget.note.body = jsonString;
    widget.note.title = titleController.text;
    await widget.note.save(old_title);
    if (mounted) {
      setState(() {
        changed = false;
      });
    }
    old_title = titleController.text;
  }

  Future<void> _handleBack() async {
    if (_isSaving) return;
    _isSaving = true;
    try {
      if (changed) {
        await save();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("TextNoteScreen: back error: $e");
    } finally {
      _isSaving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!_isSaving) {
          _isSaving = true;
          debugPrint("TextNoteScreen: onPopInvoked - saving before pop");
          try {
            await save();
          } catch (e) {
            debugPrint("TextNoteScreen: error saving before pop: $e");
          } finally {
            _isSaving = false;
          }
          if (mounted) {
            setState(() {
              _allowPop = true;
            });
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
                note_top(
                  context,
                  changed,
                  save,
                  titleController,
                  bodyController,
                  font_size,
                  onFontSizeChanged,
                  _handleBack,
                ),

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
