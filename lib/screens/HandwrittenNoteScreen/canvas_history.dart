import 'package:flutter/foundation.dart';
import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';
import '../../models/HandwrittenNote.dart';

/// Represents a single point in history using structural sharing.
class CanvasHistoryState {
  final List<NotePage> pages;
  final List<Stroke> topLayer;
  final List<ImageData> topImages;
  final List<TextData> topTexts;

  CanvasHistoryState({
    required this.pages,
    required this.topLayer,
    required this.topImages,
    required this.topTexts,
  });

  factory CanvasHistoryState.capture(
    List<NotePage> pages,
    List<Stroke> top, {
    List<ImageData> topImages = const [],
    List<TextData> topTexts = const [],
  }) {
    return CanvasHistoryState(
      pages: pages.map((page) => NotePage(
        strokes: page.strokes.map((s) => s.copy()).toList(),
        images: page.images.map((i) => i.copy()).toList(),
        texts: page.texts.map((t) => t.copy()).toList(),
        background: page.background,
        source: PageSource(type: page.source.type, originalIndex: page.source.originalIndex),
      )).toList(),
      topLayer: top.map((s) => s.copy()).toList(),
      topImages: topImages.map((i) => i.copy()).toList(),
      topTexts: topTexts.map((t) => t.copy()).toList(),
    );
  }

  bool equals(CanvasHistoryState other) {
    if (pages.length != other.pages.length) return false;
    if (topLayer.length != other.topLayer.length) return false;
    if (topImages.length != other.topImages.length) return false;
    if (topTexts.length != other.topTexts.length) return false;

    // Check identity or value of pages (deep check)
    for (int i = 0; i < pages.length; i++) {
      final p1 = pages[i];
      final p2 = other.pages[i];
      if (p1.strokes.length != p2.strokes.length) return false;
      if (p1.images.length != p2.images.length) return false;
      if (p1.texts.length != p2.texts.length) return false;
      if (p1.background != p2.background) return false;
      if (p1.source.type != p2.source.type || p1.source.originalIndex != p2.source.originalIndex) return false;
    }
    return true; 
  }
}

class CanvasHistoryManager {
  final List<CanvasHistoryState> _history = [];
  int _historyIndex = -1;
  final int maxHistory;

  CanvasHistoryManager({this.maxHistory = 50});

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void record(
    List<NotePage> pages,
    List<Stroke> top, {
    List<ImageData> topImages = const [],
    List<TextData> topTexts = const [],
  }) {
    final newState = CanvasHistoryState.capture(
      pages,
      top,
      topImages: topImages,
      topTexts: topTexts,
    );

    if (_historyIndex >= 0 && _history[_historyIndex].equals(newState)) {
      return;
    }

    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(newState);
    _historyIndex++;

    if (_history.length > maxHistory) {
      _history.removeAt(0);
      _historyIndex--;
    }
    debugPrint("History recorded. Index: $_historyIndex, Length: ${_history.length}");
  }

  CanvasHistoryState? undo() {
    if (canUndo) {
      _historyIndex--;
      debugPrint("Undo performed. Index: $_historyIndex");
      return _history[_historyIndex];
    }
    return null;
  }

  CanvasHistoryState? redo() {
    if (canRedo) {
      _historyIndex++;
      debugPrint("Redo performed. Index: $_historyIndex");
      return _history[_historyIndex];
    }
    return null;
  }

  CanvasHistoryState? get currentState => _historyIndex >= 0 ? _history[_historyIndex] : null;
  
  void clear() {
    _history.clear();
    _historyIndex = -1;
  }
}
