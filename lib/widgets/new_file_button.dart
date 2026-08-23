import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:texnote/models/HandwrittenNote.dart';
import 'package:texnote/screens/latex_screen/main.dart';
import 'package:texnote/widgets/on_new_collection.dart';
import 'package:texnote/widgets/on_new_latex_project.dart';
import '../app_style.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';
import '../screens/HanwrittenNoteScreen/main.dart';
import '../screens/note_screen/main.dart';
import 'glass_container.dart';
import 'package:flutter/cupertino.dart';

void new_file_options(BuildContext context, Future<void> Function() onNoteCreated, collections, List<Note>notes ,control, add_or_remove_favorite, selected_collection) {
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
                      leading: const Icon(LucideIcons.type_outline),
                      title: const Text('New note'),
                      onTap: () async {
                        Navigator.pop(context);
                        print("New Note Started");
                        final note = TextNote(type: NoteType.TextNote,title: "", body: "", path: (await getApplicationDocumentsDirectory()).path, date: DateTime.now());
                        notes.add(note);
                        await Navigator.push<bool>( context,
                          MaterialPageRoute( builder: (_) => TextNoteScreen(note)),
                        );
                        if (control == 2) {add_or_remove_favorite(note);}
                        if (control == 0 && selected_collection != null) {selected_collection.add_to_collections(note); }
                        await onNoteCreated();
                        print("Back to home screen from note screen: new note");
                      },
                    ),

                    ListTile(
                      leading: const RotatedBox(quarterTurns: 3, child: Icon(LucideIcons.pen_tool),),
                      title: const Text('New Handwritten Note'),
                      onTap: () async {
                        Navigator.pop(context);
                        print("New Note Started");
                        final note = HandwrittenNote(type: NoteType.HandwrittenNote,title: "", path: (await getApplicationDocumentsDirectory()).path, date: DateTime.now());
                        //notes.add(note);
                        await Navigator.push<bool>( context,
                          MaterialPageRoute( builder: (_) => HandwrittenNotePage(note:note)),
                        );
                        if (control == 2) {add_or_remove_favorite(note);}
                        if (control == 0 && selected_collection != null) {selected_collection.add_to_collections(note); }
                        await onNoteCreated();
                        print("Back to home screen from note screen: new note");
                      },
                    ),

                    ListTile(
                      leading: const Icon(LucideIcons.square_function),
                      title: const Text('New Latex Project'),
                      onTap: () async {
                        Navigator.pop(context);
                        print("New Latex Project Started");
                        //on_new_latex_project(context, notes, collections, onNoteCreated); HandwrittenNotePage
                        await onNoteCreated();
                        print("Back to home screen from note screen: new note");
                      },
                    ),

                    ListTile(
                      leading: const Icon(LucideIcons.folder_plus),
                      title: const Text('New Collection'),
                      onTap: () {
                        Navigator.pop(context);
                        on_new_collection(context, collections, onNoteCreated,false);
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.ios_share_outlined),
                      title: const Text('Export note'),
                      onTap: () {
                        Navigator.pop(context);
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

