import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../models/favorite_and_collection_handling.dart';
import '../../models/note.dart';
import '../../widgets/show_note_options.dart';
import '../note_screen/main.dart';

import 'no_collections_view.dart';
import 'no_notes_view.dart';


// =============================================================================
// NOTE DISPLAY
// =============================================================================

Widget display_note(Note note) {
  return Column(
    children: [
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

      Text(
        note.date_string(),
        style: TextStyle(
          color: Colors.black.withAlpha(60),
          fontSize: 12,
        ),
      ),
    ],
  );
}


// =============================================================================
// COLLECTION DISPLAY
// =============================================================================

Widget display_collection(Collection collection) {
  return Column(
    children: [
      Container(
        width: 180,
        height: 250,
        padding: const EdgeInsets.only(top: 50),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: collection_color(collection.color),
          border: Border.all(
            color: icon_color,
            width: 2,
          ),
        ),
        child: Container(
          alignment: Alignment.bottomCenter,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: icon_color,
              width: 2,
            ),
          ),
        ),
      ),

      const SizedBox(height: 8),

      Text(
        collection.title,
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

      Text(
        "${collection.notes.length} Notes",
        style: TextStyle(
          color: Colors.black.withAlpha(60),
          fontSize: 12,
        ),
      ),
    ],
  );
}


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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteScreen(note),
        ),
      );
      await onNoteChanged();
    },

    child: display_note(note),
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

    child: display_collection(collection),
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

  // ---------------------------------------------------------------------------
  // NOTES / FAVORITES / COLLECTION NOTES
  // ---------------------------------------------------------------------------

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