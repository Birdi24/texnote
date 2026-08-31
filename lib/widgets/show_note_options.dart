import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:texnote/models/HandwrittenNote.dart';

import '../app_style.dart';
import '../models/Note.dart';
import 'color_picker.dart';
import 'glass_container.dart';
import 'on_new_collection.dart';

Future<bool?> delete_alert(BuildContext context, List<Note> notes, int index, void Function(Note) onNoteDeleted) {
  final screen_width = MediaQuery.of(context).size.width;
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
              width: screen_width > 380 ? 330 : screen_width - 50,
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
                        'Are you sure you want to delete\n"${notes[index].title}"?',
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
                            onPressed: () async{
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
    collections,
    Future<void> Function() onNoteChanged,
    void Function(Note) onNoteDeleted,
    void Function(Note) onNoteAdded,
    void Function(Note) add_to_favorites) {

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      final screen_width = MediaQuery.of(context).size.width;

      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: screen_width >470 ? 420 : screen_width -50,
          decoration:  BoxDecoration(
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
                  title: const Text('Rename note'),
                  onTap: () {
                    Navigator.pop(context);
                    rename_note(
                      context,
                      notes,
                      index,
                      onNoteChanged,
                    );
                  },
                ),

                if (notes[index].type == NoteType.HandwrittenNote)
                  ListTile(
                    leading: const Icon(LucideIcons.palette),
                    title: const Text('Change cover color'),
                    onTap: () {
                      Navigator.pop(context);
                      change_handwritten_note_color_dialog(
                        context,
                        notes,
                        index,
                        onNoteChanged,
                      );
                    },
                  ),

                ListTile(
                  leading: Icon(
                    LucideIcons.star,
                    color: notes[index].isFavorite
                        ? RED
                        : icon_color,
                  ),
                  title: notes[index].isFavorite
                      ? const Text(
                    'Remove from favorites',
                    style: TextStyle(color: RED),
                  )
                      : const Text('Add to favorites'),
                  onTap: () {
                    Navigator.pop(context);
                    add_to_favorites(notes[index]);
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
                  leading: const Icon(LucideIcons.folder),
                  title: const Text('Add to collection'),
                  onTap: () {
                    Navigator.pop(context);

                    if (collections.isEmpty) {
                      on_new_collection(
                        context,
                        collections,
                        onNoteChanged,
                        false,
                      );
                      return;
                    }

                    final screen_width =
                        MediaQuery.of(context).size.width;

                    showDialog<bool>(
                      barrierColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        String? selectedCollection;

                        return StatefulBuilder(
                          builder: (context, dialogSetState) {
                            final canSubmit =
                                selectedCollection != null;

                            return Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: glassContainer(
                                bgAlpha: 10,
                                borderAlpha: 244,
                                borderColor: icon_color,
                                height: 240,
                                width: screen_width > 430
                                    ? 380
                                    : screen_width - 50,
                                shadowColor: BG,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 10),

                                      const Text(
                                        "Add to Collection",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      Container(
                                        width: screen_width > 380
                                            ? 310
                                            : screen_width - 70,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: icon_color,
                                            width: 1,
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child:
                                        DropdownButton<String>(
                                          menuWidth:
                                          screen_width > 380
                                              ? 310
                                              : screen_width - 70,
                                          menuMaxHeight: 300,
                                          isExpanded: true,
                                          underline:
                                          const SizedBox(),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          value: selectedCollection,
                                          hint: const Text(
                                            "Select a collection",
                                          ),
                                          items: collections
                                              .map<
                                              DropdownMenuItem<String>>(
                                                (collection) {
                                              return DropdownMenuItem<
                                                  String>(
                                                value:
                                                collection.title,
                                                child: Text(
                                                  collection.title,
                                                ),
                                              );
                                            },
                                          ).toList(),
                                          onChanged: (value) {
                                            dialogSetState(() {
                                              selectedCollection =
                                                  value;
                                            });
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: icon_color,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 15),

                                          ElevatedButton(
                                            onPressed: !canSubmit
                                                ? null
                                                : () {
                                              final collection =
                                              collections
                                                  .firstWhere(
                                                    (c) =>
                                                c.title ==
                                                    selectedCollection,
                                              );

                                              if (!collection
                                                  .notes
                                                  .contains(
                                                notes[index],
                                              )) {
                                                collection.notes
                                                    .add(
                                                  notes[index],
                                                );
                                              }

                                              onNoteChanged();

                                              Navigator.pop(
                                                  context);
                                            },
                                            child:
                                            const Text("Done"),
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
                  },
                ),

                ListTile(
                  leading:
                  const Icon(LucideIcons.file_up),
                  title: const Text('Export note'),
                  onTap: () {
                    Navigator.pop(context);
                    notes[index].export();
                  },
                ),

                ListTile(
                  leading:
                  const Icon(LucideIcons.upload),
                  title: const Text('Export as PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    notes[index].exportAsPdf();
                  },
                ),

                const Divider(height: 1),

                ListTile(
                  leading: const Icon(
                    LucideIcons.trash_2,
                    color: RED,
                  ),
                  title: const Text(
                    'Delete note',
                    style: TextStyle(color: RED),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    delete_alert(
                      context,
                      notes,
                      index,
                      onNoteDeleted,
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

void rename_note(
    BuildContext context,
    List<Note> notes,
    int index,
    Function() onNoteCreated
    ) {
  final controller = TextEditingController(
    text: notes[index].title,
  );
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
          width: screen_width > 420 ? 370 : screen_width -50,
          shadowColor: BG,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                const Text(
                  "Rename Note",
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
                    hintText: "Note name",
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: icon_color,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    ElevatedButton(
                      onPressed: () async {
                        final newTitle = controller.text.trim();
                        debugPrint(newTitle);
                        if (newTitle.isEmpty) return;
                        final oldTitle = notes[index].title;
                        notes[index].title = newTitle;
                        notes[index].save(oldTitle);
                        await onNoteCreated();

                        Navigator.pop(context);
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

void change_handwritten_note_color_dialog(
    BuildContext context,
    List<Note> notes,
    int index,
    Future<void> Function() onNoteChanged) {
  final screen_width = MediaQuery.of(context).size.width;
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
                width: screen_width > 420 ? 370 : screen_width - 50,
                shadowColor: BG,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        "Cover Color",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                              await onNoteChanged();
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
