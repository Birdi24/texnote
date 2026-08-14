import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:texnote/widgets/glass_container.dart';
import '../app_style.dart';
import '../io/browse_file.dart';
import '../models/note.dart';
import '../screens/note_screen/main.dart';

Widget browse_button(context,  Future<void> Function() onNoteCreated) {
  return GestureDetector(
    onTap: () async {
      print("browsing files to open");
      Note? note = await FileOpenerScreen().browseFiles();
      if (note != null ) {
        print("\npath: "+ note.path);
        print("\ntitle:" + note.title);
        await Navigator.push(context,
            MaterialPageRoute(builder: (context) => NoteScreen(note))
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
            Icons.folder_open,
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
