///
///
/// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
//
// import '../../app_style.dart';
// import '../../models/Note.dart';
// import '../../models/TextNote.dart';
// import '../../widgets/glass_container.dart';
//
// class LatexScreen extends StatefulWidget {
//   final Note note;
//
//   const LatexScreen(this.note, {super.key});
//
//   @override
//   State<LatexScreen> createState() => _LatexScreenState();
// }
//
// class _LatexScreenState extends State<LatexScreen> {
//   final ScrollController _editorScrollController = ScrollController();
//   final ScrollController _gutterScrollController = ScrollController();
//   bool changed = false;
//   Timer? _autoSaveTimer;
//
//   var bodyController = TextEditingController();
//   String old_title = "";
//   final _currentTime = DateFormat('MMM d, yyyy - h:mm a').format(DateTime.now());
//   double font_size = 16;
//
//   late File texFile;
//
//   @override
//   void initState() {
//     super.initState();
//     bodyController = TextEditingController(text: widget.note.body,);
//     bodyController.addListener(_markChanged);
//     old_title = widget.note.title;
//     _autoSaveTimer = Timer.periodic( const Duration(minutes: 1), (_) => save(),);
//     _editorScrollController.addListener(() {
//       if (!_gutterScrollController.hasClients) return;
//
//       if (_gutterScrollController.offset !=
//           _editorScrollController.offset) {
//         _gutterScrollController.jumpTo(
//           _editorScrollController.offset.clamp(
//             0.0,
//             _gutterScrollController.position.maxScrollExtent,
//           ),
//         );
//       }
//     });
//     texFile = File(
//       '${widget.note.path}/main.tex',
//     );
//   }
//
//
//   void _markChanged() {
//     if (!changed) {
//       setState(() {
//         changed = true;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     bodyController.dispose();
//     _autoSaveTimer?.cancel();
//     _editorScrollController.dispose();
//     _gutterScrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> save() async {
//     if (!changed) {debugPrint("Save skipped: no changes");return;}
//     debugPrint("Saving...");
//     widget.note.body = bodyController.text;
//     widget.note.title = (widget.note.title == "") ? DateFormat('MMM d, yyyy - h:mm:ss a').format(DateTime.now()) : widget.note.title;
//
//     await widget.note.save(_currentTime, "main",);
//     if (!mounted) return;
//     setState(() {
//       changed = false;
//     });
//     debugPrint("Auto-saved at ${DateFormat('MMM d, yyyy - h:mm:ss a').format(DateTime.now())}");
//   }
//
//   Future<void> compile() async {
//     await save();
//
//     // run LaTeX compiler with
//     // workingDirectory = widget.main.path
//
//     // generate:
//     // widget.main.path/main.pdf
//
//     // reload PDF viewer
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     return PopScope(
//         canPop: true,
//         onPopInvokedWithResult: (didPop, result) async {
//           if (changed){
//             await save();
//           }
//         },
//         child: Scaffold(
//           body: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.only(
//                 left: 25,
//                 right: 25,
//               ),
//               child: Column(
//                 children: [
//                   plain_text_view(context, bodyController,font_size, _editorScrollController,_gutterScrollController)
//                 ],
//               ),
//             ),
//           ),
//         )
//     );
//   }
// }
//
// Widget plain_text_view(
//     BuildContext context,
//     TextEditingController bodyController,
//     double font_size,
//     _editorScrollController,
//     _gutterScrollController
//     ) {
//   final textStyle = AppStyles.bodytext.copyWith(
//     fontSize: font_size,
//     height: 1.5,
//   );
//
//   const double horizontalPadding = 0;
//   const double verticalPadding = 25;
//   const double gutterWidth = 22;
//
//   return Expanded(
//     child: glassContainer(
//       bgAlpha: 10,
//       borderAlpha: 160,
//       borderColor: icon_color,
//       shadowColor: icon_color,
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final editorWidth =
//               constraints.maxWidth -
//                   gutterWidth -
//                   horizontalPadding * 2 -
//                   30;
//
//           return Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // --------------------------------
//               // GUTTER
//               // --------------------------------
//               SizedBox(
//                 width: gutterWidth,
//                 child: AnimatedBuilder(
//                   animation: bodyController,
//                   builder: (context, _) {
//                     return SingleChildScrollView(
//                       controller: _gutterScrollController,
//                       physics: const NeverScrollableScrollPhysics(),
//                       child: Padding(
//                         padding: const EdgeInsets.only(
//                           top: verticalPadding,
//                         ),
//                         child: _buildLineNumbers(
//                           context,
//                           bodyController.text,
//                           textStyle,
//                           editorWidth,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(width: 10,),
//
//               SizedBox(width: 4,height:double.maxFinite , child: DecoratedBox(decoration: BoxDecoration(color: accent) ),),
//
//               SizedBox(width: 10,),
//               // --------------------------------
//               // EDITOR
//               // --------------------------------
//               SizedBox(
//                 width: editorWidth,
//                 child: Focus(
//                   onKeyEvent: (node, event) {
//                     if (event is KeyDownEvent &&
//                         event.logicalKey == LogicalKeyboardKey.tab) {
//
//                       final text = bodyController.text;
//                       final selection = bodyController.selection;
//
//                       final newText = text.replaceRange(
//                         selection.start,
//                         selection.end,
//                         '\t',
//                       );
//
//                       bodyController.value = TextEditingValue(
//                         text: newText,
//                         selection: TextSelection.collapsed(
//                           offset: selection.start + 1,
//                         ),
//                       );
//
//                       return KeyEventResult.handled;
//                     }
//
//                     if (event is KeyDownEvent &&
//                         event.logicalKey == LogicalKeyboardKey.enter) {
//                       final text = bodyController.text;
//                       final selection = bodyController.selection;
//
//                       final newText = text.replaceRange(
//                         selection.start,
//                         selection.end,
//                         '\n',
//                       );
//
//                       bodyController.value = TextEditingValue(
//                         text: newText,
//                         selection: TextSelection.collapsed(
//                           offset: selection.start + 1,
//                         ),
//                       );
//                     }
//
//                     return KeyEventResult.ignored;
//                   },
//                   child: TextField(
//                     controller: bodyController,
//                     scrollController: _editorScrollController,
//
//                     maxLines: null,
//                     expands: true,
//
//                     keyboardType: TextInputType.multiline,
//                     textInputAction: TextInputAction.newline,
//
//                     textAlignVertical: TextAlignVertical.top,
//
//                     style: textStyle,
//
//                     decoration: InputDecoration(
//                       hintText: "Start your note here...",
//                       hintStyle: textStyle,
//                       border: InputBorder.none,
//                       isCollapsed: true,
//                       contentPadding: const EdgeInsets.only(
//                         top: verticalPadding,
//                         bottom: verticalPadding,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     ),
//   );
// }
//
// Widget _buildLineNumbers(
//     BuildContext context,
//     String text,
//     TextStyle style,
//     double width,
//     ) {
//   final lines = text.split('\n');
//
//   final widgets = <Widget>[];
//
//   for (int i = 0; i < lines.length; i++) {
//     final line = lines[i];
//
//     final painter = TextPainter(
//       text: TextSpan(
//         text: line.isEmpty ? ' ' : line,
//         style: style,
//       ),
//       textDirection: Directionality.of(context),
//       maxLines: null,
//     );
//
//     painter.layout(
//       maxWidth: width,
//     );
//
//     final metrics = painter.computeLineMetrics();
//
//     final visualLineCount = metrics.isEmpty
//         ? 1
//         : metrics.length;
//
//     final height = metrics.fold<double>(
//       0,
//           (total, metric) => total + metric.height,
//     );
//
//     widgets.add(
//       SizedBox(
//         height: height,
//         child: Align(
//           alignment: Alignment.topRight,
//           child: Text(
//             '${i + 1}',
//             style: style.copyWith(
//               color: Colors.grey,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.end,
//     children: widgets,
//   );
// }