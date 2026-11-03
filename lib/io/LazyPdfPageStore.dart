import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';

/// Only rendering PDF pages near the current page.
class LazyPdfPageStore {
  final String pdfPath;
  final Directory noteDir;
  final int renderRadius;
  final int diskKeepRadius;
  final double maxDimension;
  final double previewDimension;

  late final Directory _cacheDir;

  PdfDocument? _document;
  Future<PdfDocument>? _openFuture;
  Future<void> _renderQueue = Future<void>.value();
  int _pageChangeToken = 0;

  final Map<int, String> _renderedPaths = {};
  final Set<int> _cachedPageIndices = {};

  /// Tracks page indices currently being rendered to prevent
  /// duplicate concurrent rendering tasks for the same page.
  final Map<String, Future<String>> _activeTasks = {};

  LazyPdfPageStore({
    required this.pdfPath,
    required this.noteDir,
    this.renderRadius =
        1, // pages actually rendered around current, aka +-1 from current page
    this.diskKeepRadius = 12,
    this.maxDimension = 1600.0,
    this.previewDimension = 800.0,
  }) {
    final String fileId = p
        .basenameWithoutExtension(pdfPath)
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final String folderId = p
        .basename(p.dirname(pdfPath))
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final String uniqueId = '${folderId}_$fileId';
    _cacheDir = Directory(p.join(noteDir.path, '.pdf_cache', uniqueId));
  }

  /// opens the pdf if it isn't already
  Future<void> _ensureOpen() async {
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
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

    // 2. Disk check
    final diskPath = p.join(_cacheDir.path, 'page_$pageIndex.jpg');
    if (await File(diskPath).exists()) {
      _renderedPaths[pageIndex] = diskPath;
      _cachedPageIndices.add(pageIndex);
      return diskPath;
    }

    // 3. De-duplicate active rendering tasks
    final taskKey = '$pageIndex:full';
    if (_activeTasks.containsKey(taskKey)) return _activeTasks[taskKey]!;

    final task = _queueRender(pageIndex, preview: false);
    _activeTasks[taskKey] = task;
    try {
      return await task;
    } finally {
      _activeTasks.remove(taskKey);
    }
  }

  Future<String> previewPathForPage(int pageIndex) async {
    final fullPath = p.join(_cacheDir.path, 'page_$pageIndex.jpg');
    if (await File(fullPath).exists()) {
      _cachedPageIndices.add(pageIndex);
      return fullPath;
    }

    final previewPath = p.join(_cacheDir.path, 'page_$pageIndex.preview.jpg');
    if (await File(previewPath).exists()) {
      _cachedPageIndices.add(pageIndex);
      return previewPath;
    }

    final taskKey = '$pageIndex:preview';
    if (_activeTasks.containsKey(taskKey)) return _activeTasks[taskKey]!;

    final task = _queueRender(pageIndex, preview: true);
    _activeTasks[taskKey] = task;
    try {
      return await task;
    } finally {
      _activeTasks.remove(taskKey);
    }
  }

  Future<String> _queueRender(int pageIndex, {required bool preview}) {
    final completer = Completer<String>();
    _renderQueue = _renderQueue.then((_) async {
      try {
        completer.complete(await _renderPage(pageIndex, preview: preview));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// Renders a singular page from a PDF
  Future<String> _renderPage(int pageIndex, {required bool preview}) async {
    // open the file
    await _ensureOpen();
    if (pageIndex < 1 || pageIndex > pagesCount) {
      throw RangeError.index(
        pageIndex,
        null,
        "pageIndex",
        "Page index out of range",
        pagesCount,
      );
    }

    // get the page
    final page = await _document!.getPage(pageIndex);

    try {
      final dimension = preview ? previewDimension : maxDimension;
      final scale =
          (dimension / (page.width > page.height ? page.width : page.height))
              .clamp(0.35, 2.0);

      final pageImage = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.jpeg,
        quality: preview ? 68 : 84,
      );

      if (pageImage == null) {
        throw Exception("Failed to render page $pageIndex");
      }

      /// Save page locally
      final path = p.join(
        _cacheDir.path,
        preview ? 'page_$pageIndex.preview.jpg' : 'page_$pageIndex.jpg',
      );
      await File(path).writeAsBytes(pageImage.bytes);

      /// Cache the path for later
      _cachedPageIndices.add(pageIndex);
      if (!preview) _renderedPaths[pageIndex] = path;
      return path;
    } finally {
      await page.close();
    }
  }

  /// Call whenever the viewer's current page changes.
  /// Renders pages within [renderRadius], then evicts files
  /// outside [diskKeepRadius] to bound storage use.
  Future<void> onCurrentPageChanged(int currentPage) async {
    final token = ++_pageChangeToken;
    await _ensureOpen();
    final count = pagesCount;
    if (count == 0) return;

    await previewPathForPage(currentPage);
    if (token != _pageChangeToken) return;

    for (int distance = 1; distance <= renderRadius; distance++) {
      for (final pageIndex in [
        currentPage - distance,
        currentPage + distance,
      ]) {
        if (token != _pageChangeToken) return;
        if (pageIndex >= 1 && pageIndex <= count) {
          await previewPathForPage(pageIndex);
        }
      }
    }

    _evictOutside(currentPage);
  }

  void _evictOutside(int currentPage) {
    final count = pagesCount;
    if (count == 0) return;

    final keepLo = (currentPage - diskKeepRadius).clamp(1, count);
    final keepHi = (currentPage + diskKeepRadius).clamp(1, count);

    final toRemove = _cachedPageIndices
        .where((i) => i < keepLo || i > keepHi)
        .toList();

    for (final i in toRemove) {
      _cachedPageIndices.remove(i);
      _renderedPaths.remove(i);
      final fullPath = p.join(_cacheDir.path, 'page_$i.jpg');
      File(fullPath).delete().catchError((_) => File(''));
      final previewPath = p.join(_cacheDir.path, 'page_$i.preview.jpg');
      File(previewPath).delete().catchError((_) => File(''));
    }
  }

  Future<void> dispose() async {
    await _document?.close();
    _document = null;
    _openFuture = null;
  }
}
