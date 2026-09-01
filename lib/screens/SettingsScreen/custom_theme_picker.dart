
import 'package:flutter/material.dart';
import 'package:texnote/widgets/color_picker.dart';

import '../../app_style.dart';

class CustomThemeScreen extends StatefulWidget {
final ThemeManager themeManager;

const CustomThemeScreen({
super.key,
required this.themeManager,
});

@override
State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  late Color _background;
  late Color _text;
  late Color _iconColor;
  late Color _accent;
  late Color _glassBg;
  late Color _glassBorder;
  late Color _glassShadow;
  late Color _navSelected;

  static final List<Color> _colorHistory = [];

ThemeManager get themeManager => widget.themeManager;

@override
void initState() {
super.initState();

final theme = themeManager.theme;

    _background = theme.bg;
    _text = theme.text;
    _iconColor = theme.iconColor;
    _accent = theme.accent;
    _glassBg = theme.glassBg;
    _glassBorder = theme.glassBorder;
    _glassShadow = theme.glassShadow;
    _navSelected = theme.navSelected;
}

String _hex(Color color) {
return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}

  Future<void> _pickColor({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onChanged,
  }) async {
    final result = await showDialog<Color>(
      context: context,
      builder: (context) {
        return _ColorPickerDialog(
          title: title,
          initialColor: currentColor,
          history: _colorHistory,
        );
      },
    );

    if (result != null) {
      if (!_colorHistory.contains(result)) {
        _colorHistory.insert(0, result);
        if (_colorHistory.length > 10) _colorHistory.removeLast();
      }
      onChanged(result);
      setState(() {});
    }
  }

Widget _colorOption({
required String title,
required String description,
required Color color,
required VoidCallback onTap,
}) {
return Material(
color: Colors.transparent,
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(18),
child: Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: BG,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: _iconColor,
),
),
child: Row(
children: [
Container(
width: 52,
height: 52,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: _iconColor,
),
),
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
color: _text,
fontSize: 16,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 3),

Text(
description,
style: TextStyle(
color: _iconColor,
fontSize: 12,
),
),

const SizedBox(height: 4),

Text(
_hex(color),
style: TextStyle(
color: _accent,
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
],
),
),

Icon(
Icons.chevron_right,
color: _iconColor,
),
],
),
),
),
);
}

  Widget _preview() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _iconColor,
        ),
        boxShadow: [
          BoxShadow(
            color: _glassShadow,
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                color: _iconColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Texnote',
                style: TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.star_rounded,
                color: _accent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'My Notes',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This is a preview of your custom theme.',
            style: TextStyle(
              color: _text,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _glassBorder),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _navSelected,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.home_filled, color: _iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    await themeManager.setCustomTheme(
      bg: _background,
      text: _text,
      iconColor: _iconColor,
      accent: _accent,
      glassBg: _glassBg,
      glassBorder: _glassBorder,
      glassShadow: _glassShadow,
      navSelected: _navSelected,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: _background,

body: SafeArea(
child: Column(
children: [
// =====================================================
// HEADER
// =====================================================

Padding(
padding: const EdgeInsets.fromLTRB(
8,
12,
20,
12,
),
child: Row(
children: [
IconButton(
icon: Icon(
Icons.arrow_back,
color: _iconColor,
),
onPressed: () {
Navigator.pop(context);
},
),

const SizedBox(width: 8),

Expanded(
child: Text(
'Custom Theme',
style: TextStyle(
color: _iconColor,
fontSize: 24,
fontWeight: FontWeight.w600,
),
),
),
],
),
),

// =====================================================
// CONTENT
// =====================================================

Expanded(
child: ListView(
padding: const EdgeInsets.fromLTRB(
20,
8,
20,
30,
),
children: [
Text(
'Preview',
style: TextStyle(
color: _accent,
fontSize: 15,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 12),

_preview(),

const SizedBox(height: 28),

Text(
'Colors',
style: TextStyle(
color: _accent,
fontSize: 15,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 12),

_colorOption(
title: 'Background',
description: 'Main app background',
color: BG,
onTap: () {
_pickColor(
title: 'Background',
currentColor: _background,
onChanged: (color) {
_background = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Text',
description: 'Primary text throughout the app',
color: _text,
onTap: () {
_pickColor(
title: 'Text',
currentColor: _text,
onChanged: (color) {
_text = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Icons',
description: 'Icons and secondary UI elements',
color: _iconColor,
onTap: () {
_pickColor(
title: 'Icons',
currentColor: _iconColor,
onChanged: (color) {
_iconColor = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Accent',
description: 'Highlights, buttons and selections',
color: _accent,
onTap: () {
_pickColor(
title: 'Accent',
currentColor: _accent,
onChanged: (color) {
_accent = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Glass Background',
description: 'Translucent background for containers',
color: _glassBg,
onTap: () {
_pickColor(
title: 'Glass Background',
currentColor: _glassBg,
onChanged: (color) {
_glassBg = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Glass Border',
description: 'Subtle borders for glass elements',
color: _glassBorder,
onTap: () {
_pickColor(
title: 'Glass Border',
currentColor: _glassBorder,
onChanged: (color) {
_glassBorder = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Glass Shadow',
description: 'Elevation shadows for containers',
color: _glassShadow,
onTap: () {
_pickColor(
title: 'Glass Shadow',
currentColor: _glassShadow,
onChanged: (color) {
_glassShadow = color;
},
);
},
),

const SizedBox(height: 10),

_colorOption(
title: 'Home Button',
description: 'Selected state for navigation items',
color: _navSelected,
onTap: () {
_pickColor(
title: 'Home Button',
currentColor: _navSelected,
onChanged: (color) {
_navSelected = color;
},
);
},
),

const SizedBox(height: 28),

SizedBox(
height: 52,
width: double.infinity,
child: ElevatedButton(
onPressed: _apply,
style: ElevatedButton.styleFrom(
backgroundColor: _accent,
foregroundColor: _background,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
),
child: const Text(
'Apply Theme',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w600,
),
),
),
),
],
),
),
],
),
),
);
}
}

// =================================================================
// COLOR PICKER DIALOG
// =================================================================

class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initialColor;
  final List<Color> history;

  const _ColorPickerDialog({
    required this.title,
    required this.initialColor,
    required this.history,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BG,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.title,
        style: AppStyles.bodytext.copyWith(
          color: icon_color,
        ),
      ),
      content: SingleChildScrollView(child:SizedBox(
        height: 420,
        width: 300,
        child: ColorPicker(
          initialColor: widget.initialColor,
          history: widget.history,
          showFullPicker: true,
          onColorChanged: (color, identifier) {
            selectedColor = color;
          },
        ),
      ),),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: icon_color)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: Text('Apply', style: TextStyle(color: icon_color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

