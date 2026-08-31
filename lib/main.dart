import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'app_style.dart';
import 'screens/HomeScreen/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeManager = ThemeManager();

  await themeManager.loadTheme();

  runApp(
    NotesApp(
      themeManager: themeManager,
    ),
  );
}

class NotesApp extends StatelessWidget {
  final ThemeManager themeManager;

  const NotesApp({
    super.key,
    required this.themeManager,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeManager,

      builder: (context, child) {
        // Keep your existing global variables updated.
        applyTheme(themeManager.theme);

        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: AppStyles.theme,

          // Your existing localization setup
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('en'),
          ],

          home: HomeScreen(
            themeManager: themeManager,
          ),
        );
      },
    );
  }
}