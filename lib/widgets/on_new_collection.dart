
import 'package:flutter/material.dart';

import '../app_style.dart';
import '../models/collections.dart';
import 'color_picker.dart';
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
        backgroundColor: BG.withAlpha(140), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(38)),
        clipBehavior: Clip.antiAlias,
        child: glassContainer(
          bgAlpha:30,
          borderAlpha: 244,
          borderColor: collection_color(selectedColor),
          height: 360,
          width: screen_width >420 ? 370 : screen_width -50,
          shadowColor: BG,
          child: SingleChildScrollView( child: Padding(
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

                ColorPicker(
                  initialColor: selectedColor,
                  showFullPicker: false,
                  onColorChanged: (color, identifier) {
                    setState(() {
                      selectedColor = identifier ?? "#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}";
                    });
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:  Text('Cancel', style: TextStyle(color: icon_color),),
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
                      child:  Text('Create', style: TextStyle(color: icon_color)),
                    ),
                  ],
                ),
              ],
            ),
          ),)
        ),
      );
    },
    );
    },
  );
}