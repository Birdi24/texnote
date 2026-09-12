import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/Note.dart';
import '../../models/folder.dart';
import '../../models/TextNote.dart';
import '../../models/HandwrittenNote.dart';
import '../HandwrittenNoteScreen/main.dart';
import '../../widgets/show_note_options.dart';
import '../../widgets/show_folder_options.dart';
import '../TextNoteScreen/main.dart';

import 'nothing_view.dart';

// =============================================================================
// NOTE CARD
// =============================================================================
Widget note_card({
  required BuildContext context,
  required Note note,
  required List<Folder> folders,
  required Future<void> Function([Note?]) onNoteChanged,
  required void Function(Note) onNoteDeleted,
  required void Function(Note) onNoteAdded,
  required void Function(Note) addToFavorites,
}) {

  void showOptions() {
    show_note_options(
      context,
      [note],
      0,
      folders,
      onNoteChanged,
      onNoteDeleted,
      onNoteAdded,
      addToFavorites,
    );
  }

  return GestureDetector(
    onLongPress: showOptions,
    onDoubleTap: showOptions,
    onTap: () async {
      debugPrint("note_card.onTap: opening note ${note.title}");
      if (note.type == NoteType.TextNote) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TextNoteScreen(note as TextNote),
          ),
        );
      } else if (note.type == NoteType.HandwrittenNote) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HandwrittenNotePage(note: note as HandwrittenNote),
          ),
        );
      }
      debugPrint("note_card.onTap: returned from note screen. note: ${note.title}");
      await onNoteChanged(); // Force full refresh for now to troubleshoot
    },

    child: note.display(),
  );
}


// =============================================================================
// FOLDER CARD
// =============================================================================
Widget folder_card({
  required BuildContext context,
  required Folder folder,
  required List<Folder> allFolders,
  required List<Note> allNotes,
  required Future<void> Function([Note?]) onNoteChanged,
  required void Function(Folder) onFolderDeleted,
  required void Function(List<Note>) onNotesDeleted,
  required void Function(Folder) openFolder,
}) {
  return GestureDetector(
    onLongPress: () {
      show_folder_options(
        context,
        folder,
        onNoteChanged,
        onFolderDeleted,
        onNotesDeleted,
      );
    },
    onDoubleTap: () {
      show_folder_options(
        context,
        folder,
        onNoteChanged,
        onFolderDeleted,
        onNotesDeleted,
      );
    },
    onTap: () {
      openFolder(folder);
    },
    child: folder.display(),
  );
}


// =============================================================================
// GRID
// =============================================================================
Widget _grid({required List<Widget> children, }) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Grid constants
        const double maxExtent = 220;
        const double spacing = 12;
        const double gridPadding = 40; 

        // Calculate actual width per item
        double usableWidth = constraints.maxWidth - gridPadding;
        int crossAxisCount = ((usableWidth + spacing) / (maxExtent + spacing)).ceil();
        crossAxisCount = math.max(1, crossAxisCount);

        double childWidth = (usableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        double mainAxisExtent = (childWidth / 0.72) + 55;

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 50,
            bottom: 90,
            left: 20,
            right: 20,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 20,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) {
            return children[index];
          },
        );
      },
    ),
  );
}


// =============================================================================
// HOME BODY
// =============================================================================

Widget home_body({
  required int control,
  required BuildContext context,
  required List<Note> notes,
  required List<Note> displayedNotes,
  required List<Folder> folders,
  required Future<void> Function([Note?]) onNoteChanged,
  required void Function(Note) onNoteDeleted,
  required void Function(Folder) onFolderDeleted,
  required void Function(List<Note>) onNotesDeleted,
  required void Function(Note) onNoteAdded,
  required void Function(Note) addToFavorites,
  required void Function(Folder) openFolder,
  required Folder? selectedFolder,
  required bool inFolder,
  required List<Folder> allFolders,
}) {
  debugPrint("home_body.dart: control=$control, displayedNotesCount=${displayedNotes.length}, foldersCount=${folders.length}");
  if (displayedNotes.isNotEmpty) {
    debugPrint("   -> Sample notes: ${displayedNotes.take(3).map((n) => n.title).toList()}");
  }
  
  List<Widget> gridChildren = [];

  // Add Folders first in Browser view
  if (control == 1) {
    gridChildren.addAll(folders.map((folder) => folder_card(
      context: context,
      folder: folder,
      allFolders: folders,
      allNotes: notes,
      onNoteChanged: onNoteChanged,
      onFolderDeleted: onFolderDeleted,
      onNotesDeleted: onNotesDeleted,
      openFolder: openFolder,
    )));
  }

  // Add Notes
  gridChildren.addAll(displayedNotes.map((note) => note_card(
    context: context,
    note: note,
    folders: allFolders,
    onNoteChanged: onNoteChanged,
    onNoteDeleted: onNoteDeleted,
    onNoteAdded: onNoteAdded,
    addToFavorites: addToFavorites,
  )));

  if (gridChildren.isEmpty) {
    return nothing_view(
      context,
      onNoteChanged,
      folders,
      notes,
      control,
      addToFavorites,
      selectedFolder,
    );
  }

  return _grid(children: gridChildren);
}
