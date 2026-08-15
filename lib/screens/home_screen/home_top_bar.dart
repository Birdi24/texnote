
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_style.dart';
import 'home_nav_bar.dart';

Widget title(int control, _selectedCollection) {
  final text_src = ["Collections", "All Notes", "Favorites"];
  String text = text_src[control];
  if (_selectedCollection != null && control == 0) {text = "Collection: ${_selectedCollection.title}";}

  return IgnorePointer(child: Text(text, style: AppStyles.title ));
}

Widget top_left_cluster(int control, _selectedCollection, closeCollection, context, screen_width,) {
  bool in_collection = (_selectedCollection != null && control == 0);
  return Positioned(
    top: 15,
    left: 25,

    child: Align(
        alignment: Alignment.topLeft,
        child: Row(
            spacing: 10,
            children: [
              in_collection ?
                single_nav_button(Icons.arrow_back_ios_new, 20.0,90, "Back",closeCollection, context, screen_width, button_width: 45.0 )
                : SizedBox.shrink(),
              title(control,_selectedCollection)
            ]
        )
    ),
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

Widget top_right_button_cluster(Function() onNoteChanged, Function() onSortChanged, context, screen_width, Function() onSearchChanged, bool _isSearching) {
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

