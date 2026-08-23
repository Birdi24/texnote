import 'package:flutter/material.dart';
import 'glass_container.dart';

class FullColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const FullColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<FullColorPicker> createState() => _FullColorPickerState();
}

class _FullColorPickerState extends State<FullColorPicker> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  void _updateColor(HSVColor color) {
    setState(() {
      _hsvColor = color;
    });
    widget.onColorChanged(color.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SV Picker
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  final x = details.localPosition.dx.clamp(0.0, constraints.maxWidth);
                  final y = details.localPosition.dy.clamp(0.0, constraints.maxHeight);
                  _updateColor(_hsvColor.withSaturation(x / constraints.maxWidth).withValue(1.0 - (y / constraints.maxHeight)));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      // Base Hue Color
                      Positioned.fill(
                        child: Container(
                          color: HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor(),
                        ),
                      ),
                      // Saturation Gradient (White to Transparent)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.white, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      // Value Gradient (Transparent to Black)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                            ),
                          ),
                        ),
                      ),
                      // Selector handle
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SVPainter(_hsvColor.saturation, _hsvColor.value),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Hue Slider
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                for (var i = 0; i <= 360; i += 60)
                  HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, 1.0).toColor(),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  final x = details.localPosition.dx.clamp(0.0, constraints.maxWidth);
                  _updateColor(_hsvColor.withHue((x / constraints.maxWidth) * 360));
                },
                child: CustomPaint(
                  painter: _HuePainter(_hsvColor.hue / 360),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SVPainter extends CustomPainter {
  final double s;
  final double v;

  _SVPainter(this.s, this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final pos = Offset(s * size.width, (1.0 - v) * size.height);
    
    canvas.drawCircle(pos, 6, shadowPaint);
    canvas.drawCircle(pos, 6, paint);
  }

  @override
  bool shouldRepaint(_SVPainter oldDelegate) => oldDelegate.s != s || oldDelegate.v != v;
}

class _HuePainter extends CustomPainter {
  final double huePercent;

  _HuePainter(this.huePercent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final x = huePercent * size.width;
    final rect = Rect.fromCenter(center: Offset(x, size.height / 2), width: 4, height: size.height + 4);
    
    canvas.drawRect(rect, shadowPaint);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_HuePainter oldDelegate) => oldDelegate.huePercent != huePercent;
}
