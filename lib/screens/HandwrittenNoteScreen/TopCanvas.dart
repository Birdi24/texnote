import 'dart:io';

import 'package:flutter/material.dart';
import 'package:birdwrite/screens/HandwrittenNoteScreen/canvas_options.dart';
import '../../app_style.dart';
import 'HandwritingPainter.dart';
import 'lasso_manager.dart';

import '../../models/ImageData.dart';
import '../../models/TextData.dart';
import '../../models/stroke.dart';

class TopCanvas extends StatefulWidget {
  final void Function(List<Stroke> strokes, List<ImageData> images, List<TextData> texts) onCommit;
  final VoidCallback? onChanged;
  final bool Function() suspended;
  final double Function() zoom;
  final void Function(Offset position)? onEraseFromBottom;
  final List<Stroke> Function(Path lassoPath)? onSelectStrokesFromBottom;
  final List<ImageData> Function(Path lassoPath)? onSelectImagesFromBottom;
  final List<TextData> Function(Path lassoPath)? onSelectTextsFromBottom;
  final Function(DrawingTool)? onToolChanged;

  const TopCanvas({
    super.key,
    required this.onCommit,
    this.onChanged,
    required this.suspended,
    required this.zoom,
    this.onEraseFromBottom,
    this.onSelectStrokesFromBottom,
    this.onSelectImagesFromBottom,
    this.onSelectTextsFromBottom,
    this.onToolChanged,
  });

  @override
  State<TopCanvas> createState() => TopCanvasState();
}

class TopCanvasState extends State<TopCanvas> {
  Stroke? _currentStroke;
  List<Stroke> _toplayer = [];
  List<ImageData> _topLayerImages = [];
  List<TextData> _topLayerTexts = [];
  final LassoManager _lassoManager = LassoManager();
  Offset? _lastPointerPos;

  double _penSize = 3.0;
  double _eraserSize = 10.0;
  double _highlighterSize = 10.0;
  double _fontSize = 20.0;
  DrawingTool _selectedTool = DrawingTool.pen;
  
  static const int kMaxPointsPerSegment = 300;
  static const int kSegmentOverlap = 8;

  double penSize = 3.0;
  Color penColor = icon_color;
  int topStrokeLen = 0;

  TextData? _editingText;
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  DateTime? _lastPointerDownTime;
  Offset? _lastPointerDownPos;

  @override
  void dispose() {
    _textEditingController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void addTextAt(Offset pos) {
    setState(() {
      final newText = TextData(
        position: pos,
        fontSize: _fontSize,
        color: penColor,
      );
      _topLayerTexts.add(newText);
      _editingText = newText;
      _textEditingController.text = "";
    });
    widget.onChanged?.call();
  }

  void addImage(ImageData image) {
    setState(() {
      _lassoManager.clearSelection(_toplayer, _topLayerImages, _topLayerTexts, widget.onChanged ?? () {});
      _lassoManager.selectedImages = [image];
      _lassoManager.updateSelectionRect();
      _lassoManager.currentMode = LassoMode.moving;
    });
    widget.onChanged?.call();
  }

  void setTool(DrawingTool tool) {
    if (tool == DrawingTool.duplicate) {
      setState(() {
        _lassoManager.duplicateSelectedItems(_toplayer, _topLayerImages, _topLayerTexts, widget.onChanged ?? () {});
      });
      return;
    }

    DrawingTool oldTool = _selectedTool;
    _selectedTool = tool;

    setState(() {
      if (tool == DrawingTool.pen) {
        penColor = icon_color;
        penSize = _penSize;
      } else if (tool == DrawingTool.eraser || tool == DrawingTool.eraser2) {
        penColor = BG;
        penSize = _eraserSize;
      } else if (tool == DrawingTool.highlighter) {
        penColor = Colors.yellow.withAlpha(77);
        penSize = _highlighterSize;
      } else if (tool == DrawingTool.text) {
        penColor = icon_color;
        penSize = _fontSize;
      }

      bool wasLassoTool = oldTool == DrawingTool.lasso;
      bool isDrawingTool = tool == DrawingTool.pen ||
          tool == DrawingTool.eraser ||
          tool == DrawingTool.eraser2 ||
          tool == DrawingTool.highlighter ||
          tool == DrawingTool.text;

      if (wasLassoTool && isDrawingTool) {
        _lassoManager.clearSelection(_toplayer, _topLayerImages, _topLayerTexts, widget.onChanged ?? () {});
      }
    });
  }

  void changeSize(double delta) {
    setState(() {
      if (_selectedTool == DrawingTool.pen) {
        _penSize = (_penSize + delta).clamp(0.1, 50.0);
        penSize = _penSize;
      } else if (_selectedTool == DrawingTool.eraser || _selectedTool == DrawingTool.eraser2) {
        _eraserSize = (_eraserSize + delta).clamp(0.1, 50.0);
        penSize = _eraserSize;
      } else if (_selectedTool == DrawingTool.highlighter) {
        _highlighterSize = (_highlighterSize + delta).clamp(0.1, 50.0);
        penSize = _highlighterSize;
      } else if (_selectedTool == DrawingTool.text || _selectedTool == DrawingTool.lasso) {
        if (_selectedTool == DrawingTool.text) {
          _fontSize = (_fontSize + delta).clamp(8.0, 200.0);
          penSize = _fontSize;
        }
        
        // Update selected text font size
        if (_lassoManager.selectedTexts.isNotEmpty) {
          for (var txt in _lassoManager.selectedTexts) {
            txt.fontSize = (txt.fontSize + delta).clamp(8.0, 500.0);
          }
        }
      }
    });
    widget.onChanged?.call();
  }

  void setColor(Color color) {
    setState(() {
      penColor = color;
      
      if (_selectedTool == DrawingTool.text) {
        for (var txt in _lassoManager.selectedTexts) {
          txt.color = color;
        }
      }
    });
    widget.onChanged?.call();
  }

  void _eraseStrokeAt(Offset position) {
    bool changed = false;
    final double threshold = penSize * 2.0;

    setState(() {
      _toplayer.removeWhere((stroke) {
        bool hit = stroke.points.any((p) => (p - position).distance < threshold);
        if (hit) changed = true;
        return hit;
      });

      _lassoManager.removeSelectedItems(
        (stroke) {
          bool hit = stroke.points.any((p) => (p - position).distance < threshold);
          if (hit) changed = true;
          return hit;
        },
        (image) {
          bool hit = image.getBounds().contains(position);
          if (hit) changed = true;
          return hit;
        },
        (text) {
          bool hit = text.getBounds().contains(position);
          if (hit) changed = true;
          return hit;
        },
      );
    });

    if (changed) {
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
      widget.onChanged?.call();
      widget.onCommit([], [], []);
    }

    widget.onEraseFromBottom?.call(position);
  }

  void cancelCurrentStroke() {
    setState(() {
      _currentStroke = null;
      if (_lassoManager.currentMode == LassoMode.lassoing) {
        _lassoManager.lassoPath = null;
        _lassoManager.lassoPoints = [];
      }
      _lassoManager.currentMode = LassoMode.none;
    });
  }

  void _updateStroke(Offset position) {
    if (_currentStroke == null) return;
    setState(() {
      _currentStroke!.points.add(position);
      if (_currentStroke!.points.length >= kMaxPointsPerSegment) {
        _splitCurrentStroke();
      }
    });
  }

  void _splitCurrentStroke() {
    final pts = _currentStroke!.points;
    final overlap = pts.sublist(pts.length - kSegmentOverlap);

    final finishedSegment = Stroke(
      points: pts,
      size: _currentStroke!.size,
      color: _currentStroke!.color,
      hasStartCap: _currentStroke!.hasStartCap,
      hasEndCap: false,
    );

    if (topStrokeLen >= 49) {
      _currentStroke = finishedSegment;
      _endStroke();
    } else {
      _toplayer.add(finishedSegment);
    }

    _currentStroke = Stroke(
      points: List<Offset>.from(overlap),
      size: penSize,
      color: penColor,
      hasStartCap: false,
      hasEndCap: true,
    );
  }

  void _startStroke(Offset position) {
    setState(() {
      _currentStroke = Stroke(
        points: [position],
        size: penSize,
        color: penColor,
      );
    });
  }

  void _endStroke() {
    if (_currentStroke == null) return;
    topStrokeLen++;

    if (topStrokeLen >= 50) {
      final strokesToCommit = [..._toplayer, _currentStroke!];
      final imagesToCommit = [..._topLayerImages];
      final textsToCommit = [..._topLayerTexts];
      _toplayer.clear();
      _topLayerImages.clear();
      _topLayerTexts.clear();
      _currentStroke = null;
      topStrokeLen = 0;
      widget.onCommit(strokesToCommit, imagesToCommit, textsToCommit);
    } else {
      _toplayer.add(_currentStroke!);
      _currentStroke = null;
    }
    setState(() {});
    widget.onChanged?.call();
  }

  void setStrokes(List<Stroke> strokes) {
    setState(() {
      _lassoManager.selectedStrokes = [];
      _lassoManager.selectionRect = null;
      _toplayer = List.from(strokes);
      topStrokeLen = _toplayer.where((s) => s.hasEndCap).length;
    });
  }

  void setImages(List<ImageData> images) {
    setState(() {
      _lassoManager.selectedImages = [];
      _lassoManager.selectionRect = null;
      _topLayerImages = List.from(images);
    });
  }

  void setTexts(List<TextData> texts) {
    setState(() {
      _lassoManager.selectedTexts = [];
      _lassoManager.selectionRect = null;
      _topLayerTexts = List.from(texts);
    });
  }

  List<Stroke> getStrokes() => [..._toplayer, ..._lassoManager.selectedStrokes];
  List<ImageData> getImages() => [..._topLayerImages, ..._lassoManager.selectedImages];
  List<TextData> getTexts() => [..._topLayerTexts, ..._lassoManager.selectedTexts];

  void shiftContent(double thresholdY, Offset delta) {
    setState(() {
      for (int i = 0; i < _toplayer.length; i++) {
        final stroke = _toplayer[i];
        if (stroke.getBounds().top >= thresholdY - 1.0) {
          _toplayer[i] = stroke.translate(delta);
        }
      }
      for (int i = 0; i < _topLayerImages.length; i++) {
        final img = _topLayerImages[i];
        if (img.position.dy >= thresholdY - 1.0) {
          _topLayerImages[i] = img.translate(delta);
        }
      }
      for (int i = 0; i < _topLayerTexts.length; i++) {
        final txt = _topLayerTexts[i];
        if (txt.position.dy >= thresholdY - 1.0) {
          _topLayerTexts[i] = txt.translate(delta);
        }
      }

      for (int i = 0; i < _lassoManager.selectedStrokes.length; i++) {
        final stroke = _lassoManager.selectedStrokes[i];
        if (stroke.getBounds().top >= thresholdY - 1.0) {
          _lassoManager.selectedStrokes[i] = stroke.translate(delta);
        }
      }
      for (int i = 0; i < _lassoManager.selectedImages.length; i++) {
        final img = _lassoManager.selectedImages[i];
        if (img.position.dy >= thresholdY - 1.0) {
          _lassoManager.selectedImages[i] = img.translate(delta);
        }
      }
      for (int i = 0; i < _lassoManager.selectedTexts.length; i++) {
        final txt = _lassoManager.selectedTexts[i];
        if (txt.position.dy >= thresholdY - 1.0) {
          _lassoManager.selectedTexts[i] = txt.translate(delta);
        }
      }
      _lassoManager.updateSelectionRect();
    });
  }

  void movePageContent(
      double yMin1, double yMax1, Offset shift1,
      double yMin2, double yMax2, Offset shift2,
      ) {
    setState(() {
      for (int i = 0; i < _toplayer.length; i++) {
        final stroke = _toplayer[i];
        double centerY = stroke.getBounds().center.dy;
        if (centerY >= yMin1 && centerY < yMax1) {
          _toplayer[i] = stroke.translate(shift1);
        } else if (centerY >= yMin2 && centerY < yMax2) {
          _toplayer[i] = stroke.translate(shift2);
        }
      }

      for (int i = 0; i < _lassoManager.selectedStrokes.length; i++) {
        final stroke = _lassoManager.selectedStrokes[i];
        double centerY = stroke.getBounds().center.dy;
        if (centerY >= yMin1 && centerY < yMax1) {
          _lassoManager.selectedStrokes[i] = stroke.translate(shift1);
        } else if (centerY >= yMin2 && centerY < yMax2) {
          _lassoManager.selectedStrokes[i] = stroke.translate(shift2);
        }
      }

      for (int i = 0; i < _topLayerImages.length; i++) {
        final img = _topLayerImages[i];
        double centerY = img.getBounds().center.dy;
        if (centerY >= yMin1 && centerY < yMax1) {
          _topLayerImages[i] = img.translate(shift1);
        } else if (centerY >= yMin2 && centerY < yMax2) {
          _topLayerImages[i] = img.translate(shift2);
        }
      }

      for (int i = 0; i < _topLayerTexts.length; i++) {
        final txt = _topLayerTexts[i];
        double centerY = txt.getBounds().center.dy;
        if (centerY >= yMin1 && centerY < yMax1) {
          _topLayerTexts[i] = txt.translate(shift1);
        } else if (centerY >= yMin2 && centerY < yMax2) {
          _topLayerTexts[i] = txt.translate(shift2);
        }
      }

      for (int i = 0; i < _lassoManager.selectedImages.length; i++) {
        final img = _lassoManager.selectedImages[i];
        double centerY = img.getBounds().center.dy;
        if (centerY >= yMin1 && centerY < yMax1) {
          _lassoManager.selectedImages[i] = img.translate(shift1);
        } else if (centerY >= yMin2 && centerY < yMax2) {
          _lassoManager.selectedImages[i] = img.translate(shift2);
        }
      }

      for (int i = 0; i < _lassoManager.selectedTexts.length; i++) {
        final txt = _lassoManager.selectedTexts[i];
        double centerY = txt.getBounds().center.dy;
        if (centerY >= yMin1 && centerY < yMax1) {
          _lassoManager.selectedTexts[i] = txt.translate(shift1);
        } else if (centerY >= yMin2 && centerY < yMax2) {
          _lassoManager.selectedTexts[i] = txt.translate(shift2);
        }
      }
      _lassoManager.updateSelectionRect();
    });
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (widget.suspended()) return;
          _lastPointerPos = event.localPosition;

          final now = DateTime.now();
          bool isDoubleTap = false;
          if (_lastPointerDownTime != null &&
              now.difference(_lastPointerDownTime!) < const Duration(milliseconds: 300)) {
            if ((event.localPosition - (_lastPointerDownPos ?? Offset.zero)).distance < 20) {
              isDoubleTap = true;
            }
          }
          _lastPointerDownTime = now;
          _lastPointerDownPos = event.localPosition;

          final bool isEraser = _selectedTool == DrawingTool.eraser || _selectedTool == DrawingTool.eraser2;

          // 1. Check for hits on existing selection handles (Resizing) - Global Priority
          if (_lassoManager.selectionRect != null && !isEraser) {
            const handleHitSize = 36.0;
            final rect = _lassoManager.selectionRect!;

            if (Rect.fromCenter(center: rect.topLeft, width: handleHitSize, height: handleHitSize).contains(event.localPosition)) {
              _lassoManager.currentMode = LassoMode.resizing;
              _lassoManager.activeHandle = ResizeHandle.topLeft;
              return;
            } else if (Rect.fromCenter(center: rect.topRight, width: handleHitSize, height: handleHitSize).contains(event.localPosition)) {
              _lassoManager.currentMode = LassoMode.resizing;
              _lassoManager.activeHandle = ResizeHandle.topRight;
              return;
            } else if (Rect.fromCenter(center: rect.bottomLeft, width: handleHitSize, height: handleHitSize).contains(event.localPosition)) {
              _lassoManager.currentMode = LassoMode.resizing;
              _lassoManager.activeHandle = ResizeHandle.bottomLeft;
              return;
            } else if (Rect.fromCenter(center: rect.bottomRight, width: handleHitSize, height: handleHitSize).contains(event.localPosition)) {
              _lassoManager.currentMode = LassoMode.resizing;
              _lassoManager.activeHandle = ResizeHandle.bottomRight;
              return;
            }
          }

          // 2. Global Object Interaction (Text Boxes & Images)
          if (!isEraser) {
            TextData? hitText;
            ImageData? hitImage;
            bool hitInsideSelection = false;

            // Check if we hit an ALREADY selected text box or image
            for (var txt in _lassoManager.selectedTexts) {
              if (txt.getBounds().contains(event.localPosition)) {
                hitText = txt;
                hitInsideSelection = true;
                break;
              }
            }
            if (hitText == null) {
              for (var img in _lassoManager.selectedImages) {
                if (img.getBounds().contains(event.localPosition)) {
                  hitImage = img;
                  hitInsideSelection = true;
                  break;
                }
              }
            }
            
            // Check unselected top layer texts
            if (hitText == null && hitImage == null) {
              for (var txt in _topLayerTexts) {
                if (txt.getBounds().contains(event.localPosition)) {
                  hitText = txt;
                  break;
                }
              }
            }

            // Check unselected top layer images
            if (hitText == null && hitImage == null) {
              for (var img in _topLayerImages) {
                if (img.getBounds().contains(event.localPosition)) {
                  hitImage = img;
                  break;
                }
              }
            }

            // Check bottom layer texts (lift if found)
            if (hitText == null && hitImage == null && widget.onSelectTextsFromBottom != null) {
              final smallPath = Path()..addRect(Rect.fromCenter(center: event.localPosition, width: 20, height: 20));
              final fromBottom = widget.onSelectTextsFromBottom!(smallPath);
              if (fromBottom.isNotEmpty) {
                hitText = fromBottom.first;
                if (fromBottom.length > 1) {
                  _topLayerTexts.addAll(fromBottom.skip(1));
                }
              }
            }

            // Check bottom layer images (lift if found)
            if (hitText == null && hitImage == null && widget.onSelectImagesFromBottom != null) {
              final smallPath = Path()..addRect(Rect.fromCenter(center: event.localPosition, width: 20, height: 20));
              final fromBottom = widget.onSelectImagesFromBottom!(smallPath);
              if (fromBottom.isNotEmpty) {
                hitImage = fromBottom.first;
                if (fromBottom.length > 1) {
                  _topLayerImages.addAll(fromBottom.skip(1));
                }
              }
            }

            // Check general selection rect hit
            if (hitText == null && hitImage == null && _lassoManager.selectionRect != null && _lassoManager.selectionRect!.contains(event.localPosition)) {
              hitInsideSelection = true;
            }

            if (hitText != null || hitImage != null || hitInsideSelection) {
              // Open for editing if double tap OR single tap on already selected item
              bool shouldEdit = isDoubleTap || (hitInsideSelection && _selectedTool == DrawingTool.text);
              
              if (shouldEdit && hitText != null) {
                // Cancel accidental stroke from first tap
                if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
                  if (_toplayer.isNotEmpty && _toplayer.last.points.length < 5) {
                    _toplayer.removeLast();
                    topStrokeLen = (topStrokeLen - 1).clamp(0, 9999);
                  }
                }
                setState(() {
                  _editingText = hitText;
                  _textEditingController.text = hitText!.text;
                  _textEditingController.selection = TextSelection.fromPosition(TextPosition(offset: hitText!.text.length));
                  _selectedTool = DrawingTool.text;
                  penColor = icon_color;
                  penSize = _fontSize;
                });
                _textFocusNode.requestFocus();
                // Ensure keyboard opens
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _textFocusNode.requestFocus();
                });
                widget.onToolChanged?.call(DrawingTool.text);
                return;
              } else {
                // Single tap selection logic
                if (!hitInsideSelection) {
                  setState(() {
                    _editingText = null;
                    // Move current selection back to top layer
                    _toplayer.addAll(_lassoManager.selectedStrokes);
                    _topLayerImages.addAll(_lassoManager.selectedImages);
                    _topLayerTexts.addAll(_lassoManager.selectedTexts);
                    _lassoManager.selectedStrokes = [];
                    _lassoManager.selectedImages = [];
                    _lassoManager.selectedTexts = [];
                    
                    if (hitText != null) {
                      _topLayerTexts.remove(hitText);
                      _lassoManager.selectedTexts = [hitText!];
                      _selectedTool = DrawingTool.text;
                      penColor = icon_color;
                      penSize = _fontSize;
                      widget.onToolChanged?.call(DrawingTool.text);
                    } else if (hitImage != null) {
                      _topLayerImages.remove(hitImage);
                      _lassoManager.selectedImages = [hitImage!];
                      // For images, we can switch to lasso or just stay in current drawing tool
                      // but 'moving' mode will be active.
                    }
                    
                    _lassoManager.updateSelectionRect();
                    _lassoManager.currentMode = LassoMode.moving;
                  });
                  widget.onChanged?.call();
                  return;
                } else {
                  // Tapped inside existing selection
                  _lassoManager.currentMode = LassoMode.moving;
                  return;
                }
              }
            }
          }

          // 3. Normal Tool Fallback
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else if (_selectedTool == DrawingTool.lasso) {
            _lassoManager.startLasso(event.localPosition, _toplayer, _topLayerImages, _topLayerTexts);
          } else if (_selectedTool == DrawingTool.text) {
            // Tapped empty space in text tool
            setState(() {
              if (_editingText != null) {
                _editingText = null;
              } else {
                _lassoManager.clearSelection(_toplayer, _topLayerImages, _topLayerTexts, widget.onChanged ?? () {});
                widget.onToolChanged?.call(DrawingTool.pen);
              }
            });
          } else {
            _startStroke(event.localPosition);
          }
        },
        onPointerMove: (event) {
          if (widget.suspended()) return;
          final delta = event.localPosition - (_lastPointerPos ?? event.localPosition);
          if (_selectedTool == DrawingTool.eraser2) {
            _eraseStrokeAt(event.localPosition);
          } else if (_selectedTool == DrawingTool.lasso || _selectedTool == DrawingTool.text) {
            setState(() {
              switch (_lassoManager.currentMode) {
                case LassoMode.lassoing:
                  _lassoManager.updateLasso(event.localPosition);
                  break;
                case LassoMode.moving:
                  _lassoManager.handleMove(delta, () {}); // Don't record history during move
                  break;
                case LassoMode.resizing:
                  _lassoManager.handleResize(event.localPosition, delta, () {}); // Don't record history during resize
                  break;
                case LassoMode.none:
                  break;
              }
            });
          } else {
            _updateStroke(event.localPosition);
          }
          _lastPointerPos = event.localPosition;
        },
        onPointerUp: (_) {
          if (_selectedTool == DrawingTool.lasso || _selectedTool == DrawingTool.text) {
            setState(() {
              _lassoManager.activeHandle = ResizeHandle.none;
              if (_lassoManager.currentMode == LassoMode.lassoing) {
                _lassoManager.selectItemsInLasso(
                  topLayerStrokes: _toplayer,
                  topLayerImages: _topLayerImages,
                  topLayerTexts: _topLayerTexts,
                  onSelectStrokesFromBottom: widget.onSelectStrokesFromBottom ?? (p) => [],
                  onSelectImagesFromBottom: widget.onSelectImagesFromBottom ?? (p) => [],
                  onSelectTextsFromBottom: widget.onSelectTextsFromBottom ?? (p) => [],
                  onChanged: widget.onChanged ?? () {},
                );
              } else if (_lassoManager.currentMode == LassoMode.moving || _lassoManager.currentMode == LassoMode.resizing) {
                widget.onChanged?.call(); // Record history once at the end of move/resize
              }
              _lassoManager.currentMode = LassoMode.none;
            });
          } else if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
            _endStroke();
          }
          _lastPointerPos = null;
        },
        onPointerCancel: (_) {
          if (_selectedTool == DrawingTool.lasso) {
            setState(() {
              if (_lassoManager.currentMode == LassoMode.lassoing) {
                _lassoManager.lassoPath = null;
                _lassoManager.lassoPoints = [];
              }
              _lassoManager.currentMode = LassoMode.none;
            });
          } else if (_selectedTool == DrawingTool.pen || _selectedTool == DrawingTool.highlighter) {
            _endStroke();
          }
          _lastPointerPos = null;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ..._topLayerImages.map((img) => Positioned(
              left: img.position.dx,
              top: img.position.dy,
              child: Opacity(
                opacity: 0.8,
                child: Image.file(
                  File(img.imagePath),
                  width: img.width,
                  height: img.height,
                  fit: BoxFit.contain,
                ),
              ),
            )),
            ..._lassoManager.selectedImages.map((img) => Positioned(
              left: img.position.dx,
              top: img.position.dy,
              child: Image.file(
                File(img.imagePath),
                width: img.width,
                height: img.height,
                fit: BoxFit.contain,
              ),
            )),
            ..._topLayerTexts.map((txt) => Positioned(
              left: txt.position.dx,
              top: txt.position.dy,
              width: txt.width,
              height: txt.height,
              child: _buildTextBox(txt),
            )),
            ..._lassoManager.selectedTexts.map((txt) => Positioned(
              left: txt.position.dx,
              top: txt.position.dy,
              width: txt.width,
              height: txt.height,
              child: _buildTextBox(txt, isSelected: true),
            )),
            // DRAWING LAYER ON TOP - Use IgnorePointer to allow hits to reach TextFields underneath
            IgnorePointer(
              child: CustomPaint(
                painter: HandwritingPainter(
                  strokes: _toplayer,
                  currentStroke: _currentStroke,
                  selectedStrokes: _lassoManager.selectedStrokes,
                  selectionRect: _lassoManager.selectionRect,
                  lassoPath: _lassoManager.lassoPath,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBox(TextData txt, {bool isSelected = false}) {
    bool isEditing = _editingText == txt;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : (isEditing ? accent : Colors.blue.withOpacity(0.2)),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: isEditing 
        ? TextField(
            autofocus: true,
            controller: _textEditingController,
            focusNode: _textFocusNode,
            style: TextStyle(
              fontSize: txt.fontSize,
              color: txt.color,
            ),
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.all(4),
            ),
            onChanged: (val) {
              txt.text = val;
            },
            onSubmitted: (val) {
              txt.text = val;
              setState(() => _editingText = null);
              widget.onChanged?.call();
            },
            onTapOutside: (_) {
              if (_editingText == txt) {
                 setState(() => _editingText = null);
                 widget.onChanged?.call();
              }
            },
          )
        : Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              txt.text.isEmpty && isSelected ? "Tap to type..." : txt.text,
              style: TextStyle(
                fontSize: txt.fontSize,
                color: txt.text.isEmpty ? txt.color.withOpacity(0.5) : txt.color,
              ),
            ),
          ),
      ),
    );
  }
}
