import 'package:flutter/material.dart';
import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import 'canvas_transformation_controller.dart';

class CanvasScrollbar extends StatelessWidget {
  final CanvasTransformationController transformationController;
  final int numPages;
  final double pageWidth;
  final double pageHeight;
  final double basePageHeight;
  final double safeHeight;
  final Size viewportSize;

  const CanvasScrollbar({
    super.key,
    required this.transformationController,
    required this.numPages,
    required this.pageWidth,
    required this.pageHeight,
    required this.basePageHeight,
    required this.safeHeight,
    required this.viewportSize,
  });

  @override
  Widget build(BuildContext context) {
    if (numPages <= 1) return const SizedBox.shrink();

    // Calculate current page based on viewport center
    final currentScale = transformationController.scale;
    final totalScaledHeight = pageHeight * currentScale;
    final viewportCenterY = -transformationController.offset.dy + safeHeight / 2;
    final currentPage = (viewportCenterY / (basePageHeight * currentScale))
            .floor()
            .clamp(0, numPages - 1) +
        1;

    const double handleHeight = 30.0;
    const double topMargin = handleHeight;
    const double bottomMargin = 30.0;
    final double trackHeight = safeHeight - topMargin - bottomMargin;
    double scrollbarHandleY = 0;

    if (totalScaledHeight > safeHeight) {
      final scrollableRange = totalScaledHeight - safeHeight;
      final scrollProgress =
          (-transformationController.offset.dy) / scrollableRange;
      scrollbarHandleY = (scrollProgress * (trackHeight - handleHeight))
          .clamp(0, trackHeight - handleHeight);
    }

    return Positioned(
      right: 10,
      top: topMargin,
      bottom: bottomMargin,
      width: 60,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackHeight = constraints.maxHeight;

          double scrollbarHandleY = 0;
          if (totalScaledHeight > safeHeight) {
            final scrollableRange = totalScaledHeight - safeHeight;
            final scrollProgress =
                (-transformationController.offset.dy) / scrollableRange;
            scrollbarHandleY = (scrollProgress * (trackHeight - handleHeight))
                .clamp(0, trackHeight - handleHeight);
          }

          void handleScroll(Offset localPosition) {
            final totalScaledHeight =
                pageHeight * transformationController.scale;
            final scrollableRange = totalScaledHeight - safeHeight;
            if (scrollableRange <= 0) return;

            // Map finger position to handle top position within the track
            final handleTop = (localPosition.dy - handleHeight / 2)
                .clamp(0.0, trackHeight - handleHeight);
            final scrollProgress = handleTop / (trackHeight - handleHeight);
            final targetScroll = scrollProgress * scrollableRange;

            transformationController.setOffset(
              Offset(transformationController.offset.dx, -targetScroll),
              viewportSize,
              pageWidth,
              pageHeight,
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) => handleScroll(details.localPosition),
            onVerticalDragUpdate: (details) =>
                handleScroll(details.localPosition),
            child: Stack(
              children: [
                Positioned(
                  top: scrollbarHandleY,
                  right: 0,
                  child: glassContainer(
                    width: 50,
                    height: handleHeight,
                    radius: 12,
                    child: Center(
                      child: Text(
                        "$currentPage",
                        style: AppStyles.icon_text.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
