import '../../models/HandwrittenNote.dart' show Stroke, ImageData;

/// Represents a single point in history using structural sharing.
/// Because Stroke and ImageData are now treated as immutable (modifying them returns a new instance),
/// we can safely store references to them without deep-copying their internal point lists.
class CanvasHistoryState {
  final List<Stroke> bottomLayer;
  final List<Stroke> topLayer;
  final int numPages;
  final List<ImageData> images;
  final List<ImageData> topImages;
  final List<String?> pageBackgrounds;

  CanvasHistoryState({
    required this.bottomLayer,
    required this.topLayer,
    required this.numPages,
    required this.images,
    required this.topImages,
    required this.pageBackgrounds,
  });

  /// Captures the current state using structural sharing.
  /// This is O(N) where N is the number of items, but it only copies references (pointers),
  /// making it extremely fast even for 1600+ pages.
  factory CanvasHistoryState.capture(
    List<Stroke> bottom,
    List<Stroke> top,
    int numPages,
    List<ImageData> images,
    List<String?> backgrounds, {
    List<ImageData> topImages = const [],
  }) {
    return CanvasHistoryState(
      bottomLayer: List<Stroke>.from(bottom),
      topLayer: List<Stroke>.from(top),
      numPages: numPages,
      images: List<ImageData>.from(images),
      topImages: List<ImageData>.from(topImages),
      pageBackgrounds: List<String?>.from(backgrounds),
    );
  }

  /// Extremely fast comparison using identity checks and lengths.
  bool equals(CanvasHistoryState other) {
    if (numPages != other.numPages) return false;
    if (bottomLayer.length != other.bottomLayer.length) return false;
    if (topLayer.length != other.topLayer.length) return false;
    if (images.length != other.images.length) return false;
    if (topImages.length != other.topImages.length) return false;
    if (pageBackgrounds.length != other.pageBackgrounds.length) return false;

    // Check identity of last items (most likely to change)
    if (bottomLayer.isNotEmpty && !identical(bottomLayer.last, other.bottomLayer.last)) return false;
    if (topLayer.isNotEmpty && !identical(topLayer.last, other.topLayer.last)) return false;
    if (images.isNotEmpty && !identical(images.last, other.images.last)) return false;
    
    // Background check
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

  /// Records a new state. Optimization: only captures if the state actually changed.
  void record(
    List<Stroke> bottom,
    List<Stroke> top,
    int numPages,
    List<ImageData> images,
    List<String?> backgrounds, {
    List<ImageData> topImages = const [],
  }) {
    // 1. Shallow comparison with current state before capturing
    if (_historyIndex >= 0) {
      final current = _history[_historyIndex];
      // Fast check: if lengths are same and last items are identical (by reference), skip capture.
      if (numPages == current.numPages &&
          bottom.length == current.bottomLayer.length &&
          top.length == current.topLayer.length &&
          images.length == current.images.length &&
          topImages.length == current.topImages.length &&
          (bottom.isEmpty || identical(bottom.last, current.bottomLayer.last)) &&
          (top.isEmpty || identical(top.last, current.topLayer.last))) {
        return;
      }
    }

    final newState = CanvasHistoryState.capture(
      bottom,
      top,
      numPages,
      images,
      backgrounds,
      topImages: topImages,
    );

    // If we've undone things and then draw something new, clear the "future" redo path.
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
  
  void clear() {
    _history.clear();
    _historyIndex = -1;
  }
}
