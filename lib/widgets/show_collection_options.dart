import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../app_style.dart';
import '../models/Note.dart';
import '../models/collections.dart';
import 'glass_container.dart';


void show_collection_options(
    BuildContext context,
    List<Collection> collections,
    int index,
    List<Note> allNotes,
    Future<void> Function() onCollectionChanged,
    void Function(Collection) onCollectionDeleted,
    void Function(List<Note>) onNotesDeleted) {

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      final screen_width = MediaQuery.of(context).size.width;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: screen_width > 470 ? 420 : screen_width - 50,
          decoration: const BoxDecoration(
            color: BG,
            borderRadius: BorderRadius.vertical(
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
                  title: const Text('Rename collection'),
                  onTap: () {
                    Navigator.pop(context);
                    rename_collection_dialog(
                      context,
                      collections,
                      index,
                      onCollectionChanged,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(LucideIcons.palette),
                  title: const Text('Change color'),
                  onTap: () {
                    Navigator.pop(context);
                    change_collection_color_dialog(
                      context,
                      collections,
                      index,
                      onCollectionChanged,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(LucideIcons.plus),
                  title: const Text('Add notes'),
                  onTap: () {
                    Navigator.pop(context);
                    add_notes_to_collection_dialog(
                      context,
                      collections,
                      index,
                      allNotes,
                      onCollectionChanged,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(LucideIcons.minus),
                  title: const Text('Delete notes'),
                  onTap: () {
                    Navigator.pop(context);
                    delete_notes_from_collection_dialog(
                      context,
                      collections,
                      index,
                      onCollectionChanged,
                      onNotesDeleted,
                    );
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    LucideIcons.trash_2,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete collection',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    delete_collection_alert(
                      context,
                      collections,
                      index,
                      onCollectionDeleted,
                      onNotesDeleted,
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void rename_collection_dialog(
    BuildContext context,
    List<Collection> collections,
    int index,
    Future<void> Function() onCollectionChanged) {
  final controller = TextEditingController(text: collections[index].title);
  final screen_width = MediaQuery.of(context).size.width;

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
          width: screen_width > 420 ? 370 : screen_width - 50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Rename Collection",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Collection name",
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: icon_color)),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: () async {
                        final newTitle = controller.text.trim();
                        if (newTitle.isEmpty) return;
                        collections[index].rename_collection(newTitle);
                        await Collection.save_collections(collections);
                        await onCollectionChanged();
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

void change_collection_color_dialog(
    BuildContext context,
    List<Collection> collections,
    int index,
    Future<void> Function() onCollectionChanged) {
  final screen_width = MediaQuery.of(context).size.width;
  final List<String> colorOptions = ["1", "2", "3", "4", "5", "6"];

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
          height: 280,
          width: screen_width > 420 ? 370 : screen_width - 50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Collection Color",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: colorOptions.map((colorId) {
                    bool isSelected = collections[index].color == colorId;
                    return GestureDetector(
                      onTap: () async {
                        collections[index].color = colorId;
                        await Collection.save_collections(collections);
                        await onCollectionChanged();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: collection_color(colorId),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? icon_color : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 25),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: icon_color)),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void add_notes_to_collection_dialog(
    BuildContext context,
    List<Collection> collections,
    int index,
    List<Note> allNotes,
    Future<void> Function() onCollectionChanged) {
  final screen_width = MediaQuery.of(context).size.width;
  Collection currentCollection = collections[index];

  // Notes NOT in this collection
  List<Note> availableNotes = allNotes.where((note) => !currentCollection.notes.any((n) => n.path == note.path)).toList();
  List<Note> selectedNotes = [];

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
              height: 450,
              width: screen_width > 420 ? 370 : screen_width - 50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Add Notes",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (availableNotes.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedNotes.length == availableNotes.length) {
                                selectedNotes.clear();
                              } else {
                                selectedNotes = List.from(availableNotes);
                              }
                            });
                          },
                          child: Text(selectedNotes.length == availableNotes.length ? "Deselect All" : "Select All"),
                        ),
                      ),
                    Expanded(
                      child: availableNotes.isEmpty
                          ? const Center(child: Text("No more notes to add"))
                          : ListView.builder(
                              itemCount: availableNotes.length,
                              itemBuilder: (context, i) {
                                final note = availableNotes[i];
                                bool isSelected = selectedNotes.contains(note);
                                return CheckboxListTile(
                                  title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(note.type.name, style: const TextStyle(fontSize: 10)),
                                  value: isSelected,
                                  activeColor: collection_color(currentCollection.color),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedNotes.add(note);
                                      } else {
                                        selectedNotes.remove(note);
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
                          child: const Text("Cancel", style: TextStyle(color: icon_color)),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: selectedNotes.isEmpty
                              ? null
                              : () async {
                                  for (var note in selectedNotes) {
                                    currentCollection.add_to_collections(note);
                                  }
                                  await Collection.save_collections(collections);
                                  await onCollectionChanged();
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text("Add"),
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

void delete_collection_alert(
    BuildContext context,
    List<Collection> collections,
    int index,
    void Function(Collection) onCollectionDeleted,
    void Function(List<Note>) onNotesDeleted) {
  final screen_width = MediaQuery.of(context).size.width;
  Collection collection = collections[index];

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: glassContainer(
          bgAlpha: 140,
          borderAlpha: 244,
          borderColor: Colors.red,
          height: 330,
          width: screen_width > 380 ? 330 : screen_width - 50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Delete Collection?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  textAlign: TextAlign.center,
                  'How would you like to delete\n"${collection.title}"?',
                ),
                const SizedBox(height: 25),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        collections.removeAt(index);
                        await Collection.save_collections(collections);
                        onCollectionDeleted(collection);
                      },
                      child: const Text('Delete Collection only'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        List<Note> notesToDelete = List.from(collection.notes);
                        
                        // Remove collection first
                        collections.removeAt(index);
                        await Collection.save_collections(collections);
                        
                        // Delete each note
                        for (var note in notesToDelete) {
                          await note.delete();
                        }
                        
                        onCollectionDeleted(collection);
                        onNotesDeleted(notesToDelete);
                      },
                      child: const Text('Delete with all notes', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: icon_color)),
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

void delete_notes_from_collection_dialog(
    BuildContext context,
    List<Collection> collections,
    int index,
    Future<void> Function() onCollectionChanged,
    void Function(List<Note>) onNotesDeleted) {
  final screen_width = MediaQuery.of(context).size.width;
  Collection currentCollection = collections[index];
  List<Note> collectionNotes = List.from(currentCollection.notes);
  List<Note> selectedNotes = [];

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
              bgAlpha: 140,
              borderAlpha: 244,
              borderColor: icon_color,
              height: 480,
              width: screen_width > 420 ? 370 : screen_width - 50,
              shadowColor: BG,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Delete Notes",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (collectionNotes.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedNotes.length == collectionNotes.length) {
                                selectedNotes.clear();
                              } else {
                                selectedNotes = List.from(collectionNotes);
                              }
                            });
                          },
                          child: Text(selectedNotes.length == collectionNotes.length ? "Deselect All" : "Select All"),
                        ),
                      ),
                    Expanded(
                      child: collectionNotes.isEmpty
                          ? const Center(child: Text("Collection is empty"))
                          : ListView.builder(
                              itemCount: collectionNotes.length,
                              itemBuilder: (context, i) {
                                final note = collectionNotes[i];
                                bool isSelected = selectedNotes.contains(note);
                                return CheckboxListTile(
                                  title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(note.type.name, style: const TextStyle(fontSize: 10)),
                                  value: isSelected,
                                  activeColor: Colors.red,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedNotes.add(note);
                                      } else {
                                        selectedNotes.remove(note);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 15),
                    Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          onPressed: selectedNotes.isEmpty
                              ? null
                              : () async {
                                  for (var note in selectedNotes) {
                                    currentCollection.notes.removeWhere((n) => n.path == note.path);
                                  }
                                  await Collection.save_collections(collections);
                                  await onCollectionChanged();
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: const Text("Remove from Collection"),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          onPressed: selectedNotes.isEmpty
                              ? null
                              : () async {
                                  // Confirmation for permanent delete
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text("Delete Permanently?"),
                                      content: Text("Are you sure you want to permanently delete ${selectedNotes.length} note(s) from disk?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    for (var note in selectedNotes) {
                                      currentCollection.notes.removeWhere((n) => n.path == note.path);
                                      await note.delete();
                                    }
                                    await Collection.save_collections(collections);
                                    onNotesDeleted(selectedNotes);
                                    await onCollectionChanged();
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
                          child: const Text("Delete Permanently", style: TextStyle(color: Colors.red)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: icon_color)),
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
