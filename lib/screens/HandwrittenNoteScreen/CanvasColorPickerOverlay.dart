import 'package:flutter/material.dart';
import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/color_picker.dart';

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
      width: 205,
      height: 332,
      radius: 25,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: NoteColorPicker(
                initialColor: initialColor,
                onColorChanged: (color) {
                  onColorChanged(color);
                },
              ),
            ),

          ],
        ),
      )
    );
  }
}
