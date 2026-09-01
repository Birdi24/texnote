import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../app_style.dart';
import '../../models/HandwrittenNote.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/single_circle_button.dart';
import 'CanvasBackground.dart';
import 'HandwritingPainter.dart';

class PageThumbnailView extends StatefulWidget {
  final int numPages;
  final List<String?> pageBackgrounds;
  final String paperType;
  final Function(int index, int direction) onMovePage;
  final VoidCallback onClose;
  final List<Stroke> strokes;
  final List<ImageData> images;
  final double pageWidth;
  final double basePageHeight;
  final PageBackgroundResolver? resolvePageBackground;
  final Function(int index)? onPageTap;
  final int? initialPageIndex;
  final int currentPage;
  final Map<int, ui.Image> thumbnailCache;

  const PageThumbnailView({
    super.key,
    required this.currentPage,
    required this.numPages,
    required this.pageBackgrounds,
    required this.paperType,
    required this.onMovePage,
    required this.onClose,
    required this.strokes,
    required this.images,
    required this.pageWidth,
    required this.basePageHeight,
    required this.thumbnailCache,
    this.resolvePageBackground,
    this.onPageTap,
    this.initialPageIndex,
  });

  @override
  State<PageThumbnailView> createState() => _PageThumbnailViewState();
}

class _PageThumbnailViewState extends State<PageThumbnailView> {
  int? _selectedPageIndex;
  late ScrollController _scrollController;
  static const double _thumbnailHeight = 184.0;
  static const double _thumbnailSpacing = 15.0;

  Map<int, List<Stroke>> _strokesByPage = {};
  Map<int, List<ImageData>> _imagesByPage = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {});
    });

    _indexContentIfNeeded();

    if (widget.initialPageIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final double itemHeight = _thumbnailHeight + _thumbnailSpacing;
          final double offset = 10.0 + (widget.initialPageIndex! * itemHeight);
          _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PageThumbnailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Force re-indexing of stroke bounds per page when content or page order changes
    _indexContent();
  }

  void _indexContent() {
    _strokesByPage = {};
    for (final stroke in widget.strokes) {
      final bounds = stroke.getBounds();
      final startPage = (bounds.top / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);
      final endPage = (bounds.bottom / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);

      for (int p = startPage; p <= endPage; p++) {
        final yMin = p * widget.basePageHeight;
        final translated = stroke.translate(Offset(0, -yMin));
        _strokesByPage.putIfAbsent(p, () => []).add(translated);
      }
    }

    _imagesByPage = {};
    for (final img in widget.images) {
      final bounds = img.getBounds();
      final startPage = (bounds.top / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);
      final endPage = (bounds.bottom / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);

      for (int p = startPage; p <= endPage; p++) {
        _imagesByPage.putIfAbsent(p, () => []).add(img);
      }
    }
  }

  void _indexContentIfNeeded() {
    bool allCached = true;
    for (int i = 0; i < widget.numPages; i++) {
      if (!widget.thumbnailCache.containsKey(i)) {
        allCached = false;
        break;
      }
    }
    if (allCached) return;

    _strokesByPage = {};
    for (final stroke in widget.strokes) {
      final bounds = stroke.getBounds();
      final startPage = (bounds.top / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);
      final endPage = (bounds.bottom / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);

      for (int p = startPage; p <= endPage; p++) {
        final yMin = p * widget.basePageHeight;
        final translated = stroke.translate(Offset(0, -yMin));
        _strokesByPage.putIfAbsent(p, () => []).add(translated);
      }
    }

    _imagesByPage = {};
    for (final img in widget.images) {
      final bounds = img.getBounds();
      final startPage = (bounds.top / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);
      final endPage = (bounds.bottom / widget.basePageHeight).floor().clamp(0, widget.numPages - 1);

      for (int p = startPage; p <= endPage; p++) {
        _imagesByPage.putIfAbsent(p, () => []).add(img);
      }
    }
  }

  int _firstThumbnailIndex() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    return ((offset - 10) / (_thumbnailHeight + _thumbnailSpacing))
        .floor()
        .clamp(0, widget.numPages - 1);
  }

  int _lastThumbnailIndex() {
    if (!_scrollController.hasClients) {
      return 5.clamp(0, widget.numPages - 1);
    }
    final viewportHeight = _scrollController.position.viewportDimension;
    return (((_scrollController.offset + viewportHeight) - 10) / (_thumbnailHeight + _thumbnailSpacing))
        .ceil()
        .clamp(0, widget.numPages - 1);
  }

  bool _shouldLoadBackground(int index) {
    final first = _firstThumbnailIndex() - 2;
    final last = _lastThumbnailIndex() + 2;
    return index >= first && index <= last;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMove(int index, int direction) {
    int targetIndex = index + direction;
    if (targetIndex >= 0 && targetIndex < widget.numPages) {
      widget.onMovePage(index, direction);
      setState(() {
        _selectedPageIndex = targetIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return glassContainer(
      width: 180,
      height: double.infinity,
      radius: 10,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pages",
                  style: AppStyles.icon_text.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                single_circle_button(
                  LucideIcons.x,
                  20,
                  90,
                  "close",
                  widget.onClose,
                  context,
                  MediaQuery.of(context).size.width,
                  button_width: 35,
                  bgAlpha: 100,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: widget.numPages,
                itemBuilder: (context, index) {
                  final isSelected = _selectedPageIndex == index;
                  final cachedImage = widget.thumbnailCache[index];
                  final bgPath = widget.pageBackgrounds.length > index ? widget.pageBackgrounds[index] : null;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedPageIndex == index) {
                          _selectedPageIndex = null;
                        } else {
                          _selectedPageIndex = index;
                          widget.onPageTap?.call(index);
                        }
                      });
                    },
                    child: Container(
                      height: _thumbnailHeight,
                      width: 150,
                      margin: const EdgeInsets.only(bottom: _thumbnailSpacing),
                      decoration: BoxDecoration(
                        color: BG,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? accent : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _PagePreview(
                              // CHANGE: Key includes bgPath so Flutter destroys & rebuilds State on page swap/move
                              key: ValueKey('preview_${index}_${bgPath ?? 'blank'}'),
                              index: index,
                              pageWidth: widget.pageWidth,
                              basePageHeight: widget.basePageHeight,
                              paperType: widget.paperType,
                              backgroundPath: bgPath,
                              strokes: _strokesByPage[index] ?? const [],
                              images: _imagesByPage[index] ?? const [],
                              resolver: widget.resolvePageBackground,
                              loadBackground: _shouldLoadBackground(index),
                              cachedImage: cachedImage,
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BLACK.withAlpha(150),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: AppStyles.icon_text.copyWith(
                                    fontSize: 12,
                                    color: WHITE,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned.fill(
                                child: Container(
                                  color: BLACK.withAlpha(100),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (index > 0)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: single_circle_button(
                                            LucideIcons.chevron_up,
                                            25,
                                            90,
                                            "move up",
                                                () => _handleMove(index, -1),
                                            context,
                                            MediaQuery.of(context).size.width,
                                            button_width: 50,
                                            bgAlpha: 200,
                                          ),
                                        ),
                                      if (index < widget.numPages - 1)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: single_circle_button(
                                            LucideIcons.chevron_down,
                                            25,
                                            90,
                                            "move down",
                                                () => _handleMove(index, 1),
                                            context,
                                            MediaQuery.of(context).size.width,
                                            button_width: 50,
                                            bgAlpha: 200,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}

class _PagePreview extends StatefulWidget {
  final int index;
  final double pageWidth;
  final double basePageHeight;
  final String paperType;
  final String? backgroundPath;
  final List<Stroke> strokes;
  final List<ImageData> images;
  final PageBackgroundResolver? resolver;
  final bool loadBackground;
  final ui.Image? cachedImage;

  const _PagePreview({
    super.key,
    required this.loadBackground,
    required this.index,
    required this.pageWidth,
    required this.basePageHeight,
    required this.paperType,
    this.backgroundPath,
    required this.strokes,
    required this.images,
    this.resolver,
    this.cachedImage,
  });

  @override
  State<_PagePreview> createState() => _PagePreviewState();
}

class _PagePreviewState extends State<_PagePreview> {
  String? _resolvedPath;
  bool _resolving = false;
  FileImage? _fileImage;

  void _evict() {
    _fileImage?.evict();
    _fileImage = null;
  }

  @override
  void initState() {
    super.initState();
    _resolvedPath = widget.backgroundPath;

    if (widget.loadBackground &&
        _resolvedPath == null &&
        widget.resolver != null) {
      _resolve();
    }
    if (!widget.loadBackground) {
      _evict();
    }
  }

  @override
  void didUpdateWidget(covariant _PagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backgroundPath != oldWidget.backgroundPath) {
      _resolvedPath = widget.backgroundPath;
      _evict();
    }

    if (!widget.loadBackground && oldWidget.loadBackground) {
      _evict();
    }

    if (widget.loadBackground &&
        !oldWidget.loadBackground &&
        _resolvedPath == null &&
        widget.resolver != null) {
      _resolve();
    }
  }

  @override
  void dispose() {
    _evict();
    super.dispose();
  }

  Future<void> _resolve() async {
    if (_resolving) return;
    _resolving = true;
    try {
      final path = await widget.resolver!(widget.index);
      if (mounted) {
        setState(() {
          _resolvedPath = path;
        });
      }
    } finally {
      _resolving = false;
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final double yMin = widget.index * widget.basePageHeight;

    if (widget.loadBackground && _resolvedPath != null && _resolvedPath != "blank") {
      _fileImage ??= FileImage(File(_resolvedPath!));
    }

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        // 1. PDF Background
        if (widget.loadBackground && _fileImage != null)
          Image(
            image: _fileImage!,
            width: widget.pageWidth,
            height: widget.basePageHeight,
            fit: BoxFit.contain,
          ),
        // 2. Paper Type
        if (widget.paperType != "blank")
          CustomPaint(
            size: Size(widget.pageWidth, widget.basePageHeight),
            painter: PaperPainter(widget.paperType),
          ),

        // 3. Pre-rendered Strokes Bitmap
        if (widget.cachedImage != null)
          RawImage(
            image: widget.cachedImage,
            fit: BoxFit.contain,
            width: widget.pageWidth,
            height: widget.basePageHeight,
          ),

        // 2. Images (Always render over background)
        ...widget.images.map((img) => Positioned(
          left: img.position.dx,
          top: img.position.dy - yMin,
          width: img.width,
          height: img.height,
          child: Image.file(
            File(img.imagePath),
            fit: BoxFit.contain,
          ),
        )),

        // 3. Fallback Vector Strokes (Only if thumbnail bitmap is not ready)
        if (widget.cachedImage == null)
          CustomPaint(
            painter: HandwritingPainter(
              strokes: widget.strokes,
              currentStroke: null,
              backgroundColor: BG,
            ),
          ),
      ],
    );

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: widget.pageWidth,
        height: widget.basePageHeight,
        child: content,
      ),
    );
  }
}
