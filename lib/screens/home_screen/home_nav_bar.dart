import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/new_file_button.dart';
import '../../widgets/single_circle_button.dart';


Widget home_nav_bar(onNoteChanged, context, screen_width, control, onControlChanged, collections,notes,add_or_remove_favorite,selected_collection) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min,
        children: [
          glassContainer(
            width: (screen_width > 600) ? 300 : 0.7 * screen_width, height: (screen_width > 600) ?68 : 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(Icons.collections_bookmark_outlined, "Collections", control == 0, onControlChanged, 0),
                _buildNavButton(Icons.all_inclusive, "All", control == 1, onControlChanged, 1),
                _buildNavButton(Icons.star_outline, "Favorites", control == 2, onControlChanged, 2),
              ],
            ),
          ),

          const SizedBox(width: 8),

          single_circle_button(
            Icons.add, 34.0, 34, "Add",
            () async { new_file_options(context, onNoteChanged,collections, notes,control,add_or_remove_favorite,selected_collection);},
            context, screen_width, button_width: (screen_width > 600) ? 68 : 58,
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavButton(IconData icon, String label, bool selected, Function(int) function, int num) {
  return InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () {function(num);},
    child: Container(
      width: 70, height: 58,
      decoration: BoxDecoration(
        color: selected ? BG.withAlpha(200): Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: selected ? Border.all(color: BG.withAlpha(29)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: icon_color, size: 23,),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.cantarell(color: icon_color, fontSize: 11, fontWeight: FontWeight.w400,),
          ),
        ],
      ),
    ),
  );
}





