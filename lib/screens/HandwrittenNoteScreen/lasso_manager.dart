import 'package:flutter/material.dart';

import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';

enum LassoMode { lassoing, moving, resizing, none }
enum ResizeHandle { topLeft, topRight, bottomLeft, bottomRight, none }

class LassoManager {
  List<Stroke> selectedStrokes = [];
  List<ImageData> selectedImages = [];
  List<TextData> selectedTexts = [];
  List<Offset> lassoPoints = [];
  Path? lassoPath;
  Rect? selectionRect;
  LassoMode currentMode = LassoMode.none;
  ResizeHandle activeHandle = ResizeHandle.none;

  void updateSelectionRect() {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty && selectedTexts.isEmpty) {
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

    for (final txt in selectedTexts) {
      final txtBounds = txt.getBounds();
      bounds = bounds == null ? txtBounds : bounds.expandToInclude(txtBounds);
    }

    selectionRect = bounds?.inflate(5.0);
  }

  void startLasso(Offset position, List<Stroke> topLayerStrokes, List<ImageData> topLayerImages, List<TextData> topLayerTexts) {
    if (selectedStrokes.isNotEmpty || selectedImages.isNotEmpty || selectedTexts.isNotEmpty) {
      topLayerStrokes.addAll(selectedStrokes);
      topLayerImages.addAll(selectedImages);
      topLayerTexts.addAll(selectedTexts);
      selectedStrokes = [];
      selectedImages = [];
      selectedTexts = [];
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
    required List<TextData> topLayerTexts,
    required List<Stroke> Function(Path) onSelectStrokesFromBottom,
    required List<ImageData> Function(Path) onSelectImagesFromBottom,
    required List<TextData> Function(Path) onSelectTextsFromBottom,
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

    // Select Texts
    final List<TextData> newlySelectedTexts = [];
    final List<TextData> remainingTopTexts = [];
    for (final txt in topLayerTexts) {
      final bounds = txt.getBounds();
      if (selectionPath.contains(bounds.center) || 
          selectionPath.contains(bounds.topLeft) || 
          selectionPath.contains(bounds.bottomRight)) {
        newlySelectedTexts.add(txt);
      } else {
        remainingTopTexts.add(txt);
      }
    }
    final textsFromBottom = onSelectTextsFromBottom(selectionPath);
    newlySelectedTexts.addAll(textsFromBottom);

    topLayerStrokes.clear();
    topLayerStrokes.addAll(remainingTopStrokes);
    selectedStrokes.addAll(newlySelectedStrokes);

    topLayerImages.clear();
    topLayerImages.addAll(remainingTopImages);
    selectedImages.addAll(newlySelectedImages);

    topLayerTexts.clear();
    topLayerTexts.addAll(remainingTopTexts);
    selectedTexts.addAll(newlySelectedTexts);

    updateSelectionRect();
    lassoPath = null;
    lassoPoints = [];

    if (newlySelectedStrokes.isNotEmpty || newlySelectedImages.isNotEmpty || newlySelectedTexts.isNotEmpty) {
      onChanged();
    }
  }

  void handleMove(Offset delta, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty && selectedTexts.isEmpty) return;
    for (int i = 0; i < selectedStrokes.length; i++) {
      selectedStrokes[i] = selectedStrokes[i].translate(delta);
    }
    for (int i = 0; i < selectedImages.length; i++) {
      selectedImages[i] = selectedImages[i].translate(delta);
    }
    for (int i = 0; i < selectedTexts.length; i++) {
      selectedTexts[i] = selectedTexts[i].translate(delta);
    }
    updateSelectionRect();
    onChanged();
  }

  void handleResize(Offset position, Offset delta, VoidCallback onChanged) {
    if ((selectedStrokes.isEmpty && selectedImages.isEmpty && selectedTexts.isEmpty) || selectionRect == null) return;

    final rect = selectionRect!;
    Offset fixedPoint;
    Offset oldPoint;

    switch (activeHandle) {
      case ResizeHandle.topLeft:
        fixedPoint = rect.bottomRight;
        oldPoint = rect.topLeft;
        break;
      case ResizeHandle.topRight:
        fixedPoint = rect.bottomLeft;
        oldPoint = rect.topRight;
        break;
      case ResizeHandle.bottomLeft:
        fixedPoint = rect.topRight;
        oldPoint = rect.bottomLeft;
        break;
      case ResizeHandle.bottomRight:
        fixedPoint = rect.topLeft;
        oldPoint = rect.bottomRight;
        break;
      case ResizeHandle.none:
        final center = rect.center;
        final oldDist = (position - delta - center).distance;
        final newDist = (position - center).distance;
        if (oldDist > 0) {
          final scaleFactor = newDist / oldDist;
          for (int i = 0; i < selectedStrokes.length; i++) {
            selectedStrokes[i] = selectedStrokes[i].scale(scaleFactor, center);
          }
          for (int i = 0; i < selectedImages.length; i++) {
            selectedImages[i] = selectedImages[i].scaleFromOrigin(scaleFactor, center);
          }
          for (int i = 0; i < selectedTexts.length; i++) {
            selectedTexts[i] = selectedTexts[i].scaleFromOrigin(scaleFactor, center);
          }
          updateSelectionRect();
          onChanged();
        }
        return;
    }

    final oldWidth = (oldPoint.dx - fixedPoint.dx).abs();
    final oldHeight = (oldPoint.dy - fixedPoint.dy).abs();
    final newWidth = (position.dx - fixedPoint.dx).abs();
    final newHeight = (position.dy - fixedPoint.dy).abs();

    if (oldWidth > 0 && oldHeight > 0) {
      final scaleX = newWidth / oldWidth;
      final scaleY = newHeight / oldHeight;

      for (int i = 0; i < selectedStrokes.length; i++) {
        final avgScale = (scaleX + scaleY) / 2;
        selectedStrokes[i] = selectedStrokes[i].scale(avgScale, fixedPoint);
      }

      for (int i = 0; i < selectedImages.length; i++) {
        final img = selectedImages[i];
        final newPos = fixedPoint + (img.position - fixedPoint).scale(scaleX, scaleY);
        selectedImages[i] = ImageData(
          position: newPos,
          imagePath: img.imagePath,
          scale: img.scale,
          width: img.width * scaleX,
          height: img.height * scaleY,
        );
      }

      for (int i = 0; i < selectedTexts.length; i++) {
        final txt = selectedTexts[i];
        final newPos = fixedPoint + (txt.position - fixedPoint).scale(scaleX, scaleY);
        selectedTexts[i] = TextData(
          position: newPos,
          text: txt.text,
          width: txt.width * scaleX,
          height: txt.height * scaleY,
          fontSize: txt.fontSize, 
          color: txt.color,
        );
      }
      updateSelectionRect();
      onChanged();
    }
  }

  void duplicateSelectedItems(List<Stroke> topLayerStrokes, List<ImageData> topLayerImages, List<TextData> topLayerTexts, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty && selectedTexts.isEmpty) return;

    final List<Stroke> strokeCopies = selectedStrokes.map((s) => s.copy().translate(const Offset(20, 20))).toList();
    final List<ImageData> imageCopies = selectedImages.map((i) => i.copy().translate(const Offset(20, 20))).toList();
    final List<TextData> textCopies = selectedTexts.map((t) => t.copy().translate(const Offset(20, 20))).toList();
    
    topLayerStrokes.addAll(selectedStrokes);
    selectedStrokes = strokeCopies;

    topLayerImages.addAll(selectedImages);
    selectedImages = imageCopies;

    topLayerTexts.addAll(selectedTexts);
    selectedTexts = textCopies;

    updateSelectionRect();
    onChanged();
  }

  void clearSelection(List<Stroke> topLayerStrokes, List<ImageData> topLayerImages, List<TextData> topLayerTexts, VoidCallback onChanged) {
    if (selectedStrokes.isEmpty && selectedImages.isEmpty && selectedTexts.isEmpty) return;
    topLayerStrokes.addAll(selectedStrokes);
    topLayerImages.addAll(selectedImages);
    topLayerTexts.addAll(selectedTexts);
    selectedStrokes = [];
    selectedImages = [];
    selectedTexts = [];
    selectionRect = null;
    onChanged();
  }

  void removeSelectedItems(bool Function(Stroke) strokePredicate, bool Function(ImageData) imagePredicate, bool Function(TextData) textPredicate) {
    selectedStrokes.removeWhere(strokePredicate);
    selectedImages.removeWhere(imagePredicate);
    selectedTexts.removeWhere(textPredicate);
    updateSelectionRect();
  }
}
