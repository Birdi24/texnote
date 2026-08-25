import 'package:flutter/material.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/CanvasView.dart';
import '../../app_style.dart';
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
  final GlobalKey<BottomCanvasState> _bottomCanvasKey = GlobalKey<BottomCanvasState>();
  final GlobalKey<TopCanvasState> _topCanvasKey = GlobalKey<TopCanvasState>();

  final List<Stroke> bottomlayer = [];
  bool changed = false;
  String old_title = "";

  @override
  void initState() {
    super.initState();
    debugPrint("Handwritten note path: ${widget.note.path}");
    old_title = widget.note.title;
    bottomlayer.addAll(widget.note.strokes);
  }

  void _markChanged() {
    if (!changed) {
      setState(() {
        changed = true;
      });
    }
  }

  Future<void> save() async {
    if (!changed) return;
    
    final topStrokes = _topCanvasKey.currentState?.getStrokes() ?? [];
    widget.note.strokes = [...bottomlayer, ...topStrokes];
    
    await widget.note.save(old_title);
    
    if (mounted) {
      setState(() {
        changed = false;
      });
    }
    old_title = widget.note.title;
  }

  void _commitToBottom(List<Stroke> strokes) {
    setState(() {
      bottomlayer.addAll(strokes);
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
  
          body: LayoutBuilder(builder: (context, scaffoldConstraints) => SafeArea(
            child: LayoutBuilder(builder: (context, safeAreaConstraints) {
            return CanvasView(
                bottomLayerStrokes: bottomlayer,
                onCommit: _commitToBottom,
                bottomCanvasKey: _bottomCanvasKey,
                topCanvasKey: _topCanvasKey,
                onSave: save,
                changed: changed,
                onChanged: _markChanged,
            );
            },
          ),
        ),
        ),
      ),
    );
  }
}

