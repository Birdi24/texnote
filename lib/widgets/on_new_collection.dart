
import 'package:flutter/material.dart';

import '../app_style.dart';
import '../models/collections.dart';
import 'glass_container.dart';

Future<dynamic> on_new_collection(context, collections, onNoteCreated,bool project) {
  double screen_width = MediaQuery.of(context).size.width;

  return showDialog(
    barrierColor: Colors.transparent,
    context: context,
    builder: (context) {
    String selectedColor = "1";
    final titleController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setState) {
      return Dialog(
        backgroundColor: BG, elevation: 0,
        child: glassContainer(
          bgAlpha:30,
          borderAlpha: 244,
          borderColor: collection_color(selectedColor),
          height: 278,
          width: screen_width >420 ? 370 : screen_width -50,
          shadowColor: collection_color(selectedColor),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
              project ? 'New Project' : 'New Collection',
              style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              ),
              ),

              const SizedBox(height: 20),

              TextField(
              controller: titleController,
              autofocus: true,

              decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: project ? 'Project name':'Collection name',
              ),
              ),

              const SizedBox(height: 20),

              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
              final color = '${index + 1}';
              final selected = selectedColor == color;

              return GestureDetector(
              onTap: () {
              setState(() {
              selectedColor = color;
              });
              },
              child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
              color: collection_color(color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
              color: selected
              ? icon_color
                  : Colors.transparent,
              width: 3,
              ),
              ),
              ),
              );
              }),
              ),

              const SizedBox(height: 24),

              Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: icon_color),),
              ),

              const SizedBox(width: 8),

              ElevatedButton(
              onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              collections.add(Collection( title, selectedColor, [],));
              await onNoteCreated();
              Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: icon_color)),
              ),
              ],
              ),
              ],
            ),
          ),
        ),
      );
    },
    );
    },
  );
}