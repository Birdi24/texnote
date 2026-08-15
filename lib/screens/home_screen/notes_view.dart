import 'dart:io';

import 'package:flutter/material.dart';
import '../../app_style.dart';
import '../../models/note.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/show_note_options.dart';
import '../note_screen/main.dart';


Widget single_note(
  context,
  notes,
  index, collections,
  Future<void> Function() onNoteChanged,
  void Function(Note) onNoteDeleted,
  void Function(Note) add_to_favorites ) {
  Note note = notes[index];
  return GestureDetector(
    onLongPress: () {show_note_options(context, notes, index,  collections,onNoteChanged,onNoteDeleted, add_to_favorites);},
    onDoubleTap: () {show_note_options(context, notes, index, collections, onNoteChanged, onNoteDeleted, add_to_favorites);},
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
                color: icon_color,
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
                  color: icon_color,
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
            color: icon_color,
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
  final screen_width = MediaQuery.of(context).size.width;
  return showDialog<bool>(
    barrierColor: Colors.transparent,
    context: context,
    builder: (context) {
      return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: glassContainer(
            bgAlpha: 10,
            borderAlpha: 244,
            borderColor: Colors.red,
            height: 278,
            width: screen_width > 420 ? 370 : screen_width - 50,
            shadowColor: BG,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const SizedBox(height: 45),
                    const Text(
                      "Delete note?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      textAlign: TextAlign.center,
                      'Are you sure you want to delete\n"${notes[index].title}"?',
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: icon_color),),
                        ),

                        const SizedBox(width: 15),

                        ElevatedButton(
                          onPressed: () async{
                            Note noteToDelete = notes[index];
                            Navigator.pop(context);
                            await noteToDelete.deleteNote();
                            onNoteDeleted(noteToDelete);
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ]
              ),
            ),)
      );
    }
    );
}


Widget notes_view(
    context,
    notes, collections,
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
              index, collections,
              onNoteChanged,
              onNoteDeleted,
              add_to_favorites
            );
          },
        ),


  );
}

