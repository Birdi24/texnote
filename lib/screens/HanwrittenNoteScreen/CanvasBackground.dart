import 'dart:io';
import 'package:flutter/material.dart';
import '../../app_style.dart';

/// Resolves the background image path for a 0-based page index, rendering
/// it on demand if needed (e.g. from a PDF). Returns null if there's no
/// background for that page.
typedef PageBackgroundResolver = Future<String?> Function(int pageIndex);

class CanvasBackground extends StatelessWidget {
  final int numPages;
  final double pageWidth;
  final double basePageHeight;
  final String paperType;

  /// Already-known background paths, index-aligned with pages.
  /// Entries can be null if not rendered yet.
  final List<String?> pageBackgrounds;

  /// Renders a page's background on demand (used for lazily-rendered PDF
  /// pages). If null, only [pageBackgrounds] is used.
  final PageBackgroundResolver? resolvePageBackground;

  /// 0-based index of the page currently centered in the viewport.
  final int currentPage;

  /// Pages within this many indices of [currentPage] get their image
  /// loaded; everything else shows a blank placeholder.
  final int windowRadius;

  const CanvasBackground({
    super.key,
    required this.numPages,
    required this.pageWidth,
    required this.basePageHeight,
    required this.paperType,
    this.pageBackgrounds = const [],
    this.resolvePageBackground,
    this.currentPage = 0,
    this.windowRadius = 1,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
        maxHeight: double.infinity,
        alignment: Alignment.topCenter, child:Column(
      children: List.generate(
        numPages,
            (index) => Container(
          width: pageWidth,
          height: basePageHeight,
          decoration: BoxDecoration(
            color: BG,
            border: Border(
              bottom: BorderSide(
                color: icon_color.withAlpha(40),
                width: 1.0,
              ),
            ),
          ),
          child: Stack(
            children: [
              _PageBackgroundImage(
                key: ValueKey('page_bg_$index'),
                pageIndex: index,
                width: pageWidth,
                height: basePageHeight,
                knownPath: pageBackgrounds.length > index ? pageBackgrounds[index] : null,
                resolver: resolvePageBackground,
                inWindow: (index - currentPage).abs() <= windowRadius,
              ),
              if (paperType != "blank")
                CustomPaint(
                  size: Size(pageWidth, basePageHeight),
                  painter: PaperPainter(paperType),
                ),
              if (index > 0 || pageBackgrounds.isNotEmpty)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "Page ${index + 1}",
                      style: AppStyles.icon_text.copyWith(
                        fontSize: 14,
                        color: icon_color.withAlpha(30),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}

/// Only builds/holds a decoded image while [inWindow] is true. Evicts the
/// underlying FileImage from Flutter's image cache as soon as the page
/// scrolls out of the window, so far-away pages don't hold memory.
class _PageBackgroundImage extends StatefulWidget {
  final int pageIndex;
  final double width;
  final double height;
  final String? knownPath;
  final PageBackgroundResolver? resolver;
  final bool inWindow;

  const _PageBackgroundImage({
    super.key,
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.knownPath,
    required this.resolver,
    required this.inWindow,
  });

  @override
  State<_PageBackgroundImage> createState() => _PageBackgroundImageState();
}

class _PageBackgroundImageState extends State<_PageBackgroundImage> {
  String? _resolvedPath;
  FileImage? _fileImage;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolvedPath = widget.knownPath;
    if (widget.inWindow) _load();
  }

  @override
  void didUpdateWidget(covariant _PageBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.knownPath != widget.knownPath) {
      _evict();
      _resolvedPath = widget.knownPath;
    }

    if (widget.inWindow && !oldWidget.inWindow) {
      _load();
    } else if (!widget.inWindow && oldWidget.inWindow) {
      _evict();
    }
  }

  Future<void> _load() async {
    // Explicitly blank page — NEVER ask the resolver for a PDF page.
    if (_resolvedPath == "blank") {
      return;
    }

    var path = _resolvedPath;

    if (path == null && widget.resolver != null && !_resolving) {
      _resolving = true;

      try {
        path = await widget.resolver!(widget.pageIndex);

        if (!mounted) return;

        _resolvedPath = path;

        if (path != null && path != "blank") {
          _fileImage = FileImage(File(path));
        }

        setState(() {});
      } finally {
        _resolving = false;
      }

      return;
    }

    if (path != null && path != "blank" && mounted) {
      setState(() {
        _fileImage = FileImage(File(path!));
      });
    }
  }
  void _evict() {
    _fileImage?.evict();
    _fileImage = null;
  }

  @override
  void dispose() {
    _evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (!widget.inWindow || _resolvedPath == null || _resolvedPath == "blank") {
      // Reserves layout space with no decode cost.
      return SizedBox(width: widget.width, height: widget.height);
    }
    _fileImage ??= FileImage(File(_resolvedPath!));
    return Image(
      image: _fileImage!,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
    );
  }
}

class PaperPainter extends CustomPainter {
  final String paperType;

  PaperPainter(this.paperType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = icon_color.withAlpha(30)
      ..strokeWidth = 0.5;

    if (paperType == "lined") {
      double spacing = 30.0;
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (paperType == "dot-grid") {
      double spacing = 25.0;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 0.8, paint);
        }
      }
    } else if (paperType == "full-grid") {
      double spacing = 25.0;
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}