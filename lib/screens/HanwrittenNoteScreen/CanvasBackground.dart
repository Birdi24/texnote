import 'package:flutter/material.dart';
import '../../app_style.dart';

class CanvasBackground extends StatelessWidget {
  final int numPages;
  final double pageWidth;
  final double basePageHeight;

  const CanvasBackground({
    super.key,
    required this.numPages,
    required this.pageWidth,
    required this.basePageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            child: index > 0
                ? Align(
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
                  )
                : null,
          ),
        ),
    );
  }
}
