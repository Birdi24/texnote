import 'package:flutter/material.dart';
import 'package:texnote/screens/HanwrittenNoteScreen/CanvasView.dart';

import '../../app_style.dart';
import '../../models/HandwrittenNote.dart';
import 'DualCanvas.dart';

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

  void _commitToBottom(List<Stroke> strokes) {
    setState(() {
      bottomlayer.addAll(strokes);
    });
    _bottomCanvasKey.currentState?.updateStrokes(List<Stroke>.from(bottomlayer));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BG.withAlpha(252),

        body: LayoutBuilder(builder: (context, scaffoldConstraints) => SafeArea(
          child: LayoutBuilder(builder: (context, safeAreaConstraints) {
          return CanvasView(bottomLayerStrokes: bottomlayer, onCommit: _commitToBottom, bottomCanvasKey: _bottomCanvasKey, topCanvasKey: _topCanvasKey);
          },
        ),
      ),
      ),
    );
  }
}

