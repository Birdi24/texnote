import 'package:flutter/material.dart';
import '../../models/HandwrittenNote.dart';

enum LassoMode { lassoing, moving, resizing, none }

class LassoManager {
  List<Stroke> selectedStrokes = [];
  List<Offset> lassoPoints = [];
  Path? lassoPath;
  Rect? selectionRect;
  LassoMode currentMode = LassoMode.none;

  void updateSelectionRect() {
    if (selectedStrokes.isEmpty) {
      selectionRect = null;
      return;
    }

    Rect bounds = selectedStrokes.first.getBounds();
    for (final stroke in selectedStrokes.skip(1)) {
      bounds = bounds.expandToInclude(stroke.getBounds());
    }
    selectionRect = bounds.inflate(5.0);
  }

  void startLasso(Offset position, List<Stroke> topLayer) {
    if (selectedStrokes.isNotEmpty) {
      topLayer.addAll(selectedStrokes);
      selectedStrokes = [];
      selectionRect = null;
    }
    lassoPoints = [position];
    lassoPath = Path()..moveTo(position.dx, position.dy);
    currentMode = LassoMode.lassoing;
  }

  void updateLasso(Offset position) {
    lassoPoints.add(position);
    lassoPath!.lineTo(position.dx, position.dy);
  }

  void selectStrokesInLasso({
    required List<Stroke> topLayer,
    required List<Stroke> Function(Path) onSelectFromBottom,
    required VoidCallback onChanged,
  }) {
    if (lassoPath == null) return;

    final selectionPath = Path.from(lassoPath!)..close();

    final List<Stroke> newlySelected = [];
    final List<Stroke> remainingTop = [];

    for (final stroke in topLayer) {
      bool isInside = stroke.points.any((p) => selectionPath.contains(p));
      if (isInside) {
        newlySelected.add(stroke);
      } else {
        remainingTop.add(stroke);
      }
    }

    final fromBottom = onSelectFromBottom(selectionPath);
    newlySelected.addAll(fromBottom);

    topLayer.clear();
    topLayer.addAll(remainingTop);
    selectedStrokes.addAll(newlySelected);
    updateSelectionRect();
    lassoPath = null;
    lassoPoints = [];

    if (newlySelected.isNotEmpty) {
      onChanged();
    }
  }

  void handleMove(Offset delta, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty) return;
    for (final stroke in selectedStrokes) {
      stroke.translate(delta);
    }
    updateSelectionRect();
    onChanged();
  }

  void handleResize(Offset position, Offset delta, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty || selectionRect == null) return;

    final center = selectionRect!.center;
    final oldDist = (position - delta - center).distance;
    final newDist = (position - center).distance;

    if (oldDist > 0) {
      final scaleFactor = newDist / oldDist;
      for (final stroke in selectedStrokes) {
        stroke.scale(scaleFactor, center);
      }
      updateSelectionRect();
      onChanged();
    }
  }

  void duplicateSelectedStrokes(List<Stroke> topLayer, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty) return;

    final List<Stroke> copies = selectedStrokes.map((s) => s.copy()).toList();
    const Offset offset = Offset(20, 20);
    for (final stroke in copies) {
      stroke.translate(offset);
    }

    topLayer.addAll(selectedStrokes);
    selectedStrokes = copies;
    updateSelectionRect();
    onChanged();
  }

  void clearSelection(List<Stroke> topLayer, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty) return;
    topLayer.addAll(selectedStrokes);
    selectedStrokes = [];
    selectionRect = null;
    onChanged();
  }

  void removeSelectedStrokes(bool Function(Stroke) predicate) {
    selectedStrokes.removeWhere(predicate);
    updateSelectionRect();
  }
}
