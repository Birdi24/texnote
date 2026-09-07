
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:birdwrite/screens/SettingsScreen/main.dart';

import '../../app_style.dart';
import '../../widgets/single_circle_button.dart';

/// displays what subsection of the HomeScreen is being viewed, clicking it means nothing
Widget title(int control, _selectedCollection) {
  final text_src = ["Collections", "All Notes", "Favorites"];
  String text = text_src[control];
  if (_selectedCollection != null && control == 0) {text = _selectedCollection.title; if (text.length >15) {text = text.substring(0,12) + "...";}}

  return IgnorePointer(child: Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.tinos(
      fontSize: 37.0,
      letterSpacing: .8,
      color: icon_color,
      fontWeight: FontWeight.w500,
    )
  ));
}

/// Widget that houses the title [and back button when inside a collection]
Widget top_left_cluster(int control, _selectedCollection, closeCollection, context, screen_width,) {
  bool in_collection = (_selectedCollection != null && control == 0);

  bool showSearch = (control != 0 || in_collection);
  double rightClusterWidth = 15 + (showSearch ? 3 : 2) * 45 + (showSearch ? 2 : 1) * 8;

  return Positioned(
    top: 16,
    left: 15,
    right: rightClusterWidth + 5,

    child: Align(
        alignment: Alignment.topLeft,
        child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              if (in_collection)
                Padding(padding: EdgeInsetsGeometry.only(top: 4) ,child: single_circle_button(Icons.arrow_back_ios_new, 20.0,90, "Back",closeCollection, context, screen_width, button_width: 45.0 ),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: title(control,_selectedCollection),
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
Widget top_right_button_cluster(control, _inCollection,Function() onNoteChanged, Function() onSortChanged, context, screen_width, Function() onSearchChanged, bool _isSearching, themeManager) {
  return

    Positioned(
      top: 20,
      right: 15,

      child: Align(
          alignment: Alignment.topRight,
          child: Row(
              spacing: 8,
              children: [
                (control != 0 || _inCollection) ? single_circle_button(LucideIcons.search, 20.0,90, "Search", onSearchChanged, context, screen_width, button_width: 45.0 ) : SizedBox.shrink(),
                single_circle_button(Icons.sort_sharp, 20.0,90, "Sort", onSortChanged, context, screen_width, button_width: 45.0 ),
                single_circle_button(LucideIcons.palette, 20.0,90, "Themes", () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        themeManager: themeManager,
                      ),
                    ),
                  );
                }, context, screen_width, button_width: 45.0 ),
              ]
          )
      ),
    );
}

