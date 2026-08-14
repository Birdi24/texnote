
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_style.dart';
import 'home_nav_bar.dart';

Widget title(int control) {
  final text = ["Collections", "All Notes", "Favorites"];
  return Positioned(
      top: 10,
      left: 25,
      right: 15,
      child: IgnorePointer(child: Text(text[control], style: AppStyles.title ),)
  );
}

Widget bg_gradient(){
  return Positioned(
    left: 0,
    right: 0,
    top: 20,
    child: IgnorePointer(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BG,
              BG.withAlpha(0),
            ],
            stops: const [0.6, 1.0],
          ),
        ),
      ),
    ),
  );
}

Widget top_button_cluster(Function() onNoteChanged, Function() onSortChanged, context, screen_width, Function() onSearchChanged, bool _isSearching) {
  return

    Positioned(
      top: 15,
      right: 15,

      child: Align(
          alignment: Alignment.topRight,
          child: Row(
              spacing: 8,
              children: [
                single_nav_button(Icons.search, 20.0,90, "Sort", onSearchChanged, context, screen_width, button_width: 45.0 ),
                single_nav_button(Icons.sort_sharp, 20.0,90, "Sort", onSortChanged, context, screen_width, button_width: 45.0 ),
                single_nav_button(Icons.more_horiz, 20.0,90, "settings", onNoteChanged, context, screen_width, button_width: 45.0 ),
              ]
          )
      ),
    );
}

