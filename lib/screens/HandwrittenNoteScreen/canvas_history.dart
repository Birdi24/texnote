import 'package:flutter/foundation.dart';
import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';

/// Represents a single point in history using structural sharing.
class CanvasHistoryState {
  final List<Stroke> bottomLayer;
  final List<Stroke> topLayer;
  final int numPages;
  final List<ImageData> images;
  final List<ImageData> topImages;
  final List<TextData> texts;
  final List<TextData> topTexts;
  final List<String?> pageBackgrounds;

  CanvasHistoryState({
    required this.bottomLayer,
    required this.topLayer,
    required this.numPages,
    required this.images,
    required this.topImages,
    required this.texts,
    required this.topTexts,
    required this.pageBackgrounds,
  });

  factory CanvasHistoryState.capture(
    List<Stroke> bottom,
    List<Stroke> top,
    int numPages,
    List<ImageData> images,
    List<String?> backgrounds, {
    List<ImageData> topImages = const [],
    List<TextData> texts = const [],
    List<TextData> topTexts = const [],
  }) {
    return CanvasHistoryState(
      bottomLayer: List<Stroke>.from(bottom),
      topLayer: List<Stroke>.from(top),
      numPages: numPages,
      images: images.map((i) => i.copy()).toList(),
      topImages: topImages.map((i) => i.copy()).toList(),
      texts: texts.map((t) => t.copy()).toList(),
      topTexts: topTexts.map((t) => t.copy()).toList(),
      pageBackgrounds: List<String?>.from(backgrounds),
    );
  }

  bool equals(CanvasHistoryState other) {
    if (numPages != other.numPages) return false;
    if (bottomLayer.length != other.bottomLayer.length) return false;
    if (topLayer.length != other.topLayer.length) return false;
    if (images.length != other.images.length) return false;
    if (topImages.length != other.topImages.length) return false;
    if (texts.length != other.texts.length) return false;
    if (topTexts.length != other.topTexts.length) return false;
    if (pageBackgrounds.length != other.pageBackgrounds.length) return false;

    // Check identity of items in layers (should work if we always copy on modify)
    for (int i = 0; i < bottomLayer.length; i++) {
      if (!identical(bottomLayer[i], other.bottomLayer[i])) return false;
    }
    for (int i = 0; i < topLayer.length; i++) {
      if (!identical(topLayer[i], other.topLayer[i])) return false;
    }
    
    // Images value check
    for (int i = 0; i < images.length; i++) {
      if (images[i].position != other.images[i].position ||
          images[i].width != other.images[i].width ||
          images[i].height != other.images[i].height ||
          images[i].imagePath != other.images[i].imagePath) {
        return false;
      }
    }
    for (int i = 0; i < topImages.length; i++) {
      if (topImages[i].position != other.topImages[i].position ||
          topImages[i].width != other.topImages[i].width ||
          topImages[i].height != other.topImages[i].height ||
          topImages[i].imagePath != other.topImages[i].imagePath) {
        return false;
      }
    }
    
    // Texts value check
    for (int i = 0; i < texts.length; i++) {
      if (texts[i].text != other.texts[i].text || 
          texts[i].position != other.texts[i].position ||
          texts[i].fontSize != other.texts[i].fontSize ||
          texts[i].color != other.texts[i].color) {
        return false;
      }
    }
    for (int i = 0; i < topTexts.length; i++) {
      if (topTexts[i].text != other.topTexts[i].text ||
          topTexts[i].position != other.topTexts[i].position ||
          topTexts[i].fontSize != other.topTexts[i].fontSize ||
          topTexts[i].color != other.topTexts[i].color) {
        return false;
      }
    }

    // Backgrounds
    for (int i = 0; i < pageBackgrounds.length; i++) {
      if (pageBackgrounds[i] != other.pageBackgrounds[i]) return false;
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
    List<Stroke> bottom,
    List<Stroke> top,
    int numPages,
    List<ImageData> images,
    List<String?> backgrounds, {
    List<ImageData> topImages = const [],
    List<TextData> texts = const [],
    List<TextData> topTexts = const [],
  }) {
    final newState = CanvasHistoryState.capture(
      bottom,
      top,
      numPages,
      images,
      backgrounds,
      topImages: topImages,
      texts: texts,
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
