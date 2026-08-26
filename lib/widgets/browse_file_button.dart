import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:texnote/widgets/glass_container.dart';
import '../app_style.dart';
import '../io/browse_file.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';
import '../screens/TextNoteScreen/main.dart';

Widget browse_button(context,  Future<void> Function() onNoteCreated) {
  return GestureDetector(
    onTap: () async {
      print("browsing files to open");
      Note? note = await FileOpenerScreen().browseFiles();
      if (note != null && note.type == TextNote) {

        await Navigator.push(context,
            MaterialPageRoute(builder: (context) => TextNoteScreen(note as TextNote))
        );
      }
      await onNoteCreated();
      print("Back to home screen from note screen :imported note");
    },
    child: glassContainer(
      width: 170,
      height: 78,
      borderAlpha: 50,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.folder,
            size: 22,
            color: icon_color,
          ),
          const SizedBox(width: 8),
          Text(
            "Browse Files",
            style: AppStyles.icon_text,
          ),
        ],
      ),
    ),
  );

}
