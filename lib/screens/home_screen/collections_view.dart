import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app_style.dart';
import '../../models/favorite_and_collection_handling.dart';
import '../../models/note.dart';

Widget collections_view(
    BuildContext context,
    List<Collection> collections,
    Future<void> Function() onNoteChanged,
    void Function(Note) add_or_remove_favorites,
    void Function(Collection) openCollection
    ) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: 50,
        bottom: 90,
        left: 20,
        right: 20,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 300,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        return single_collection(
          context,
          collections,
          index,
          onNoteChanged,
          add_or_remove_favorites,
          openCollection,
        );
      },
    ),
  );
}

Widget single_collection(
    BuildContext context,
    List<Collection> collections,
    int index,
    Future<void> Function() onNoteChanged,
    void Function(Note) add_or_remove_favorites,
    void Function(Collection) openCollection
    ) {
  Collection collection = collections[index];

  return GestureDetector(
    onTap: () {
      openCollection(collection);
    },
    child: Column(
      children: [
        Container(
          width: 180,
          height: 250,
          padding: const EdgeInsetsGeometry.only(top: 50),
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
    ),
  );
}
