import 'package:flutter/material.dart';
import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/full_color_picker.dart';

class CanvasColorPickerOverlay extends StatelessWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;
  final VoidCallback onDismiss;

  const CanvasColorPickerOverlay({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return glassContainer(
      width: 250,
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: FullColorPicker(
                initialColor: initialColor,
                onColorChanged: onColorChanged,
              ),
            ),
            const SizedBox(height: 16),
            // Quick presets
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Colors.black,
                  Colors.white,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ].map((color) => GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onDismiss,
              child: Text(
                "Done",
                style: AppStyles.icon_text.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
