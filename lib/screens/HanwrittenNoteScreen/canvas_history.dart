import '../../models/HandwrittenNote.dart' show Stroke, ImageData;

class CanvasHistoryState {
  final List<Stroke> bottomLayer;
  final List<Stroke> topLayer;
  final int numPages;
  final List<ImageData> images;
  final List<ImageData> topImages;

  CanvasHistoryState({
    required this.bottomLayer,
    required this.topLayer,
    required this.numPages,
    required this.images,
    this.topImages = const [],
  });

  factory CanvasHistoryState.capture(List<Stroke> bottom, List<Stroke> top, int numPages, List<ImageData> images, {List<ImageData> topImages = const []}) {
    return CanvasHistoryState(
      bottomLayer: bottom.map((s) => s.copy()).toList(),
      topLayer: top.map((s) => s.copy()).toList(),
      numPages: numPages,
      images: images.map((i) => i.copy()).toList(),
      topImages: topImages.map((i) => i.copy()).toList(),
    );
  }

  bool equals(CanvasHistoryState other) {
    if (numPages != other.numPages) return false;
    if (bottomLayer.length != other.bottomLayer.length) return false;
    if (topLayer.length != other.topLayer.length) return false;
    if (images.length != other.images.length) return false;
    if (topImages.length != other.topImages.length) return false;

    // Quick check for last stroke/image changes
    if (bottomLayer.isNotEmpty && other.bottomLayer.isNotEmpty) {
      if (bottomLayer.last.points.length != other.bottomLayer.last.points.length) return false;
    }
    
    if (images.isNotEmpty && other.images.isNotEmpty) {
      if (images.last.position != other.images.last.position) return false;
      if (images.last.width != other.images.last.width) return false;
    }

    if (topImages.isNotEmpty && other.topImages.isNotEmpty) {
      if (topImages.last.position != other.topImages.last.position) return false;
    }

    // If counts are the same and last items are same (positionally), assume same for performance
    // or we can do full deep check.
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

  void record(List<Stroke> bottom, List<Stroke> top, int numPages, List<ImageData> images, {List<ImageData> topImages = const []}) {
    final newState = CanvasHistoryState.capture(bottom, top, numPages, images, topImages: topImages);

    if (_historyIndex >= 0) {
      final lastState = _history[_historyIndex];
      if (lastState.equals(newState)) {
        return;
      }
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
  }

  CanvasHistoryState? undo() {
    if (canUndo) {
      _historyIndex--;
      return _history[_historyIndex];
    }
    return null;
  }

  CanvasHistoryState? redo() {
    if (canRedo) {
      _historyIndex++;
      return _history[_historyIndex];
    }
    return null;
  }

  CanvasHistoryState? get currentState => _historyIndex >= 0 ? _history[_historyIndex] : null;
}
