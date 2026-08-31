import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const WHITE = Colors.white;
const RED = Colors.red;
const BLACK = Colors.black;


class AppTheme {
  final Color bg;
  final Color text;
  final Color iconColor;
  final Color accent;
  final Color glassBg;
  final Color glassBorder;
  final Color glassShadow;
  final Color navSelected;

  const AppTheme({
    required this.bg,
    required this.text,
    required this.iconColor,
    required this.accent,
    required this.glassBg,
    required this.glassBorder,
    required this.glassShadow,
    required this.navSelected,
  });
}

class AppThemes {

  // Theme 1 — Default
  static const defaultTheme = AppTheme(
    bg: WHITE,
    text: Colors.black,
    iconColor: Colors.black,
    accent: Colors.black38,
    glassBg: Color.fromRGBO(255, 255, 255, 0.4),
    glassBorder: Color.fromRGBO(0, 0, 0, 0.1),
    glassShadow: Color.fromRGBO(0, 0, 0, 0.05),
    navSelected: Color.fromRGBO(0, 0, 0, 0.1),
  );

  // Theme 2 — Dark
  static const darkTheme = AppTheme(
    bg: Color(0xFF1E1E1E),
    text: WHITE,
    iconColor: WHITE,
    accent: Colors.white54,
    glassBg: Color.fromRGBO(255, 255, 255, 0.08),
    glassBorder: Color.fromRGBO(255, 255, 255, 0.15),
    glassShadow: Color.fromRGBO(0, 0, 0, 0.5),
    navSelected: Color.fromRGBO(255, 255, 255, 0.15),
  );

  // Theme 3 — Red
  static const redTheme = AppTheme(
    bg:  Color(0xFF7F1D1D),
    text: Color(0xFFFEF2F2),
    iconColor: Color(0xFFFFDEDE),
    accent: Color(0xFFF8475A),
    glassBg: Color.fromRGBO(255, 95, 95, 0.4),
    glassBorder: Color.fromRGBO(165, 28, 40, 0.2),
    glassShadow: Color.fromRGBO(165, 28, 40, 0.1),
    navSelected: Color.fromRGBO(165, 28, 40, 0.15),
  );

  // Theme 4 — Green
  static const greenTheme = AppTheme(
    bg:  Color(0xFF14532D),
    text: Color(0xFFF0FDF4),
    iconColor: Color(0xFFE0FFED),
    accent: Color(0xFF46C872),
    glassBg: Color.fromRGBO(85, 126, 84, 1.0),
    glassBorder: Color.fromRGBO(27, 81, 45, 0.2),
    glassShadow: Color.fromRGBO(27, 81, 45, 0.1),
    navSelected: Color.fromRGBO(27, 81, 45, 0.15),
  );

  // Theme 5 — Tokyo Night
  static const tokyoNightTheme = AppTheme(
    bg: Color(0xFF1A1B26),
    text: Color(0xFFA9B1D6),
    iconColor: Color(0xFFA9B1D6),
    accent: Color(0xFF9AA6F7),
    glassBg: Color.fromRGBO(42, 43, 62, 1.0),
    glassBorder: Color.fromRGBO(99, 102, 145, 1.0),
    glassShadow: Color.fromRGBO(0, 0, 0, 0.5),
    navSelected: Color.fromRGBO(71, 80, 110, 1.0),
  );

  // All five preset themes
  static const List<AppTheme> presets = [
    defaultTheme,
    darkTheme,
    redTheme,
    greenTheme,
    tokyoNightTheme,
  ];
}


// ============================================================
// THEME MANAGER
// ============================================================

class ThemeManager extends ChangeNotifier {

  AppTheme _theme = AppThemes.defaultTheme;

  int _selectedPreset = 0;

  // ----------------------------------------------------------
  // Getters
  // ----------------------------------------------------------

  AppTheme get theme => _theme;

  Color get bg => _theme.bg;
  Color get iconColor => _theme.iconColor;
  Color get accent => _theme.accent;

  int get selectedPreset => _selectedPreset;

  bool get isCustom => _selectedPreset == -1;


  // ----------------------------------------------------------
  // Load saved theme
  // ----------------------------------------------------------

  Future<void> loadTheme() async {

    final prefs = await SharedPreferences.getInstance();

    final themeType = prefs.getString('theme_type') ?? 'preset';

    // --------------------------------------------------------
    // Preset theme
    // --------------------------------------------------------

    if (themeType == 'preset') {

      final index = prefs.getInt('theme_index') ?? 0;

      if (index >= 0 && index < AppThemes.presets.length) {
        _selectedPreset = index;
        _theme = AppThemes.presets[index];
      } else {
        _selectedPreset = 0;
        _theme = AppThemes.defaultTheme;
      }
    }

    // --------------------------------------------------------
    // Custom theme
    // --------------------------------------------------------

    else if (themeType == 'custom') {

      final bgValue = prefs.getInt('custom_bg');
      final textValue = prefs.getInt('custom_text');
      final iconValue = prefs.getInt('custom_icon');
      final accentValue = prefs.getInt('custom_accent');

      if (
      bgValue != null &&
          textValue != null &&
          iconValue != null &&
          accentValue != null
      ) {
        final Color bg = Color(bgValue);
        final bool isDark = bg.computeLuminance() < 0.5;

        final glassBgValue = prefs.getInt('custom_glass_bg');
        final glassBorderValue = prefs.getInt('custom_glass_border');
        final glassShadowValue = prefs.getInt('custom_glass_shadow');
        final navSelectedValue = prefs.getInt('custom_nav_selected');

        _theme = AppTheme(
          bg: bg,
          text: Color(textValue),
          iconColor: Color(iconValue),
          accent: Color(accentValue),
          glassBg: glassBgValue != null ? Color(glassBgValue) : (isDark ? const Color.fromRGBO(255, 255, 255, 0.08) : const Color.fromRGBO(255, 255, 255, 0.4)),
          glassBorder: glassBorderValue != null ? Color(glassBorderValue) : (isDark ? const Color.fromRGBO(255, 255, 255, 0.15) : const Color.fromRGBO(0, 0, 0, 0.1)),
          glassShadow: glassShadowValue != null ? Color(glassShadowValue) : (isDark ? const Color.fromRGBO(0, 0, 0, 0.5) : const Color.fromRGBO(0, 0, 0, 0.05)),
          navSelected: navSelectedValue != null ? Color(navSelectedValue) : (isDark ? const Color.fromRGBO(255, 255, 255, 0.15) : const Color.fromRGBO(0, 0, 0, 0.1)),
        );

        _selectedPreset = -1;
      }
    }

    notifyListeners();
  }


  // ----------------------------------------------------------
  // Set preset theme
  // ----------------------------------------------------------

  Future<void> setPreset(int index) async {

    if (index < 0 || index >= AppThemes.presets.length) {
      return;
    }

    _theme = AppThemes.presets[index];
    _selectedPreset = index;
    applyTheme(_theme);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('theme_type', 'preset');
    await prefs.setInt('theme_index', index);
  }


  // ----------------------------------------------------------
  // Set custom theme
  // ----------------------------------------------------------

  Future<void> setCustomTheme({
    required Color bg,
    required Color text,
    required Color iconColor,
    required Color accent,
    Color? glassBg,
    Color? glassBorder,
    Color? glassShadow,
    Color? navSelected,
  }) async {

    final bool isDark = bg.computeLuminance() < 0.5;
    _theme = AppTheme(
      bg: bg,
      text: text,
      iconColor: iconColor,
      accent: accent,
      glassBg: glassBg ?? (isDark ? const Color.fromRGBO(255, 255, 255, 0.08) : const Color.fromRGBO(255, 255, 255, 0.4)),
      glassBorder: glassBorder ?? (isDark ? const Color.fromRGBO(255, 255, 255, 0.15) : const Color.fromRGBO(0, 0, 0, 0.1)),
      glassShadow: glassShadow ?? (isDark ? const Color.fromRGBO(0, 0, 0, 0.5) : const Color.fromRGBO(0, 0, 0, 0.05)),
      navSelected: navSelected ?? (isDark ? const Color.fromRGBO(255, 255, 255, 0.15) : const Color.fromRGBO(0, 0, 0, 0.1)),
    );

    _selectedPreset = -1;
    applyTheme(_theme);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('theme_type', 'custom');

    await prefs.setInt('custom_bg', bg.toARGB32());
    await prefs.setInt('custom_text', text.toARGB32());
    await prefs.setInt('custom_icon', iconColor.toARGB32());
    await prefs.setInt('custom_accent', accent.toARGB32());

    if (glassBg != null) await prefs.setInt('custom_glass_bg', glassBg.toARGB32());
    if (glassBorder != null) await prefs.setInt('custom_glass_border', glassBorder.toARGB32());
    if (glassShadow != null) await prefs.setInt('custom_glass_shadow', glassShadow.toARGB32());
    if (navSelected != null) await prefs.setInt('custom_nav_selected', navSelected.toARGB32());
  }

}

Color BG = AppThemes.defaultTheme.bg;
Color text = AppThemes.defaultTheme.text;
Color icon_color = AppThemes.defaultTheme.iconColor;
Color accent = AppThemes.defaultTheme.accent;
Color glass_bg = AppThemes.defaultTheme.glassBg;
Color glass_border = AppThemes.defaultTheme.glassBorder;
Color glass_shadow = AppThemes.defaultTheme.glassShadow;
Color nav_selected = AppThemes.defaultTheme.navSelected;


// ============================================================
// APPLY THEME
// ============================================================

void applyTheme(AppTheme theme) {

  BG = theme.bg;
  text = theme.text;
  icon_color = theme.iconColor;
  accent = theme.accent;
  glass_bg = theme.glassBg;
  glass_border = theme.glassBorder;
  glass_shadow = theme.glassShadow;
  nav_selected = theme.navSelected;
}


// ============================================================
// ADAPTIVE COLORS
// ============================================================

Color getAdaptiveStrokeColor(Color strokeColor, Color bgColor) {
  // Check saturation to see if the color belongs to the "white to black" spectrum.
  // Saturated colors like dark blues and light yellows will be preserved.
  final hsl = HSLColor.fromColor(strokeColor);
  if (hsl.saturation > 0.15) {
    return strokeColor;
  }

  final strokeLuminance = strokeColor.computeLuminance();
  final bgLuminance = bgColor.computeLuminance();

  // If the stroke color is very close to white and the background is light, flip to black
  if (strokeLuminance > 0.9 && bgLuminance > 0.5) {
    return BLACK;
  }
  
  // If the stroke color is very close to black and the background is dark, flip to white
  if (strokeLuminance < 0.1 && bgLuminance <= 0.5) {
    return WHITE;
  }

  return strokeColor;
}


// ============================================================
// COLLECTION COLORS
// ============================================================

Color collection_color(String s) {

  switch (s) {

    case "1":
      return const Color.fromRGBO(255, 190, 11, 1.0);

    case "2":
      return const Color.fromRGBO(251, 86, 7, 1.0);

    case "3":
      return const Color.fromRGBO(255, 0, 110, 1.0);

    case "4":
      return const Color.fromRGBO(6, 214, 160, 1.0);

    case "5":
      return const Color.fromRGBO(17, 138, 178, 1.0);

    case "6":
      return const Color.fromRGBO(225, 181, 172, 1.0);

    default:
      // If the string starts with #, remove it
      String hexColor = s.replaceAll('#', '');
      // If it's a 6-digit hex, add the opacity prefix (FF)
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
  }
}


// ============================================================
// APP STYLES
// ============================================================

class AppStyles {

  static TextStyle get title2 => GoogleFonts.tinos(
    fontSize: 20.0,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.8,
    color: text,
  );

  static TextStyle get bodytext => GoogleFonts.cantarell(
    fontSize: 14.0,
    color: text,
  );

  static TextStyle get icon_text => GoogleFonts.tinos(
    fontSize: 16.0,
    color: icon_color,
  );

  static TextStyle get timefont => TextStyle(
    fontSize: 12,
    color: accent,
  );


  // ----------------------------------------------------------
  // Material Theme
  // ----------------------------------------------------------

  static ThemeData get theme {

    return ThemeData(
      scaffoldBackgroundColor: BG,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: BG.computeLuminance() > 0.5
            ? Brightness.light
            : Brightness.dark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: BG,
        foregroundColor: icon_color,
        elevation: 0,
      ),

      iconTheme: IconThemeData(
        color: icon_color,
      ),

      textTheme: TextTheme(
        bodyMedium: bodytext,
      ),
    );
  }
}


// ============================================================
// MARKDOWN STYLE
// ============================================================

MarkdownStyleSheet markdown_style(double font_size) {

  return MarkdownStyleSheet(

    // Normal text
    p: AppStyles.bodytext.copyWith(
      fontSize: font_size,
    ),

    // Headings
    h1: AppStyles.bodytext.copyWith(
      fontSize: font_size * 1.8,
      fontWeight: FontWeight.bold,
    ),

    h2: AppStyles.bodytext.copyWith(
      fontSize: font_size * 1.5,
      fontWeight: FontWeight.bold,
    ),

    h3: AppStyles.bodytext.copyWith(
      fontSize: font_size * 1.3,
      fontWeight: FontWeight.bold,
    ),

    h4: AppStyles.bodytext.copyWith(
      fontSize: font_size * 1.15,
      fontWeight: FontWeight.bold,
    ),

    h5: AppStyles.bodytext.copyWith(
      fontSize: font_size * 1.05,
      fontWeight: FontWeight.bold,
    ),

    // Checkboxes
    checkbox: TextStyle(
      color: icon_color,
    ),

    // Inline code
    code: GoogleFonts.robotoMono(
      fontSize: font_size,
      color: text,
    ),

    // Fenced code blocks
    codeblockPadding: EdgeInsets.all(
      font_size * 0.8,
    ),

    codeblockDecoration: BoxDecoration(
      color: BG.computeLuminance() > 0.5
          ? Colors.grey.shade200
          : Colors.white.withAlpha(20),

      borderRadius: BorderRadius.circular(8),

      border: Border.all(
        color: icon_color.withAlpha(BG.computeLuminance() > 0.5 ? 30 : 60),
      ),
    ),

    // Lists
    listBullet: AppStyles.bodytext.copyWith(
      fontSize: font_size,
    ),

    // Links
    a: AppStyles.bodytext.copyWith(
      fontSize: font_size,
      color: BG.computeLuminance() > 0.5 ? Colors.blue : Colors.blueAccent,
      decoration: TextDecoration.underline,
    ),
  );
}