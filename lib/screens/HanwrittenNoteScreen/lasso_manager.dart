import 'package:flutter/material.dart';
import '../../models/HandwrittenNote.dart';

enum LassoMode { lassoing, moving, resizing, none }

class LassoManager {
  List<Stroke> selectedStrokes = [];
  List<ImageData> selectedImages = [];
  List<Offset> lassoPoints = [];
  Path? lassoPath;
  Rect? selectionRect;
  LassoMode currentMode = LassoMode.none;

  void updateSelectionRect() {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty) {
      selectionRect = null;
      return;
    }

    Rect? bounds;
    
    for (final stroke in selectedStrokes) {
      final strokeBounds = stroke.getBounds();
      bounds = bounds == null ? strokeBounds : bounds.expandToInclude(strokeBounds);
    }

    for (final img in selectedImages) {
      final imgBounds = img.getBounds();
      bounds = bounds == null ? imgBounds : bounds.expandToInclude(imgBounds);
    }

    selectionRect = bounds?.inflate(5.0);
  }

  void startLasso(Offset position, List<Stroke> topLayerStrokes, List<ImageData> topLayerImages) {
    if (selectedStrokes.isNotEmpty || selectedImages.isNotEmpty) {
      topLayerStrokes.addAll(selectedStrokes);
      topLayerImages.addAll(selectedImages);
      selectedStrokes = [];
      selectedImages = [];
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

  void selectItemsInLasso({
    required List<Stroke> topLayerStrokes,
    required List<ImageData> topLayerImages,
    required List<Stroke> Function(Path) onSelectStrokesFromBottom,
    required List<ImageData> Function(Path) onSelectImagesFromBottom,
    required VoidCallback onChanged,
  }) {
    if (lassoPath == null) return;

    final selectionPath = Path.from(lassoPath!)..close();

    // Select Strokes
    final List<Stroke> newlySelectedStrokes = [];
    final List<Stroke> remainingTopStrokes = [];
    for (final stroke in topLayerStrokes) {
      bool isInside = stroke.points.any((p) => selectionPath.contains(p));
      if (isInside) {
        newlySelectedStrokes.add(stroke);
      } else {
        remainingTopStrokes.add(stroke);
      }
    }
    final strokesFromBottom = onSelectStrokesFromBottom(selectionPath);
    newlySelectedStrokes.addAll(strokesFromBottom);

    // Select Images
    final List<ImageData> newlySelectedImages = [];
    final List<ImageData> remainingTopImages = [];
    for (final img in topLayerImages) {
      // Check if any corner is inside, or center
      final bounds = img.getBounds();
      if (selectionPath.contains(bounds.center) || 
          selectionPath.contains(bounds.topLeft) || 
          selectionPath.contains(bounds.bottomRight)) {
        newlySelectedImages.add(img);
      } else {
        remainingTopImages.add(img);
      }
    }
    final imagesFromBottom = onSelectImagesFromBottom(selectionPath);
    newlySelectedImages.addAll(imagesFromBottom);

    topLayerStrokes.clear();
    topLayerStrokes.addAll(remainingTopStrokes);
    selectedStrokes.addAll(newlySelectedStrokes);

    topLayerImages.clear();
    topLayerImages.addAll(remainingTopImages);
    selectedImages.addAll(newlySelectedImages);

    updateSelectionRect();
    lassoPath = null;
    lassoPoints = [];

    if (newlySelectedStrokes.isNotEmpty || newlySelectedImages.isNotEmpty) {
      onChanged();
    }
  }

  void handleMove(Offset delta, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty) return;
    for (final stroke in selectedStrokes) {
      stroke.translate(delta);
    }
    for (final img in selectedImages) {
      img.translate(delta);
    }
    updateSelectionRect();
    onChanged();
  }

  void handleResize(Offset position, Offset delta, VoidCallback onChanged) {
    if ((selectedStrokes.isEmpty && selectedImages.isEmpty) || selectionRect == null) return;

    final center = selectionRect!.center;
    final oldDist = (position - delta - center).distance;
    final newDist = (position - center).distance;

    if (oldDist > 0) {
      final scaleFactor = newDist / oldDist;
      for (final stroke in selectedStrokes) {
        stroke.scale(scaleFactor, center);
      }
      for (final img in selectedImages) {
        img.scaleFromOrigin(scaleFactor, center);
      }
      updateSelectionRect();
      onChanged();
    }
  }

  void duplicateSelectedItems(List<Stroke> topLayerStrokes, List<ImageData> topLayerImages, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty) return;

    final List<Stroke> strokeCopies = selectedStrokes.map((s) => s.copy()).toList();
    final List<ImageData> imageCopies = selectedImages.map((i) => i.copy()).toList();
    
    const Offset offset = Offset(20, 20);
    for (final stroke in strokeCopies) {
      stroke.translate(offset);
    }
    for (final img in imageCopies) {
      img.translate(offset);
    }

    topLayerStrokes.addAll(selectedStrokes);
    selectedStrokes = strokeCopies;

    topLayerImages.addAll(selectedImages);
    selectedImages = imageCopies;

    updateSelectionRect();
    onChanged();
  }

  void clearSelection(List<Stroke> topLayerStrokes, List<ImageData> topLayerImages, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty) return;
    topLayerStrokes.addAll(selectedStrokes);
    topLayerImages.addAll(selectedImages);
    selectedStrokes = [];
    selectedImages = [];
    selectionRect = null;
    onChanged();
  }

  void removeSelectedItems(bool Function(Stroke) strokePredicate, bool Function(ImageData) imagePredicate) {
    selectedStrokes.removeWhere(strokePredicate);
    selectedImages.removeWhere(imagePredicate);
    updateSelectionRect();
  }
}
