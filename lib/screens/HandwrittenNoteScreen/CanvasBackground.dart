import 'dart:io';
import 'package:flutter/material.dart';
import '../../app_style.dart';

import '../../models/HandwrittenNote.dart';

/// Resolves the background image path for a NotePage, rendering
/// it on demand if needed (e.g. from a PDF). Returns null if there's no
/// background for that page.
typedef PageBackgroundResolver =
    Future<String?> Function(NotePage page, {required bool preview});

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
    this.windowRadius = 1,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: Column(
        children: List.generate(pages.length, (index) {
          final page = pages[index];
          return Container(
            width: pageWidth,
            height: basePageHeight,
            decoration: BoxDecoration(
              color: BG,
              border: Border(
                bottom: BorderSide(color: icon_color.withAlpha(40), width: 1.0),
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
                  isCurrent: index == currentPage,
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
        }),
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
  final bool isCurrent;

  const PageBackgroundImage({
    super.key,
    required this.page,
    required this.width,
    required this.height,
    required this.resolver,
    required this.inWindow,
    required this.isCurrent,
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
    } else if (widget.isCurrent && !oldWidget.isCurrent) {
      _load();
    }
  }

  Future<void> _load() async {
    var path = _resolvedPath;
    if (_resolving || widget.resolver == null) return;

    final isMarker = path == null || path.startsWith('pdf_page:');
    final isPreview = path?.endsWith('.preview.jpg') ?? false;
    final pathExists = !isMarker && await File(path).exists();
    if (pathExists && !isPreview) {
      _setImagePath(path);
      return;
    }

    _resolving = true;
    if (mounted) setState(() {});
    try {
      if (!pathExists) {
        path = await widget.resolver!(widget.page, preview: true);
        if (path != null) _setImagePath(path);
      }

      if (mounted &&
          widget.inWindow &&
          widget.isCurrent &&
          (path?.endsWith('.preview.jpg') ?? false)) {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (mounted && widget.inWindow && widget.isCurrent) {
          final fullPath = await widget.resolver!(widget.page, preview: false);
          if (fullPath != null) _setImagePath(fullPath);
        }
      }
    } catch (error) {
      debugPrint('Failed to resolve page background: $error');
    } finally {
      _resolving = false;
      if (mounted) setState(() {});
    }
  }

  void _setImagePath(String path) {
    if (!mounted) return;
    setState(() {
      _resolvedPath = path;
      _fileImage = FileImage(File(path));
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inWindow ||
        _resolvedPath == null ||
        _resolvedPath!.startsWith("pdf_page:")) {
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
