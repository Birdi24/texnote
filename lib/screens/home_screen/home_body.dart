import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../models/Note.dart';
import '../../models/collections.dart';
import '../../models/TextNote.dart';
import '../../widgets/show_note_options.dart';
import '../note_screen/main.dart';

import 'no_collections_view.dart';
import 'no_notes_view.dart';

// =============================================================================
// NOTE CARD
// =============================================================================

Widget note_card({
  required BuildContext context,
  required Note note,
  required List<Collection> collections,
  required Future<void> Function() onNoteChanged,
  required void Function(Note) onNoteDeleted,
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
      addToFavorites,
    );
  }

  return GestureDetector(
    onLongPress: showOptions,
    onDoubleTap: showOptions,

    onTap: () async {
      if (note.type == TextNote) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TextNoteScreen(note as TextNote),
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
  required Future<void> Function() onNoteChanged,
  required void Function(Note) onNoteDeleted,
  required void Function(Note) addToFavorites,
  required void Function(Collection) openCollection,
}) {
  return GestureDetector(
    onLongPress: () {
      // Collection options can go here later.
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

Widget _grid({
  required List<Widget> children,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
    ),
    child: GridView.builder(
      physics:
      const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.only(
        top: 50,
        bottom: 90,
        left: 20,
        right: 20,
      ),

      gridDelegate:
      const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 300,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),

      itemCount: children.length,

      itemBuilder: (context, index) {
        return children[index];
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
      return no_collections_view(
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
          onNoteChanged: onNoteChanged,
          onNoteDeleted: onNoteDeleted,
          addToFavorites: addToFavorites,
          openCollection: openCollection
        );
      }).toList(),
    );
  }

  if (displayedNotes.isEmpty) {
    return no_note_view(
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
        addToFavorites: addToFavorites,
      );
    }).toList(),
  );
}