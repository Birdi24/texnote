import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_style.dart';
import '../models/favorite_and_collection_handling.dart';
import '../models/note.dart';
import '../screens/home_screen/notes_view.dart';
import 'glass_container.dart';

void show_note_options(BuildContext context, List<Note> notes,int index, collections, Future<void> Function() onNoteChanged , void Function(Note) onNoteDeleted, void Function(Note) add_to_favorites) {
  double screen_width =  MediaQuery.of(context).size.width;

  showModalBottomSheet(
    context: context,
    backgroundColor: BG,
    builder: (context) {
      return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox( width: screen_width >500 ? 450 : screen_width -50,
              child:Material(
                color: BG,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView( child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Rename note'),
                        onTap: () {
                          Navigator.pop(context);

                          rename_note(
                            context,
                            notes,
                            index, onNoteChanged
                          );
                        }
                    ),

                    ListTile(
                      leading: Icon(Icons.star_outline ,color:  notes[index].is_fav? Colors.red : icon_color),
                      title: notes[index].is_fav? Text('Remove from favorites' ,style: TextStyle(color: Colors.red),) : Text('Add to favorites'),
                      onTap: () {
                        Navigator.pop(context);
                        add_to_favorites(notes[index]);
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.copy_outlined),
                      title: const Text('Duplicate'),
                      onTap: () {
                        Navigator.pop(context);
                        notes[index].duplicate_note(onNoteChanged);
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: const Text('Add to collection'),
                      onTap: () {
                        Navigator.pop(context);

                        showDialog<bool>(
                          barrierColor: Colors.transparent,
                          context: context,
                          builder: (context) {
                            String? selectedCollection;
                            String selectedColor = "1";
                            final collectionController = TextEditingController();

                            return StatefulBuilder(
                              builder: (context, dialogSetState) {
                                final bool creatingNewCollection = collections.isEmpty;

                                final bool canSubmit = creatingNewCollection
                                    ? collectionController.text.trim().isNotEmpty
                                    : selectedCollection != null;

                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  child: glassContainer(
                                    bgAlpha: 10,
                                    borderAlpha: 244,
                                    borderColor: icon_color,
                                    height: 278,
                                    width: screen_width > 420
                                        ? 370
                                        : screen_width - 50,
                                    shadowColor: BG,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [

                                          SizedBox(height: creatingNewCollection ? 20 : 45),

                                          const Text(
                                            "Add to Collection?",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          if (creatingNewCollection) ...[
                                            TextField(
                                              controller: collectionController,
                                              decoration: const InputDecoration(
                                                hintText: "Collection name",
                                              ),
                                              onChanged: (_) {
                                                dialogSetState(() {});
                                              },
                                            ),

                                            const SizedBox(height: 20),

                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: List.generate(6, (index) {
                                                final color = '${index + 1}';
                                                final selected =
                                                    selectedColor == color;

                                                return GestureDetector(
                                                  onTap: () {
                                                    dialogSetState(() {
                                                      selectedColor = color;
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 35,
                                                    height: 35,
                                                    decoration: BoxDecoration(
                                                      color: collection_color(color),
                                                      borderRadius:
                                                      BorderRadius.circular(8),
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
                                          ] else ...[
                                            DropdownButton<String>(
                                              isExpanded: true,
                                              value: selectedCollection,
                                              hint: const Text(
                                                "Select a collection",
                                              ),
                                              items: collections
                                                  .map<DropdownMenuItem<String>>(
                                                    (collection) {
                                                  return DropdownMenuItem<String>(
                                                    value: collection.title,
                                                    child: Text(collection.title),
                                                  );
                                                },
                                              ).toList(),
                                              onChanged: (value) {
                                                dialogSetState(() {
                                                  selectedCollection = value;
                                                });
                                              },
                                            ),
                                          ],

                                          const SizedBox(height: 20),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text(
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
                                                  if (creatingNewCollection) {
                                                    final title =
                                                    collectionController
                                                        .text
                                                        .trim();

                                                    collections.add(
                                                      Collection(
                                                        title,
                                                        selectedColor,
                                                        [notes[index]],
                                                      ),
                                                    );
                                                  } else {
                                                    final collection =
                                                    collections.firstWhere(
                                                          (c) =>
                                                      c.title ==
                                                          selectedCollection,
                                                    );

                                                    if (!collection.notes
                                                        .contains(notes[index])) {
                                                      collection.notes
                                                          .add(notes[index]);
                                                    }
                                                  }

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
                          },
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.ios_share_outlined),
                      title: const Text('Export note'),
                      onTap: () {
                        Navigator.pop(context);
                        //_addToCollection(note);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete note',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        delete_alert(context,notes,index, onNoteDeleted);
                      },
                    ),
                  ],
                ),
                ),
              ))
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
          width: screen_width > 420
              ? 370
              : screen_width - 50,
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
                      child: const Text(
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

                        if (newTitle.isEmpty) return;
                        final oldTitle = notes[index].title;
                        notes[index].saveNote(DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now()), oldTitle);
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