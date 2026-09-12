import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/single_circle_button.dart';

class PageListView extends StatefulWidget {
  final int numPages;
  final int currentPage;
  final Function(int index, int direction) onMovePage;
  final Function(int index) onAddPageBelow;
  final Function(int index) onDeletePage;
  final Function(int index) onPageTap;
  final VoidCallback onClose;

  const PageListView({
    super.key,
    required this.numPages,
    required this.currentPage,
    required this.onMovePage,
    required this.onAddPageBelow,
    required this.onDeletePage,
    required this.onPageTap,
    required this.onClose,
  });

  @override
  State<PageListView> createState() => _PageListViewState();
}

class _PageListViewState extends State<PageListView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Removed jumpTo logic as it might be causing crashes during initial layout
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return glassContainer(
      width: 240,
      height: double.infinity,
      radius: 10,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
              itemCount: widget.numPages,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (context, index) {
                final isCurrent = index == widget.currentPage;
                return Center(
                  child: Container(
                    width: 210,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      color: isCurrent ? accent.withAlpha(30) : Colors.transparent,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCurrent ? accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => widget.onPageTap(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Page ${index + 1}",
                                  style: AppStyles.icon_text.copyWith(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CompactAction(
                                    icon: LucideIcons.chevron_up, color: accent,
                                    onPressed: index > 0 ? () => widget.onMovePage(index, -1) : null,
                                  ),
                                  const SizedBox(width: 4),
                                  _CompactAction(
                                    icon: LucideIcons.chevron_down,color: accent,
                                    onPressed: index < widget.numPages - 1 ? () => widget.onMovePage(index, 1) : null,
                                  ),
                                  const SizedBox(width: 4),
                                  _CompactAction(
                                    icon: LucideIcons.file_plus, color: accent,
                                    onPressed: () => widget.onAddPageBelow(index),
                                  ),
                                  const SizedBox(width: 4),
                                  _CompactAction(
                                    icon: LucideIcons.trash, color: Colors.red,
                                    onPressed: widget.numPages > 1 ? () => _showDeleteConfirmation(context, index) : null,

                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Page", style: AppStyles.title2.copyWith(fontWeight: FontWeight.bold, fontSize: 24),),
        content: Text("Are you sure you want to delete Page ${index + 1}?\nThis will delete all content on this page."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              widget.onDeletePage(index);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _CompactAction({required this.icon, this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: color,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        splashRadius: 16,
      ),
    );
  }
}

