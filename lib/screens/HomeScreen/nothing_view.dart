import 'package:flutter/material.dart';
import '../../app_style.dart';
import '../../models/Note.dart';
import '../../models/folder.dart';

Widget nothing_view(
  BuildContext context, 
  Future<void> Function([Note?]) onNoteChanged,
  List<Folder> folders,
  List<Note> notes, 
  int control,
  dynamic addOrRemoveFavorite,
  Folder? selectedFolder
) {
  String emptyText = "Begin a New Note/\nFolder";
  String subText = "Start a new Note or Folder to find it here";
  
  if (control == 0) {
    emptyText = "No PDF Notes";
    subText = "Imported PDFs will appear here";
  } else if (control == 2) {
    emptyText = "No Favorites";
    subText = "Notes you star will appear here";
  } else if (selectedFolder != null) {
    emptyText = "Empty Folder";
    subText = 'Add items to "${selectedFolder.title}"';
  }

  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          emptyText,
          style: AppStyles.title2.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subText,
          style: AppStyles.bodytext,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
