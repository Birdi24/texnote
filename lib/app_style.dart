import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

const BG =  Colors.white;
const text = Colors.black;
const dividers = Color.fromRGBO(253, 240, 213, 1.0);
const icon_color = Colors.black;
const accent = Colors.black12;

Color collection_color(String s) {
  switch (s) {
    case "1": return Color.fromRGBO(255, 190, 11, 1.0);
    case "2": return Color.fromRGBO(251, 86, 7, 1.0);
    case "3": return Color.fromRGBO(255, 0, 110, 1.0);
    case "4": return Color.fromRGBO(6, 214, 160, 1.0);
    case "5": return Color.fromRGBO(17, 138, 178, 1.0);
    case "6": return Color.fromRGBO(253, 240, 213, 1.0);

    default: return icon_color;
  }

}

class AppStyles {
  static ThemeData theme = ThemeData(
    textTheme: GoogleFonts.ibmPlexSansTextTheme(),
    scaffoldBackgroundColor: BG,

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 3,
      toolbarHeight: 50.0,
      foregroundColor: text,
      backgroundColor: BG
    ),

  );

  static  TextStyle title = GoogleFonts.tinos(
      fontSize: 37.0,
      letterSpacing: .8,
      color: text,
      fontWeight: FontWeight.w500,
  );
  static TextStyle title2 = GoogleFonts.tinos(
    fontSize: 20.0,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.8,
    color: text
  );
  static TextStyle subtitle = GoogleFonts.tinos(
      fontSize: 16.0,
      letterSpacing: 1.2,
      color: text
  );

  static TextStyle bodytext = GoogleFonts.tinos(
      fontSize: 14.0,
      color: text
  );
  static TextStyle icon_text = GoogleFonts.tinos(
      fontSize: 16.0,
      color: icon_color
  );
  static TextStyle red_text = GoogleFonts.tinos(
      fontSize: 14.0,
      color: Colors.red
  );
  static TextStyle timefont = GoogleFonts.tinos(
    fontSize: 12,
    color: Color.fromRGBO(70, 70, 70, 1),
  );
}

MarkdownStyleSheet markdown_style(font_size){
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
    checkbox: TextStyle(color: icon_color),

    // Inline code: `example`
    code: GoogleFonts.robotoMono(
      fontSize: font_size,
    ),

    // Fenced code blocks: ``` ... ```
    codeblockPadding: EdgeInsets.all(font_size * 0.8),
    codeblockDecoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.black12,
      ),
    ),

    // Lists
    listBullet: AppStyles.bodytext.copyWith(
      fontSize: font_size,
    ),

    // Links
    a: AppStyles.bodytext.copyWith(
      fontSize: font_size,
      color: Colors.blue,
      decoration: TextDecoration.underline,
    ),
  );
}
