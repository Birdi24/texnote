import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:birdwrite/screens/SettingsScreen/main.dart';

import '../../app_style.dart';
import '../../models/Note.dart';
import '../../widgets/single_circle_button.dart';
import '../../models/folder.dart';

/// displays what subsection of the HomeScreen is being viewed
Widget title(int control, Folder? selectedFolder) {
  final textSrc = ["PDFs", "Notes", "Favorites"];
  String text = textSrc[control];
  
  if (control == 1 && selectedFolder != null) {
    text = selectedFolder.title;
    if (text.length > 15) {
      text = "${text.substring(0, 12)}...";
    }
  }

  return IgnorePointer(
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.tinos(
        fontSize: 37.0,
        letterSpacing: .8,
        color: icon_color,
        fontWeight: FontWeight.w500,
      )
    )
  );
}

/// Widget that houses the title and back button when inside a folder
Widget top_left_cluster(int control, Folder? selectedFolder, VoidCallback closeFolder, BuildContext context, double screenWidth) {
  bool inFolder = (control == 1 && selectedFolder != null);

  // Width calculation for title positioning
  bool showSearch = true; // Always show search for now, or refine based on control
  double rightClusterWidth = 15 + (showSearch ? 3 : 2) * 45 + (showSearch ? 2 : 1) * 8;

  return Positioned(
    top: 16,
    left: 15,
    right: rightClusterWidth + 5,
    child: Align(
      alignment: Alignment.topLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (inFolder)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: single_circle_button(Icons.arrow_back_ios_new, 20.0, 90, "Back", closeFolder, context, screenWidth, button_width: 45.0),
            ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: title(control, selectedFolder),
            )
          )
        ]
      )
    ),
  );
}

/// A gradient below the top of the Home Screen to give the illusion of the title floating
Widget bg_gradient(){
  return Positioned(
    left: 0, right: 0, top: 20,
    child: IgnorePointer(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BG, BG.withAlpha(0)],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    ),
  );
}

/// Widget that houses the search, sort and themes button
Widget top_right_button_cluster(int control, bool inFolder, Future<void> Function([Note?]) onNoteChanged, Function() onSortChanged, BuildContext context, double screenWidth, Function() onSearchChanged, bool isSearching, themeManager) {
  return Positioned(
    top: 20,
    right: 15,
    child: Align(
      alignment: Alignment.topRight,
      child: Row(
        children: [
          single_circle_button(LucideIcons.search, 20.0, 90, "Search", onSearchChanged, context, screenWidth, button_width: 45.0),
          const SizedBox(width: 8),
          single_circle_button(Icons.sort_sharp, 20.0, 90, "Sort", onSortChanged, context, screenWidth, button_width: 45.0),
          const SizedBox(width: 8),
          single_circle_button(LucideIcons.palette, 20.0, 90, "Themes", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  themeManager: themeManager,
                ),
              ),
            );
          }, context, screenWidth, button_width: 45.0),
        ]
      )
    ),
  );
}
