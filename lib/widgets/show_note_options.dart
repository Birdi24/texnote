import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:birdwrite/models/HandwrittenNote.dart';

import '../app_style.dart';
import '../models/Note.dart';
import '../models/folder.dart';
import 'color_picker.dart';
import 'glass_container.dart';
import 'on_new_folder.dart';

Future<bool?> delete_alert(BuildContext context, List<Note> notes, int index, void Function(Note) onNoteDeleted) {
  final screenWidth = MediaQuery.of(context).size.width;
  return showDialog<bool>(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: glassContainer(
              bgAlpha: 20,
              borderAlpha: 244,
              borderColor: RED,
              height: 220,
              width: screenWidth > 380 ? 330 : screenWidth - 50,
              shadowColor: BG,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Delete note?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        textAlign: TextAlign.center,
                          notes[index].title.length > 25 ? 'Are you sure you want to delete\n"${notes[index].title.substring(0,22)}..."?' : 'Are you sure you want to delete\n"${notes[index].title}"?'
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child:  Text('Cancel', style: TextStyle(color: icon_color),),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: () async {
                              Note noteToDelete = notes[index];
                              Navigator.pop(context);
                              await noteToDelete.delete();
                              onNoteDeleted(noteToDelete);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ]
                ),
              ),)
        );
      }
  );
}

void show_note_options(
    BuildContext context,
    List<Note> notes,
    int index,
    List<Folder> folders,
    Future<void> Function([Note?]) onNoteChanged,
    void Function(Note) onNoteDeleted,
    void Function(Note) onNoteAdded,
    void Function(Note) addToFavorites) {

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: screenWidth > 470 ? 420 : screenWidth - 50,
          decoration: BoxDecoration(
            color: BG,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(LucideIcons.pen),
                  title: const Text('Rename note'),
                  onTap: () {
                    Navigator.pop(context);
                    rename_note(context, notes, index, onNoteChanged);
                  },
                ),
                if (notes[index].type == NoteType.HandwrittenNote)
                  ListTile(
                    leading: const Icon(LucideIcons.palette),
                    title: const Text('Change cover color'),
                    onTap: () {
                      Navigator.pop(context);
                      change_handwritten_note_color_dialog(context, notes, index, onNoteChanged);
                    },
                  ),
                ListTile(
                  leading: Icon(
                    LucideIcons.star,
                    color: notes[index].isFavorite ? RED : icon_color,
                  ),
                  title: notes[index].isFavorite
                      ? const Text('Remove from favorites', style: TextStyle(color: RED))
                      : const Text('Add to favorites'),
                  onTap: () {
                    Navigator.pop(context);
                    addToFavorites(notes[index]);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.copy),
                  title: const Text('Duplicate'),
                  onTap: () async {
                    Navigator.pop(context);
                    Note dup = await notes[index].duplicate_note();
                    if (dup.title != "INVALID") {
                      onNoteAdded(dup);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.move),
                  title: const Text('Move to Folder'),
                  onTap: () {
                    Navigator.pop(context);
                    show_move_note_dialog(context, notes[index], folders, onNoteChanged);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.file_up),
                  title: const Text('Export note'),
                  onTap: () {
                    Navigator.pop(context);
                    notes[index].export();
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.upload),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    notes[index].exportAsPdf();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    LucideIcons.trash,
                    color: RED,
                  ),
                  title: const Text(
                    'Delete note',
                    style: TextStyle(color: RED),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    delete_alert(context, notes, index, onNoteDeleted);
                  },
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom)
              ],
            ),
          ),
        ),
      );
    },
  );
}

void show_move_note_dialog(BuildContext context, Note note, List<Folder> folders, Future<void> Function([Note?]) onNoteChanged) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: glassContainer(
          bgAlpha: 10,
          borderAlpha: 244,
          borderColor: icon_color,
          height: 400,
          width: screenWidth > 430 ? 380 : screenWidth - 50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text("Move to Folder", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(LucideIcons.infinity),
                        title: const Text("Home"),
                        onTap: () async {
                          final appDir = await getApplicationDocumentsDirectory();
                          await note.move_to(appDir.path);
                          await onNoteChanged(note);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ..._buildFolderList(folders, note, onNoteChanged, context),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: icon_color)),
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}

List<Widget> _buildFolderList(List<Folder> folders, Note note, Future<void> Function([Note?]) onNoteChanged, BuildContext context, {int depth = 0}) {
  List<Widget> list = [];
  for (var folder in folders) {
    list.add(Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: ListTile(
        leading: Icon(LucideIcons.folder, color: collection_color(folder.color)),
        title: Text(folder.title),
        onTap: () async {
          await note.move_to(folder.path);
          await onNoteChanged(note);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ));
    if (folder.subfolders.isNotEmpty) {
      list.addAll(_buildFolderList(folder.subfolders, note, onNoteChanged, context, depth: depth + 1));
    }
  }
  return list;
}

void rename_note(BuildContext context, List<Note> notes, int index, Future<void> Function([Note?]) onNoteCreated) {
  final controller = TextEditingController(text: notes[index].title);
  final screenWidth = MediaQuery.of(context).size.width;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: glassContainer(
          bgAlpha: 10,
          borderAlpha: 244,
          borderColor: icon_color,
          height: 240,
          width: screenWidth > 420 ? 370 : screenWidth - 50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text("Rename Note", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Note name"),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(color: icon_color)),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: () async {
                        final newTitle = controller.text.trim();
                        if (newTitle.isEmpty) return;
                        final oldTitle = notes[index].title;
                        notes[index].title = newTitle;
                        await notes[index].save(oldTitle);
                        await onNoteCreated(notes[index]);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Done"),
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
}

void change_handwritten_note_color_dialog(BuildContext context, List<Note> notes, int index, Future<void> Function([Note?]) onNoteChanged) {
  final screenWidth = MediaQuery.of(context).size.width;
  final note = notes[index] as HandwrittenNote;
  String currentSelected = note.cover;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SingleChildScrollView(
              child: glassContainer(
                bgAlpha: 10,
                borderAlpha: 244,
                borderColor: collection_color(currentSelected),
                height: 560,
                width: screenWidth > 420 ? 370 : screenWidth - 50,
                shadowColor: BG,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      const Text("Cover Color", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 25),
                      ColorPicker(
                        initialColor: currentSelected,
                        showFullPicker: true,
                        onColorChanged: (color, identifier) {
                          setState(() {
                            currentSelected = identifier ?? "#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}";
                          });
                        },
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel", style: TextStyle(color: icon_color, fontSize: 16, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: collection_color(currentSelected),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              note.cover = currentSelected;
                              await note.save(note.title);
                              await onNoteChanged(note);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: const Text("Done"),
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
