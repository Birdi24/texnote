import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/note.dart';
import 'note_body.dart';
import 'note_botton.dart';
import 'note_top.dart';

class NoteScreen extends StatefulWidget {
  Note note;
  
  NoteScreen(this.note);

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  Timer? _autoSaveTimer;
  var titleController = TextEditingController();
  var bodyController = TextEditingController();
  String old_title = "";
  bool changed = false;
  bool markdown_enabled = true;
  int markdownkey = 0;
  String markdownData = "";
  String? _lastSaved;
  final _currentTime = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());
  double font_size = 12;
  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title,);
    bodyController = TextEditingController(text: widget.note.body,);
    markdownData = widget.note.body;
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

  void on_markdown_toggle_changed(){
    setState(() {
      markdown_enabled = !markdown_enabled;
      if (markdown_enabled == false) {markdownkey++;}
    });
    print(bodyController.text);
  }
  void reload_markdown(){
    setState(() {
      markdownData = bodyController.text;
      markdownkey++;
    });
  }
  Future<void> save() async {
    if (!changed && titleController.text != "") {debugPrint("Save skipped: no changes");return;}
    debugPrint("Saving...");
    widget.note.title = titleController.text;
    widget.note.body = bodyController.text;
    widget.note.title = (widget.note.title == "") ? DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now()) : widget.note.title;

    await widget.note.saveNote(_currentTime, old_title,);
    if (!mounted) return;
    setState(() {
      changed = false;_lastSaved = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());
    });
    old_title = titleController.text;
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
                    onFontSizeChanged,on_markdown_toggle_changed,reload_markdown),

                const SizedBox(height: 10),
                Expanded( child: note_body(context, bodyController,font_size, markdown_enabled,markdownkey, markdownData)),
                note_bottom(_currentTime, _lastSaved, bodyController),
              ],
            ),
          ),
        ),
      )
    );
  }
}