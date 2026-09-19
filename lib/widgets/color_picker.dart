import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../app_style.dart';
import 'glass_container.dart';

/// The core color picker component with SV box, Hue slider, and Hex input.
class FullColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color color) onColorChanged;

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
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _colorToHex(_hsvColor.toColor()));
  }

  @override
  void didUpdateWidget(FullColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _hsvColor = HSVColor.fromColor(widget.initialColor);
      _hexController.text = _colorToHex(_hsvColor.toColor());
    }
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  void _updateColor(HSVColor color, {bool updateHex = true}) {
    setState(() {
      _hsvColor = color;
      if (updateHex) {
        _hexController.text = _colorToHex(color.toColor());
      }
    });
    widget.onColorChanged(color.toColor());
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
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hsvColor.toColor(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: icon_color.withValues(alpha: 0.2)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: icon_color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: icon_color.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Text("#", style: TextStyle(color: icon_color.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        onChanged: _handleHexInput,
                        style: TextStyle(color: icon_color, fontWeight: FontWeight.w600, fontSize: 13),
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
        // SV Box Spectrum
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanDown: (details) {
                  final x = details.localPosition.dx.clamp(0.0, constraints.maxWidth);
                  final y = details.localPosition.dy.clamp(0.0, constraints.maxHeight);
                  _updateColor(HSVColor.fromAHSV(
                    1.0,
                    _hsvColor.hue,
                    x / constraints.maxWidth,
                    1.0 - (y / constraints.maxHeight),
                  ));
                },
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
        // Hue Slider
        Container(
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
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
                onPanDown: (details) {
                  final x = details.localPosition.dx.clamp(0.0, constraints.maxWidth);
                  _updateColor(_hsvColor.withHue((x / constraints.maxWidth) * 360));
                },
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

/// Color picker for Note Screens - Always shows the full picker logic, but also includes standard presets.
class NoteColorPicker extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;
  final List<Color>? history;
  final List<String> presets;

  const NoteColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.history,
    this.presets = const ["1", "2", "3", "4", "5", "6"],
  });

  @override
  State<NoteColorPicker> createState() => _NoteColorPickerState();
}

class _NoteColorPickerState extends State<NoteColorPicker> {
  late Color _currentColor;
  String? _selectedIdentifier;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _selectedIdentifier = _findIdentifier(_currentColor);
  }

  @override
  void didUpdateWidget(NoteColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _currentColor = widget.initialColor;
      _selectedIdentifier = _findIdentifier(_currentColor);
    }
  }

  String? _findIdentifier(Color color) {
    for (var id in widget.presets) {
      if (collection_color(id).toARGB32() == color.toARGB32()) return id;
    }
    return null;
  }

  void _updateColor(Color color, {String? identifier}) {
    setState(() {
      _currentColor = color;
      _selectedIdentifier = identifier ?? _findIdentifier(color);
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FullColorPicker(
          initialColor: _currentColor,
          onColorChanged: (color) {
            setState(() {
              _currentColor = color;
              _selectedIdentifier = _findIdentifier(color);
            });
            widget.onColorChanged(color);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: widget.presets.map((id) {
            final color = collection_color(id);
            final selected = _selectedIdentifier == id;
            return GestureDetector(
              onTap: () => _updateColor(color, identifier: id),
              child: Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
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
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = widget.history![index];
                return GestureDetector(
                  onTap: () => _updateColor(color),
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
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

/// Color picker for Home Screen - Shows presets and a "plus" button for custom colors.
class HomeColorPicker extends StatefulWidget {
  final dynamic initialColor; // Can be Color or String identifier
  final Function(Color color, String? identifier) onColorChanged;
  final List<String> presets;
  final double? width;

  const HomeColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.presets = const ["1", "2", "3", "4", "5", "6"],
    this.width,
  });

  @override
  State<HomeColorPicker> createState() => _HomeColorPickerState();
}

class _HomeColorPickerState extends State<HomeColorPicker> {
  Color? _currentColor;
  String? _selectedIdentifier;

  @override
  void initState() {
    super.initState();
    _initColor();
  }

  void _initColor() {
    if (widget.initialColor is String) {
      _selectedIdentifier = widget.initialColor;
      _currentColor = collection_color(_selectedIdentifier!);
    } else if (widget.initialColor is Color) {
      _currentColor = widget.initialColor;
      _selectedIdentifier = _findIdentifier(widget.initialColor);
    } else {
      _currentColor = Colors.black;
    }
  }

  String? _findIdentifier(Color color) {
    for (var id in widget.presets) {
      if (collection_color(id).toARGB32() == color.toARGB32()) return id;
    }
    return null;
  }

  void _updateColor(Color color, {String? identifier}) {
    setState(() {
      _currentColor = color;
      _selectedIdentifier = identifier ?? _findIdentifier(color);
    });
    widget.onColorChanged(color, _selectedIdentifier);
  }

  void _showCustomColorPopup() {
    double screenWidth = MediaQuery.of(context).size.width;
    Color tempColor = _currentColor ?? Colors.black;

    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: BG.withAlpha(140),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          clipBehavior: Clip.antiAlias,
          child: glassContainer(
            bgAlpha: 30,
            borderAlpha: 244,
            borderColor: tempColor,
            color: BG,
            radius: 32,
            height: 490,
            width: screenWidth > 380 ? 310 : screenWidth - 70,
            shadowColor: BG,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Custom Color",
                    style: TextStyle(color: icon_color, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FullColorPicker(
                    initialColor: tempColor,
                    onColorChanged: (color) {
                      tempColor = color;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: icon_color)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _updateColor(tempColor);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: tempColor),
                        child: Text("Select", style: TextStyle(color: WHITE, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ...widget.presets.map((id) {
            final color = collection_color(id);
            final selected = _selectedIdentifier == id;
            return GestureDetector(
              onTap: () => _updateColor(color, identifier: id),
              child: Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected ? icon_color : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
            );
          }).toList(),
          // Custom Plus Button
          GestureDetector(
            onTap: _showCustomColorPopup,
            child: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: _selectedIdentifier == null ? _currentColor : icon_color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _selectedIdentifier == null ? icon_color : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Icon(
                LucideIcons.plus,
                size: 16,
                color: _selectedIdentifier == null ? Colors.white : icon_color,
              ),
            ),
          ),
        ],
      ),
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
