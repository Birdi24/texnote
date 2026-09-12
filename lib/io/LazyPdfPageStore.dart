import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';

/// Only rendering PDF pages near the current page,
class LazyPdfPageStore {
  LazyPdfPageStore({
    required this.pdfPath,
    required this.noteDir,
    this.renderRadius = 1, // pages actually rendered around current, aka +-1 from current page
    this.diskKeepRadius = 2, // wider buffer before deleting rendered pages
    this.maxDimension = 2400.0, // max dimension of rendered pages
  });

  final String pdfPath;
  final Directory noteDir;
  final int renderRadius;
  final int diskKeepRadius;
  final double maxDimension;

  PdfDocument? _document;
  Future<PdfDocument>? _openFuture;

  final Map<int, String> _renderedPaths = {};

  /// Tracks page indices currently being rendered to prevent
  /// duplicate concurrent rendering tasks for the same page.
  final Map<int, Future<String>> _activeTasks = {};

  /// opens the pdf if it isn't already
  Future<void> _ensureOpen() async {
    if (_document != null) return;
    _openFuture ??= PdfDocument.openFile(pdfPath);
    _document = await _openFuture;
  }

  int get pagesCount => _document?.pagesCount ?? 0;

  /// Returns the rendered file path for [pageIndex] (1-based),
  /// rendering it now if it isn't cached yet.
  Future<String> pathForPage(int pageIndex) async {
    // 1. Memory cache
    final cached = _renderedPaths[pageIndex];
    if (cached != null && await File(cached).exists()) return cached;

    // 2. Disk check (e.g. after restart)
    final diskPath = p.join(noteDir.path, 'page_$pageIndex.jpg');
    if (await File(diskPath).exists()) {
      _renderedPaths[pageIndex] = diskPath;
      return diskPath;
    }

    // 3. De-duplicate active rendering tasks
    if (_activeTasks.containsKey(pageIndex)) return _activeTasks[pageIndex]!;

    final task = _renderPage(pageIndex);
    _activeTasks[pageIndex] = task;
    try {
      return await task;
    } finally {
      _activeTasks.remove(pageIndex);
    }
  }

  /// Renders a singular page from a PDF
  Future<String> _renderPage(int pageIndex) async {
    // open the file
    await _ensureOpen();
    if (pageIndex < 1 || pageIndex > pagesCount) {
      throw RangeError.index(pageIndex, null, "pageIndex", "Page index out of range", pagesCount);
    }

    // get the page
    final page = await _document!.getPage(pageIndex);

    try {
      final scale = (page.width > page.height)
          ? (maxDimension / page.width).clamp(1.0, 2.0)
          : (maxDimension / page.height).clamp(1.0, 2.0);

      final pageImage = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.jpeg,
      );

      /// Save page locally
      final path = p.join(noteDir.path, 'page_$pageIndex.jpg');
      await File(path).writeAsBytes(pageImage!.bytes);

      /// Cache the path for later
      _renderedPaths[pageIndex] = path;
      return path;
    } finally {
      await page.close();
    }
  }

  /// Call whenever the viewer's current page changes.
  /// Renders pages within [renderRadius], then evicts files
  /// outside [diskKeepRadius] to bound storage use.
  Future<void> onCurrentPageChanged(int currentPage) async {
    await _ensureOpen();
    final count = pagesCount;
    if (count == 0) return;

    final lo = (currentPage - renderRadius).clamp(1, count);
    final hi = (currentPage + renderRadius).clamp(1, count);

    // Sequential rendering to avoid resource contention
    for (int i = lo; i <= hi; i++) {
      await pathForPage(i);
    }

    // evict pages outside diskKeepRadius
    _evictOutside(currentPage);
  }

  void _evictOutside(int currentPage) {
    final count = pagesCount;
    if (count == 0) return;

    final keepLo = (currentPage - diskKeepRadius).clamp(1, count);
    final keepHi = (currentPage + diskKeepRadius).clamp(1, count);

    final toRemove = _renderedPaths.keys
        .where((i) => i < keepLo || i > keepHi)
        .toList();

    for (final i in toRemove) {
      final path = _renderedPaths.remove(i);
      if (path != null) {
        File(path).delete().catchError((_) {});
      }
    }
  }

  Future<void> dispose() async {
    await _document?.close();
    _document = null;
    _openFuture = null;
  }
}
