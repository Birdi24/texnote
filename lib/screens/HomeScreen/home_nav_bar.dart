import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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
            width: (screen_width > 600) ? 300 : 0.7 * screen_width, height: (screen_width > 600) ? 68 : 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(Icons.collections_bookmark_outlined, "Collections", control == 0, onControlChanged, 0),
                _buildNavButton(Icons.all_inclusive, "All", control == 1, onControlChanged, 1),
                _buildNavButton(LucideIcons.star, "Favorites", control == 2, onControlChanged, 2),
              ],
            ),
          ),

          const SizedBox(width: 8),

          single_circle_button(
            LucideIcons.plus, 34.0, 34, "Add",
            () async { new_file_options(context, onNoteChanged,collections, notes,control,add_or_remove_favorite,selected_collection);},
            context, screen_width, button_width: (screen_width > 600) ? 68 : 58,
          ),
        ],
      ),
    ),
  );
}

Widget _buildNavButton(IconData icon, String label, bool selected, Function(int) function, int num) {
  final bool isDark = BG.computeLuminance() < 0.5;
  final Color activeColor = isDark ? WHITE : BLACK;
  final Color inactiveColor = icon_color;

  return InkWell(
    borderRadius: BorderRadius.circular(28),
    onTap: () {function(num);},
    child: Container(
      width: 80, height: 58,
      decoration: BoxDecoration(
        color: selected ? nav_selected : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: selected ? Border.all(color: glass_border.withAlpha(100)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? activeColor : inactiveColor, size: 23,),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.cantarell(color: selected ? activeColor : inactiveColor, fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,),
          ),
        ],
      ),
    ),
  );
}





