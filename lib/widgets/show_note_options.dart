import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_style.dart';
import '../models/note.dart';
import '../screens/home_screen/notes_view.dart';

void show_note_options(BuildContext context, List<Note> notes,int index, Future<void> Function() onNoteChanged , void Function(Note) onNoteDeleted, void Function(Note) add_to_favorites) {
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
                        //_renameNote(note);
                      },
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
                        //_addToCollection(note);
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
