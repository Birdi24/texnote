import 'package:flutter/material.dart';
import 'app_style.dart';
import 'screens/home_screen/main.dart';


void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tex",
      theme: AppStyles.theme,
      home: const HomeScreen(),
    );
  }
}