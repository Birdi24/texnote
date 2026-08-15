import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../app_style.dart';
import '../models/favorite_and_collection_handling.dart';
import '../models/note.dart';
import '../screens/note_screen/main.dart';
import 'glass_container.dart';
import 'package:flutter/cupertino.dart';

void new_file_options(BuildContext context, Future<void> Function() onNoteCreated, collections, notes ,control, add_or_remove_favorite, selected_collection) {
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
                      title: const Text('New note'),
                      onTap: () async {
                        Navigator.pop(context);
                        print("New Note Started");
                        final note = Note("","",(await getApplicationDocumentsDirectory()).path,DateTime.now());
                        notes.add(note);
                        await Navigator.push<bool>( context,
                          MaterialPageRoute( builder: (_) => NoteScreen(note)),
                        );
                        if (control == 2) {add_or_remove_favorite(note);}
                        if (control == 0 && selected_collection != null) {selected_collection.add_to_collections(note); }
                        await onNoteCreated();
                        print("Back to home screen from note screen: new note");
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: const Text('New Collection'),
                      onTap: () {
                        Navigator.pop(context);

                        showDialog(
                          barrierColor: Colors.transparent,
                          context: context,
                          builder: (context) {
                            String selectedColor = "1";
                            final titleController = TextEditingController();

                            return StatefulBuilder(
                              builder: (context, setState) {
                                return Dialog(
                                  backgroundColor: BG,
                                  elevation: 0,
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
                                          const Text(
                                            'New Collection',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          TextField(
                                            controller: titleController,
                                            autofocus: true,

                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              hintText: 'Collection name',
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

                  ],
                ),
                ),
              ))
      );
    },
  );
}

Widget new_note_button( BuildContext context, Future<void> Function() onNoteCreated, collections, notes, control, add_or_remove_favorite,selected_collection,
bool selection_text,

    ) {
  return GestureDetector(
    onTap: () { new_file_options(context, onNoteCreated, collections,notes, control, add_or_remove_favorite ,selected_collection);},
    child: glassContainer(
      width: 170,
      height: 78,
      borderAlpha: 50,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, size: 22, color: icon_color,),
          const SizedBox(width: 8),
          Text( selection_text! ? "New Collection" : "New Note", style: AppStyles.icon_text ),
        ],
      ),
    ),
  );
}

