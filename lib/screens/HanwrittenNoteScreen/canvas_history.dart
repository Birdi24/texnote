import '../../models/HandwrittenNote.dart' show Stroke;

class CanvasHistoryState {
  final List<Stroke> bottomLayer;
  final List<Stroke> topLayer;
  final int numPages;

  CanvasHistoryState({
    required this.bottomLayer,
    required this.topLayer,
    required this.numPages,
  });

  factory CanvasHistoryState.capture(List<Stroke> bottom, List<Stroke> top, int numPages) {
    return CanvasHistoryState(
      bottomLayer: List.from(bottom),
      topLayer: List.from(top),
      numPages: numPages,
    );
  }

  bool equals(CanvasHistoryState other) {
    if (numPages != other.numPages) return false;
    if (bottomLayer.length != other.bottomLayer.length) return false;
    if (topLayer.length != other.topLayer.length) return false;

    for (int i = 0; i < bottomLayer.length; i++) {
      if (bottomLayer[i] != other.bottomLayer[i]) return false;
    }
    for (int i = 0; i < topLayer.length; i++) {
      if (topLayer[i] != other.topLayer[i]) return false;
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

  void record(List<Stroke> bottom, List<Stroke> top, int numPages) {
    final newState = CanvasHistoryState.capture(bottom, top, numPages);

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
