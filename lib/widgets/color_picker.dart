import 'package:flutter/material.dart';
import '../app_style.dart';

class ColorPicker extends StatefulWidget {
  final dynamic initialColor; // Can be Color or String identifier
  final Function(Color color, String? identifier) onColorChanged;
  final bool showFullPicker;
  final List<Color>? history;
  final List<String> presets;

  const ColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.showFullPicker = true,
    this.history,
    this.presets = const ["1", "2", "3", "4", "5", "6"],
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;
  String? _selectedIdentifier;

  @override
  void initState() {
    super.initState();
    _initColor();
    _hexController = TextEditingController(text: _colorToHex(_hsvColor.toColor()));
  }

  void _initColor() {
    if (widget.initialColor is String) {
      _selectedIdentifier = widget.initialColor;
      _hsvColor = HSVColor.fromColor(collection_color(_selectedIdentifier!));
    } else if (widget.initialColor is Color) {
      _hsvColor = HSVColor.fromColor(widget.initialColor);
      _selectedIdentifier = _findIdentifier(widget.initialColor);
    } else {
      _hsvColor = HSVColor.fromColor(Colors.black);
    }
  }

  String? _findIdentifier(Color color) {
    for (var id in widget.presets) {
      if (collection_color(id).value == color.value) return id;
    }
    return null;
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  void _updateColor(HSVColor color, {String? identifier, bool updateHex = true}) {
    setState(() {
      _hsvColor = color;
      _selectedIdentifier = identifier ?? _findIdentifier(color.toColor());
      if (updateHex) {
        _hexController.text = _colorToHex(color.toColor());
      }
    });
    widget.onColorChanged(color.toColor(), _selectedIdentifier);
  }

  void _handleHexInput(String input) {
    String hex = input.replaceAll('#', '');
    if (hex.length == 6) {
      try {
        final color = Color(int.parse("FF$hex", radix: 16));
        _updateColor(HSVColor.fromColor(color), updateHex: false);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showFullPicker) ...[
          AspectRatio(
            aspectRatio: 1.5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    final x = details.localPosition.dx.clamp(0.0, constraints.maxWidth);
                    final y = details.localPosition.dy.clamp(0.0, constraints.maxHeight);
                    _updateColor(HSVColor.fromAHSV(
                      1.0,
                      _hsvColor.hue,
                      x / constraints.maxWidth,
                      1.0 - (y / constraints.maxHeight),
                    ));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor(),
                          ),
                        ),
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
          const SizedBox(height: 16),
        ],
        // Hex Field
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hsvColor.toColor(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: icon_color.withOpacity(0.2)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: icon_color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: icon_color.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Text("#", style: TextStyle(color: icon_color.withOpacity(0.5), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        onChanged: _handleHexInput,
                        style: TextStyle(color: icon_color, fontWeight: FontWeight.w600, fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Presets Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.presets.map((id) {
            final color = collection_color(id);
            final selected = _selectedIdentifier == id;
            return GestureDetector(
              onTap: () => _updateColor(HSVColor.fromColor(color), identifier: id),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? icon_color : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (widget.history != null && widget.history!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text("Recent", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: icon_color.withAlpha(160))),
          const SizedBox(height: 8),
          SizedBox(
            height: 35,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.history!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = widget.history![index];
                return GestureDetector(
                  onTap: () => _updateColor(HSVColor.fromColor(color)),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
