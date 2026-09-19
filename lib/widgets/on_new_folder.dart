import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_style.dart';
import '../models/Note.dart';
import '../models/folder.dart';
import 'color_picker.dart';
import 'glass_container.dart';

Future<dynamic> on_new_folder(context, Folder? parentFolder, Future<void> Function([Note?]) onFolderCreated) async {
  double screenWidth = MediaQuery.of(context).size.width;

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
              bgAlpha: 30,
              borderAlpha: 244,
              borderColor: collection_color(selectedColor),
              height: 290,
              width: screenWidth > 420 ? 370 : screenWidth - 50,
              shadowColor: BG,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'New Folder',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Folder name',
                        ),
                      ),
                      const SizedBox(height: 20),
                      HomeColorPicker(
                        initialColor: selectedColor,
                        onColorChanged: (color, identifier) {
                          setState(() {
                            selectedColor = identifier ?? "#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}";
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: icon_color)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: collection_color(selectedColor),
                              foregroundColor: WHITE,
                            ),
                            onPressed: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;
                              
                              final appDir = await getApplicationDocumentsDirectory();
                              final basePath = parentFolder?.path ?? appDir.path;
                              final newPath = p.join(basePath, title);
                              
                              final dir = Directory(newPath);
                              if (!await dir.exists()) {
                                await dir.create(recursive: true);
                              }
                              
                              // Save the selected color immediately
                              await Folder.update_folder_color(newPath, selectedColor);
                              
                              await onFolderCreated();
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Text('Create', style: TextStyle(color: icon_color)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
