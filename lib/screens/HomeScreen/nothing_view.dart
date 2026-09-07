import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app_style.dart';

Widget nothing_view(context, Future<void> Function() onNoteChanged,collections,notes, control,add_or_remove_favorite,selected_collection) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Begin a New Note/\nCollection",
          style: AppStyles.title2.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Start a new Note or Collection to find it here",
          style: AppStyles.bodytext,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}



