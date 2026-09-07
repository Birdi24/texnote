import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/single_circle_button.dart';

class PageListView extends StatelessWidget {
  final int numPages;
  final int currentPage;
  final Function(int index, int direction) onMovePage;
  final Function(int index) onAddPageBelow;
  final Function(int index) onPageTap;
  final VoidCallback onClose;

  const PageListView({
    super.key,
    required this.numPages,
    required this.currentPage,
    required this.onMovePage,
    required this.onAddPageBelow,
    required this.onPageTap,
    required this.onClose,
  });

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
                  onClose,
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
              itemCount: numPages,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (context, index) {
                final isCurrent = index == currentPage;
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
                        onTap: () => onPageTap(index),
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
                                    icon: LucideIcons.chevron_up,
                                    onPressed: index > 0 ? () => onMovePage(index, -1) : null,
                                  ),
                                  const SizedBox(width: 4),
                                  _CompactAction(
                                    icon: LucideIcons.chevron_down,
                                    onPressed: index < numPages - 1 ? () => onMovePage(index, 1) : null,
                                  ),
                                  const SizedBox(width: 4),
                                  _CompactAction(
                                    icon: LucideIcons.file_plus,
                                    onPressed: () => onAddPageBelow(index),
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
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CompactAction({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        splashRadius: 16,
      ),
    );
  }
}

