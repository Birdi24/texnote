import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:birdwrite/models/HandwrittenNote.dart';
import 'package:birdwrite/models/Note.dart';
import 'package:birdwrite/screens/HandwrittenNoteScreen/main.dart';
import '../app_style.dart';
import 'color_picker.dart';
import 'glass_container.dart';

Future<void> on_new_handwritten_note(
  BuildContext context,
  List<Note> notes,
  Future<void> Function() onNoteCreated,
  int control,
  dynamic add_or_remove_favorite,
  dynamic selected_collection,
) async {
  double screen_width = MediaQuery.of(context).size.width;
  String selectedColor = "1";
  String selectedPaperType = "blank";
  final titleController = TextEditingController(
    text: DateFormat('h:mm a - MMM d, yyyy').format(DateTime.now()),
  );

  return showDialog(
    barrierColor: Colors.transparent,
    context: context,
    builder: (context) {
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
              height: 600,
              width: screen_width > 420 ? 370 : screen_width - 50,
              shadowColor: BG,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'New Handwritten Note',
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
                          hintText: 'Note name',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Color", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),

                      ColorPicker(
                        initialColor: selectedColor,
                        showFullPicker: true,
                        onColorChanged: (color, identifier) {
                          setState(() {
                            selectedColor = identifier ?? "#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}";
                          });
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Paper Style", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _paperTypeOption(setState, "blank", "Blank", selectedPaperType, (val) => selectedPaperType = val),
                          _paperTypeOption(setState, "lined", "Lined", selectedPaperType, (val) => selectedPaperType = val),
                          _paperTypeOption(setState, "dot-grid", "Dots", selectedPaperType, (val) => selectedPaperType = val),
                          _paperTypeOption(setState, "full-grid", "Grid", selectedPaperType, (val) => selectedPaperType = val),
                        ],
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
                            onPressed: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;
                              
                              final dir = await getApplicationDocumentsDirectory();
                              if (!context.mounted) return;

                              Navigator.pop(context); // Close dialog

                              final note = HandwrittenNote(
                                type: NoteType.HandwrittenNote,
                                title: title,
                                path: dir.path,
                                date: DateTime.now(),
                                paperType: selectedPaperType,
                              );
                              note.cover = selectedColor;
                              
                              notes.add(note);
                              
                              await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => HandwrittenNotePage(note: note)),
                              );

                              if (!context.mounted) return;
                              if (control == 2) {
                                add_or_remove_favorite(note);
                              }
                              if (control == 0 && selected_collection != null) {
                                selected_collection.add_to_collections(note);
                              }
                              await onNoteCreated();
                            },
                            child:  Text('Create', style: TextStyle(color: icon_color)),
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

Widget _paperTypeOption(StateSetter setState, String type, String label, String current, Function(String) onSelected) {
  bool selected = type == current;
  return ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (val) {
      if (val) {
        setState(() {
          onSelected(type);
        });
      }
    },
    selectedColor: icon_color.withAlpha(40),
    labelStyle: TextStyle(color: icon_color),
  );
}
