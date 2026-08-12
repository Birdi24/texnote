import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../widgets/browse_file_button.dart';
import '../../widgets/new_file_button.dart';

Widget no_note_view(context, Future<void> Function() onNoteCreated,collections) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon( Icons.note_add_outlined, size: 72),
          const SizedBox(height: 12),
          Text( "No notes yet", style: AppStyles.title2, ),
          const SizedBox(height: 8),

          Text( "Create a new note or browse your device to import one.",
            style: AppStyles.title2,
          ),
          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              browse_button(context,onNoteCreated),
              const SizedBox(width: 16),
              new_note_button(context,onNoteCreated, collections),
            ],
          ),
        ],
      ),
    ),
  );
}