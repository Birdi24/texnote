import 'dart:io';

import 'package:flutter/material.dart';
import '../../app_style.dart';
import '../../models/note.dart';
import '../../widgets/show_note_options.dart';
import '../note_screen/main.dart';


Widget single_note(
  context,
  notes,
  index,
  Future<void> Function() onNoteChanged,
  void Function(Note) onNoteDeleted,
  void Function(Note) add_to_favorites ) {
  Note note = notes[index];
  return GestureDetector(
    onLongPress: () {show_note_options(context, notes, index, onNoteChanged, onNoteDeleted, add_to_favorites);},
    onDoubleTap: () {show_note_options(context, notes, index, onNoteChanged, onNoteDeleted, add_to_favorites);},
    onTap: () async {
      print("opening a note from list");
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteScreen(note),
        ),
      );
      await onNoteChanged();
      print("Back to home screen from note screen :cards");
    },
    child: Column(
      children: [
        // Notebook rectangle
        Container(
            width: 180,
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                note.body,
                maxLines: 10,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),


        const SizedBox(height: 8),

        // Title OUTSIDE card
        Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 3),

        // Date OUTSIDE card
        Text(
          note.date_string(),
          style: TextStyle(
            color: Colors.black.withAlpha(60),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Future<bool?> delete_alert(BuildContext context, List<Note> notes, int index, void Function(Note) onNoteDeleted) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: icon_color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          "Delete note?",
          style: AppStyles.subtitle,
        ),
        content: Text(
          'Are you sure you want to delete\n"${notes[index].title}"?',
          style: AppStyles.bodytext,
        ),
        actions: [
          SizedBox(
            width: 125,
            height: 40,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: AppStyles.bodytext,
              ),
            ),
          ),
          SizedBox(
            width: 125,
            height: 40,
            child: TextButton(
              onPressed: () async{
                Note noteToDelete = notes[index];
                Navigator.pop(context);
                await noteToDelete.deleteNote();
                onNoteDeleted(noteToDelete);
              },
              child: Text(
                "Delete",
                style: AppStyles.red_text,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget notes_view(
    context,
    notes,
    Future<void> Function() onNoteChanged,
    void Function(Note) onNoteDeleted,
    void Function(Note) add_to_favorites
    ) {
  return
    Padding(
    padding: const EdgeInsets.only(left: 16, right: 16),
    child:
        GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 50, bottom: 90, left:20, right:20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 300,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return single_note(
              context,
              notes,
              index,
              onNoteChanged,
              onNoteDeleted,
              add_to_favorites
            );
          },
        ),


  );
}

