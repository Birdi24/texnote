import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:birdwrite/widgets/on_new_folder.dart';
import 'package:birdwrite/widgets/on_new_handwritten_note.dart';

import '../app_style.dart';
import '../io/browse_file.dart';
import '../models/Note.dart';
import '../models/TextNote.dart';
import '../models/folder.dart';
import '../screens/HandwrittenNoteScreen/main.dart';
import '../screens/TextNoteScreen/main.dart';
import 'glass_container.dart';

void run_async(Function(String) await_f1, Function() f2) async {
  await await_f1("");
  f2();
}

void new_file_options(BuildContext context, Future<void> Function([Note?]) onNoteCreated, List<Folder> folders, List<Note> notes, int control, dynamic addOrRemoveFavorite, Folder? selectedFolder) {
  double screenWidth = MediaQuery.of(context).size.width;

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    backgroundColor: BG,
    builder: (modalContext) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: screenWidth > 500 ? 450 : screenWidth - 50,
          child: Material(
            color: BG,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.type_outline),
                    title: const Text('New note'),
                    onTap: () async {
                      Navigator.pop(modalContext);
                      final appDir = await getApplicationDocumentsDirectory();
                      final String targetPath = selectedFolder?.path ?? appDir.path;
                      
                      final note = TextNote(
                        type: NoteType.TextNote,
                        title: "",
                        body: "",
                        path: p.canonicalize(targetPath),
                        date: DateTime.now(),
                      );
                      
                      // Save and refresh in background to ensure Home Screen is ready on return
                      run_async(note.save, onNoteCreated);
                      
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TextNoteScreen(note)),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const RotatedBox(quarterTurns: 3, child: Icon(LucideIcons.pen_tool)),
                    title: const Text('New Handwritten Note'),
                    onTap: () {
                      Navigator.pop(modalContext);
                      on_new_handwritten_note(context, notes, onNoteCreated, control, addOrRemoveFavorite, selectedFolder);
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.folder_plus),
                    title: const Text('New Folder'),
                    onTap: () async {
                      Navigator.pop(modalContext);
                      await on_new_folder(context, selectedFolder, onNoteCreated);
                    },
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.file_up),
                    title: const Text('Import PDF'),
                    onTap: () async {
                      Navigator.pop(modalContext);
                      final note = await FileOpenerScreen().importPdf();
                      if (note != null && context.mounted) {
                        // Move to current folder if needed
                        if (selectedFolder != null) {
                          await note.move_to(selectedFolder.path);
                        }
                        notes.add(note);
                        if (control == 2) {
                          addOrRemoveFavorite(note);
                        }
                        // Move and refresh in background
                        run_async((_) => note.save(""), onNoteCreated);
                        
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HandwrittenNotePage(note: note)),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
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

Widget new_note_button(BuildContext context, Future<void> Function([Note?]) onNoteCreated, List<Folder> folders, List<Note> notes, int control, dynamic addOrRemoveFavorite, Folder? selectedFolder, bool selectionText) {
  return GestureDetector(
    onTap: () {
      new_file_options(context, onNoteCreated, folders, notes, control, addOrRemoveFavorite, selectedFolder);
    },
    child: glassContainer(
      width: 170,
      height: 78,
      borderAlpha: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 22, color: icon_color),
          const SizedBox(width: 8),
          Text(selectionText ? "New Folder" : "New Note", style: AppStyles.icon_text.copyWith(color: icon_color)),
        ],
      ),
    ),
  );
}
