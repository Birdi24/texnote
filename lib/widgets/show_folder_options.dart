import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_style.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';
import '../models/folder.dart';
import 'color_picker.dart';
import 'glass_container.dart';


void show_folder_options(
    BuildContext context,
    Folder folder,
    List<Note> allNotes,
    List<Folder> allFolders,
    Future<void> Function([Note?]) onFolderChanged,
    Future<void> Function(Folder) onFolderDeleted,
    void Function(List<Note>) onNotesDeleted) {

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
          width: screenWidth > 500 ? 450 : screenWidth - 50,
          decoration: BoxDecoration(
            color: BG,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(LucideIcons.pen),
                    title: const Text('Rename folder'),
                    onTap: () {
                      Navigator.pop(context);
                      rename_folder_dialog(context, folder, onFolderChanged);
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.palette),
                    title: const Text('Change color'),
                    onTap: () {
                      Navigator.pop(context);
                      change_folder_color_dialog(context, folder, onFolderChanged);
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.move),
                    title: const Text('Move folder'),
                    onTap: () {
                      Navigator.pop(context);
                      move_folder_dialog(context, folder, allFolders, onFolderChanged);
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.plus),
                    title: const Text('Add Notes to folder'),
                    onTap: () {
                      Navigator.pop(context);
                      manage_folder_notes_dialog(context, folder, allNotes, onFolderChanged, isAdding: true);
                    },
                  ),

                  ListTile(
                    leading: const Icon(LucideIcons.minus, color: RED,),
                    title: const Text('Remove from folder', style: TextStyle(color: RED)),
                    onTap: () {
                      Navigator.pop(context);
                      manage_folder_notes_dialog(context, folder, allNotes, onFolderChanged, isAdding: false);
                    },
                  ),

                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.trash,
                      color: RED,
                    ),
                    title: const Text(
                      'Delete folder',
                      style: TextStyle(color: RED),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      delete_folder_alert(context, folder, onFolderDeleted, onNotesDeleted);
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom)
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
class _RemovableItem {
  final Note? note;
  final Folder? folder;
  _RemovableItem.note(this.note) : folder = null;
  _RemovableItem.folder(this.folder) : note = null;

  String get title => note != null
      ? (note!.title.isEmpty ? "Untitled" : note!.title)
      : folder!.title;
  String get path => note != null ? note!.path : folder!.path;
}

void manage_folder_notes_dialog(
    BuildContext context,
    Folder folder,
    List<Note> allNotes,
    Future<void> Function([Note?]) onFolderChanged,
    {required bool isAdding}) async {
  final screenWidth = MediaQuery.of(context).size.width;

  List<_RemovableItem> availableItems = [];
  if (isAdding) {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final currentDirPath = folder.parent?.path ?? appDir.path;

      availableItems = allNotes
          .where((n) => p.dirname(n.path) == currentDirPath)
          .where((n) => !folder.notes.any((fn) => fn.path == n.path))
          .map((n) => _RemovableItem.note(n))
          .toList();
    } catch (e) {
      debugPrint("Error loading current directory notes: $e");
    }
  } else {
    // Removing: everything currently inside this folder — notes AND subfolders
    availableItems = [
      ...folder.notes.map((n) => _RemovableItem.note(n)),
      ...folder.subfolders.map((f) => _RemovableItem.folder(f)),
    ];
  }

  if (availableItems.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdding ? "No notes available to add." : "Folder is empty.")),
      );
    }
    return;
  }

  List<_RemovableItem> selectedItems = [];

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: glassContainer(
              bgAlpha: 20,
              borderAlpha: 244,
              borderColor: collection_color(folder.color),
              height: 450,
              width: screenWidth > 420 ? 370 : screenWidth - 50,
              shadowColor: BG,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isAdding ? "Add to Folder" : "Remove from Folder",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: availableItems.length,
                        itemBuilder: (context, index) {
                          final item = availableItems[index];
                          final isSelected = selectedItems.contains(item);
                          return CheckboxListTile(
                            secondary: Icon(item.folder != null ? LucideIcons.folder : LucideIcons.file),
                            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(p.basename(item.path), style: const TextStyle(fontSize: 10)),
                            value: isSelected,
                            activeColor: collection_color(folder.color),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedItems.add(item);
                                } else {
                                  selectedItems.remove(item);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel", style: TextStyle(color: icon_color)),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: collection_color(folder.color),
                            foregroundColor: WHITE,
                          ),
                          onPressed: selectedItems.isEmpty
                              ? null
                              : () async {
                            final appDir = await getApplicationDocumentsDirectory();
                            final destinationPath = isAdding ? folder.path : (folder.parent?.path ?? appDir.path);
                            final destinationFolder = isAdding ? folder : folder.parent;

                            for (var item in selectedItems) {
                              if (item.note != null) {
                                await item.note!.move_to(destinationPath);
                              } else if (item.folder != null) {
                                await item.folder!.move_folder(destinationPath, newParent: destinationFolder);
                              }
                            }

                            await onFolderChanged();
                            if (context.mounted) Navigator.pop(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${selectedItems.length} items processed.")),
                              );
                            }
                          },
                          child: const Text("Confirm"),
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

void move_folder_dialog(BuildContext context, Folder folder, List<Folder> allFolders, Future<void> Function([Note?]) onFolderChanged) {
  final screenWidth = MediaQuery.of(context).size.width;

  // Collect this folder's own path + all descendant paths — these are invalid targets
  final Set<String> excludedPaths = {p.canonicalize(folder.path)};
  void collectDescendants(Folder f) {
    for (var sub in f.subfolders) {
      excludedPaths.add(p.canonicalize(sub.path));
      collectDescendants(sub);
    }
  }
  collectDescendants(folder);

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
                          try {
                            await folder.move_folder(appDir.path, newParent: null);
                            await onFolderChanged();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ..._buildMoveFolderList(allFolders, folder, excludedPaths, onFolderChanged, context),
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

List<Widget> _buildMoveFolderList(
    List<Folder> folders,
    Folder folderBeingMoved,
    Set<String> excludedPaths,
    Future<void> Function([Note?]) onFolderChanged,
    BuildContext context,
    {int depth = 0}) {
  List<Widget> list = [];
  for (var target in folders) {
    // Skip the folder itself and any of its own descendants
    if (excludedPaths.contains(p.canonicalize(target.path))) continue;

    list.add(Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: ListTile(
        leading: Icon(LucideIcons.folder, color: collection_color(target.color)),
        title: Text(target.title),
        onTap: () async {
          try {
            await folderBeingMoved.move_folder(target.path, newParent: target);
            await onFolderChanged();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ));

    if (target.subfolders.isNotEmpty) {
      list.addAll(_buildMoveFolderList(target.subfolders, folderBeingMoved, excludedPaths, onFolderChanged, context, depth: depth + 1));
    }
  }
  return list;
}

void rename_folder_dialog(
    BuildContext context,
    Folder folder,
    Future<void> Function([Note?]) onFolderChanged) {
  final controller = TextEditingController(text: folder.title);
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
                const Text(
                  "Rename Folder",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: "Folder name"),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: collection_color(folder.color),
                        foregroundColor: WHITE,
                      ),
                      onPressed: () async {
                        final newTitle = controller.text.trim();
                        if (newTitle.isEmpty) return;
                        await folder.rename_folder(newTitle);
                        await onFolderChanged();
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

void change_folder_color_dialog(
    BuildContext context,
    Folder folder,
    Future<void> Function([Note?]) onFolderChanged) {
  final screenWidth = MediaQuery.of(context).size.width;
  String currentSelected = folder.color;

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
                color: BG,
                bgAlpha: 10,
                borderAlpha: 210,
                borderColor: collection_color(currentSelected),
                height: 225,
                width: screenWidth > 420 ? 370 : screenWidth - 50,
                shadowColor: BG,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, left: 24, right: 24, bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Folder Color",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 25),
                      HomeColorPicker(
                        initialColor: currentSelected,
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
                              foregroundColor: WHITE,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              folder.color = currentSelected;
                              await Folder.update_folder_color(folder.path, currentSelected);
                              await onFolderChanged(folder.notes.isNotEmpty ? folder.notes.first : TextNote(title: "dummy", date: DateTime.now(), path: "", type: NoteType.TextNote, body: ""));
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

void delete_folder_alert(
    BuildContext context,
    Folder folder,
    Future<void> Function(Folder) onFolderDeleted,
    void Function(List<Note>) onNotesDeleted) {
  final screenWidth = MediaQuery.of(context).size.width;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: glassContainer(
          bgAlpha: 70,
          borderAlpha: 244,
          borderColor: RED,
          height: 330,
          width: screenWidth > 420 ? 370 : screenWidth - 50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Delete Folder?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  textAlign: TextAlign.center,
                  'How would you like to delete\n"${folder.title}"?',
                ),
                const SizedBox(height: 25),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        backgroundColor: collection_color(folder.color),
                        foregroundColor: WHITE
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final appDir = await getApplicationDocumentsDirectory();
                        final destinationPath = folder.parent?.path ?? appDir.path;
                        final destinationFolder = folder.parent;

                        // Move notes to parent physically
                        for (var note in folder.notes) {
                          await note.move_to(destinationPath);
                        }
                        for (var sub in folder.subfolders) {
                          await sub.move_folder(destinationPath, newParent: destinationFolder);
                        }
                        // Delete directory
                        final dir = Directory(folder.path);
                        if (await dir.exists()) await dir.delete(recursive: true);
                        
                        onFolderDeleted(folder);
                      },
                      child: const Text('Delete Folder only (Keep Items)'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RED,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        List<Note> notesToDelete = [];
                        void collectNotes(Folder f) {
                          notesToDelete.addAll(f.notes);
                          for (var sub in f.subfolders) collectNotes(sub);
                        }
                        collectNotes(folder);

                        final dir = Directory(folder.path);
                        if (await dir.exists()) await dir.delete(recursive: true);
                        
                        onFolderDeleted(folder);
                        onNotesDeleted(notesToDelete);
                      },
                      child: const Text('Delete Folder and All Content', style: TextStyle(color: WHITE)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: icon_color)),
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
