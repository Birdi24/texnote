///
///
//
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:texnote/models/latex.dart';
//
// import '../app_style.dart';
// import '../models/collections.dart';
// import '../models/latex_templates.dart';
// import '../models/TextNote.dart';
// import '../screens/latex_screen/main.dart';
// import 'glass_container.dart';
//
// Future<dynamic> on_new_latex_project(
//     context,
//     notes,
//     collections,
//     onNoteCreated,
//     ) {
//   double screen_width = MediaQuery.of(context).size.width;
//
//   return showDialog(
//     barrierColor: Colors.transparent,
//     context: context,
//     builder: (context) {
//       final titleController = TextEditingController();
//
//       String selectedTemplate = 'Blank';
//
//       final templates = <String, String>{
//         'Blank': LatexTemplates.blank,
//         'Article': LatexTemplates.article,
//         'Report': LatexTemplates.report,
//       };
//
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return Dialog(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             child: glassContainer(
//               bgAlpha: 10,
//               borderAlpha: 244,
//               borderColor: icon_color,
//               height: 320,
//               width: screen_width > 420 ? 370 : screen_width - 50,
//               shadowColor: BG,
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'New Latex Project',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     TextField(
//                       controller: titleController,
//                       autofocus: true,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         enabledBorder: InputBorder.none,
//                         focusedBorder: InputBorder.none,
//                         hintText: 'Project name',
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     DropdownButtonFormField<String>(
//                       value: selectedTemplate,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         enabledBorder: InputBorder.none,
//                         focusedBorder: InputBorder.none,
//                         labelText: 'Template',
//                       ),
//                       items: templates.keys.map((template) {
//                         return DropdownMenuItem<String>(
//                           value: template,
//                           child: Text(template),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         if (value == null) return;
//
//                         setState(() {
//                           selectedTemplate = value;
//                         });
//                       },
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: const Text(
//                             'Cancel',
//                             style: TextStyle(color: icon_color),
//                           ),
//                         ),
//
//                         const SizedBox(width: 8),
//
//                         ElevatedButton(
//                           onPressed: () async {
//                             final title = titleController.text.trim();
//
//                             if (title.isEmpty) return;
//
//                             final body = templates[selectedTemplate]!;
//
//                             final path = await createDirectory(title,body);
//
//                             if (path == "FAIL") return;
//
//                             textNote main = textNote(
//                               "main",
//                               body,
//                               path,
//                               DateTime.now(),
//                             );
//
//                             notes.add(main);
//
//                             Collection project = Collection(
//                               title,
//                               "1",
//                               [main],
//                             );
//
//                             collections.add(project);
//
//                             await Navigator.push<bool>(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => LatexScreen(main),
//                               ),
//                             );
//
//                             await onNoteCreated();
//
//                             Navigator.pop(context);
//                           },
//                           child: const Text(
//                             'Create',
//                             style: TextStyle(color: icon_color),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }