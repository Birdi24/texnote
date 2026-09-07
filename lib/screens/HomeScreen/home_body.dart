import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../app_style.dart';
import '../../models/Note.dart';
import '../../models/collections.dart';
import '../../models/TextNote.dart';
import '../../models/HandwrittenNote.dart';
import '../HandwrittenNoteScreen/main.dart';
import '../../widgets/show_note_options.dart';
import '../../widgets/show_collection_options.dart';
import '../TextNoteScreen/main.dart';

import 'nothing_view.dart';

// =============================================================================
// NOTE CARD
// =============================================================================
Widget note_card({
  required BuildContext context,
  required Note note,
  required List<Collection> collections,
  required Future<void> Function() onNoteChanged,
  required void Function(Note) onNoteDeleted,
  required void Function(Note) onNoteAdded,
  required void Function(Note) addToFavorites,
}) {

  void showOptions() {
    final index = 0;

    show_note_options(
      context,
      [note],
      index,
      collections,
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
      await onNoteChanged();
    },

    child: note.display(),
  );
}


// =============================================================================
// COLLECTION CARD
// =============================================================================
Widget collection_card({
  required BuildContext context,
  required Collection collection,
  required List<Collection> collections,
  required List<Note> allNotes,
  required Future<void> Function() onNoteChanged,
  required void Function(Note) onNoteDeleted,
  required void Function(Collection) onCollectionDeleted,
  required void Function(List<Note>) onNotesDeleted,
  required void Function(Note) addToFavorites,
  required void Function(Collection) openCollection,
}) {
  return GestureDetector(
    onLongPress: () {
      final index = collections.indexOf(collection);
      if (index != -1) {
        show_collection_options(
          context,
          collections,
          index,
          allNotes,
          onNoteChanged,
          onCollectionDeleted,
          onNotesDeleted,
        );
      }
    },
    onDoubleTap: () {
      final index = collections.indexOf(collection);
      if (index != -1) {
        show_collection_options(
          context,
          collections,
          index,
          allNotes,
          onNoteChanged,
          onCollectionDeleted,
          onNotesDeleted,
        );
      }
    },
    onTap: () {
      openCollection(collection);
    },
    child: collection.display(),
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
        const double gridPadding = 40; // 20 (left) + 20 (right) inside the grid

        // Calculate actual width per item based on SliverGridDelegateWithMaxCrossAxisExtent logic
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
  required List<Collection> collections,
  required Future<void> Function() onNoteChanged,
  required void Function(Note) onNoteDeleted,
  required void Function(Collection) onCollectionDeleted,
  required void Function(List<Note>) onNotesDeleted,
  required void Function(Note) onNoteAdded,
  required void Function(Note) addToFavorites,
  required void Function(Collection) openCollection,
  required Collection? selectedCollection,
  required bool inCollection,
}) {
  // ---------------------------------------------------------------------------
  // COLLECTIONS
  // ---------------------------------------------------------------------------

  if (control == 0 && !inCollection) {
    if (collections.isEmpty) {
      return nothing_view(
        context,
        onNoteChanged,
        collections,
        notes,
        control,
        addToFavorites,
        selectedCollection,
      );
    }

    return _grid(
      children: collections.map((collection) {
        return collection_card(
          context: context,
          collection: collection,
          collections: collections,
          allNotes: notes,
          onNoteChanged: onNoteChanged,
          onNoteDeleted: onNoteDeleted,
          onCollectionDeleted: onCollectionDeleted,
          onNotesDeleted: onNotesDeleted,
          addToFavorites: addToFavorites,
          openCollection: openCollection
        );
      }).toList(),
    );
  }

  if (displayedNotes.isEmpty) {
    return nothing_view(
      context,
      onNoteChanged,
      collections,
      notes,
      control,
      addToFavorites,
      selectedCollection,
    );
  }

  return _grid(
    children: displayedNotes.map((note) {
      return note_card(
        context: context,
        note: note,
        collections: collections,
        onNoteChanged: onNoteChanged,
        onNoteDeleted: onNoteDeleted,
        onNoteAdded: onNoteAdded,
        addToFavorites: addToFavorites,
      );
    }).toList(),
  );
}
