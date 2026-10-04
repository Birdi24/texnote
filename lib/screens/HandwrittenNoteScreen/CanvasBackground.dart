import 'dart:io';
import 'package:flutter/material.dart';
import '../../app_style.dart';

import '../../models/HandwrittenNote.dart';

/// Resolves the background image path for a NotePage, rendering
/// it on demand if needed (e.g. from a PDF). Returns null if there's no
/// background for that page.
typedef PageBackgroundResolver = Future<String?> Function(NotePage page);

class CanvasBackground extends StatelessWidget {
  final List<NotePage> pages;
  final double pageWidth;
  final double basePageHeight;
  final String paperType;
  final PageBackgroundResolver? resolvePageBackground;
  final int currentPage;
  final int windowRadius;

  const CanvasBackground({
    super.key,
    required this.pages,
    required this.pageWidth,
    required this.basePageHeight,
    required this.paperType,
    this.resolvePageBackground,
    this.currentPage = 0,
    this.windowRadius = 2,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: Column(
        children: List.generate(
          pages.length,
          (index) {
            final page = pages[index];
            return Container(
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
                  PageBackgroundImage(
                    key: ValueKey('page_bg_${page.id}'),
                    page: page,
                    width: pageWidth,
                    height: basePageHeight,
                    resolver: resolvePageBackground,
                    inWindow: (index - currentPage).abs() <= windowRadius,
                  ),
                  if (paperType != "blank")
                    CustomPaint(
                      size: Size(pageWidth, basePageHeight),
                      painter: PaperPainter(paperType),
                    ),
                  if (index > 0 || page.background != null)
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
            );
          },
        ),
      ),
    );
  }
}

class PageBackgroundImage extends StatefulWidget {
  final NotePage page;
  final double width;
  final double height;
  final PageBackgroundResolver? resolver;
  final bool inWindow;

  const PageBackgroundImage({
    super.key,
    required this.page,
    required this.width,
    required this.height,
    required this.resolver,
    required this.inWindow,
  });

  @override
  State<PageBackgroundImage> createState() => PageBackgroundImageState();
}

class PageBackgroundImageState extends State<PageBackgroundImage> {
  String? _resolvedPath;
  FileImage? _fileImage;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolvedPath = widget.page.background;
    if (widget.inWindow) _load();
  }

  @override
  void didUpdateWidget(covariant PageBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inWindow && !oldWidget.inWindow) {
      _load();
    } else if (!widget.inWindow && oldWidget.inWindow) {
      _evict();
    }
  }

  Future<void> _load() async {
    var path = _resolvedPath;
    
    // If it's a PDF marker, it's not a real path yet
    bool isMarker = path != null && path.startsWith("pdf_page:");
    
    // Check if the path is invalid (marker or missing file)
    bool isInvalid = path == null || isMarker;
    if (!isInvalid && path != null) {
      if (!await File(path).exists()) {
        isInvalid = true;
      }
    }
    
    if (isInvalid && widget.resolver != null && !_resolving) {
      _resolving = true;
      path = await widget.resolver!(widget.page);
      _resolving = false;
      if (!mounted) return;
      setState(() => _resolvedPath = path);
      return;
    }
    
    if (path != null && !path.startsWith("pdf_page:") && mounted) {
      setState(() => _fileImage = FileImage(File(path!)));
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
    if (!widget.inWindow || _resolvedPath == null || _resolvedPath!.startsWith("pdf_page:")) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: _resolving 
            ? const CircularProgressIndicator() 
            : const SizedBox.shrink(),
        ),
      );
    }
    _fileImage ??= FileImage(File(_resolvedPath!));
    return Image(
      image: _fileImage!,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // If image loading fails (e.g. file deleted from disk), try to re-resolve
        if (!_resolving) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _load());
        }
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
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
