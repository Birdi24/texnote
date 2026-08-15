import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../widgets/browse_file_button.dart';
import '../../widgets/new_file_button.dart';

Widget no_collections_view(context, Future<void> Function() onNoteChanged,collections,notes, control,add_or_remove_favorite,selected_collection) {
  return Center(
    child: GestureDetector(
      onTap: () {
        new_note_button(context, onNoteChanged, collections, notes, control, add_or_remove_favorite, selected_collection, true);
      },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          width: 250,
          height: 380,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_copy, size: 72),
              const SizedBox(height: 12),
              Text("No collections yet", style: AppStyles.title2),
              const SizedBox(height: 8),
              Text(
                "Create a new collection.",
                style: AppStyles.title2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

    ),
  );
}
