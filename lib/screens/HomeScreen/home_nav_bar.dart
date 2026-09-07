import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_style.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/new_file_button.dart';
import '../../widgets/single_circle_button.dart';

/// This has 4 buttons: Collections, All, Favorites, Add
/// They are aligned bottom center
Widget home_nav_bar(onNoteChanged, context, screen_width, control, onControlChanged, collections,notes,add_or_remove_favorite,selected_collection) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: EdgeInsets.only(
        bottom:10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glassContainer(
            width: (screen_width > 600) ? 300 : 0.75 * screen_width, height: (screen_width > 600) ? 68 : 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (screen_width > 400) ? SizedBox.shrink():SizedBox(width: 5,),
                _buildNavButton(Icons.collections_bookmark_outlined, "Collections", control == 0, onControlChanged, 0,context),
                _buildNavButton(Icons.all_inclusive, "All", control == 1, onControlChanged, 1,context),
                _buildNavButton(LucideIcons.star, "Favorites", control == 2, onControlChanged, 2,context),
                (screen_width > 400) ? SizedBox.shrink():SizedBox(width: 5,),
              ],
            ),
          ),

          const SizedBox(width: 10),

          single_circle_button(
            LucideIcons.plus, 34.0, 34, "Add",
            () async { new_file_options(context, onNoteChanged,collections, notes,control,add_or_remove_favorite,selected_collection);},
            context, screen_width, button_width: (screen_width > 600) ? 64 : 60,
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavButton(IconData icon, String label, bool selected, Function(int) function, int num, context) {
  final bool isDark = BG.computeLuminance() < 0.5;
  final Color activeColor = isDark ? WHITE : BLACK;
  final Color inactiveColor = icon_color;
  final double screen_width = MediaQuery.of(context).size.width;

  return InkWell(
    onTap: () {function(num);},
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    child: Container(
      width: (screen_width > 600) ? 90 : (0.75 * screen_width/ 3)-4, height: (screen_width > 600) ? 58 : 56,
      decoration: BoxDecoration(
        color: selected ? nav_selected : Colors.transparent,
        borderRadius: BorderRadius.circular((screen_width > 400) ? 33 :28),
        border: selected ? Border.all(color: glass_border.withAlpha(100)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? activeColor : inactiveColor, size: 23,),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.cantarell(color: selected ? activeColor : inactiveColor, fontSize: 11, fontWeight: selected ? FontWeight.w500 : FontWeight.w200,),
          ),
        ],
      )
    ),
  );
}





