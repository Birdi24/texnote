import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_style.dart';
import '../../models/Note.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/new_file_button.dart';
import '../../widgets/single_circle_button.dart';

/// This has 4 buttons: PDFs, Notes, Favorites, Add
/// They are aligned bottom center
Widget home_nav_bar(Future<void> Function([Note?]) onNoteChanged, context, screenWidth, control, onControlChanged, folders, notes, addOrRemoveFavorite, selectedFolder) {
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glassContainer(
            width: (screenWidth > 600) ? 300 : 0.76 * screenWidth, height: (screenWidth > 600) ? 68 : 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (screenWidth > 400) ? const SizedBox.shrink() : const SizedBox(width: 5),
                _buildNavButton(Icons.picture_as_pdf_outlined, "PDFs", control == 0, onControlChanged, 0, context),
                _buildNavButton(Icons.folder_open_outlined, "Notes", control == 1, onControlChanged, 1, context),
                _buildNavButton(LucideIcons.star, "Favorites", control == 2, onControlChanged, 2, context),
                (screenWidth > 400) ? const SizedBox.shrink() : const SizedBox(width: 5),
              ],
            ),
          ),

          const SizedBox(width: 10),

          single_circle_button(
            LucideIcons.plus, 34.0, 34, "Add",
            () async { new_file_options(context, onNoteChanged, folders, notes, control, addOrRemoveFavorite, selectedFolder);},
            context, screenWidth, button_width: (screenWidth > 600) ? 64 : 60,
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
  final double screenWidth = MediaQuery.of(context).size.width;

  return InkWell(
    onTap: () {function(num);},
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    child: Container(
      width: (screenWidth > 600) ? 90 : (0.72 * screenWidth / 3), height: (screenWidth > 600) ? 58 : 56,
      decoration: BoxDecoration(
        color: selected ? nav_selected : Colors.transparent,
        borderRadius: BorderRadius.circular((screenWidth > 400) ? 33 : 28),
        border: selected ? Border.all(color: glass_border.withAlpha(100)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? activeColor : inactiveColor, size: 23,),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.cantarell(
            color: selected ? activeColor : inactiveColor, 
            fontSize: 11, 
            fontWeight: selected ? FontWeight.w500 : FontWeight.w200,
          ),
          ),
        ],
      )
    ),
  );
}
