

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:texnote/widgets/table_picker.dart';
import '../../app_style.dart';
import 'note_body_helper_functions.dart';

Widget base_button(context,TextEditingController bodyController,
    valueL,valueR, icon) {
  return Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: SizedBox(
      width: 35,
      height: 35,
      child: OutlinedButton(
        onPressed: () {
          wrapSelection(bodyController, valueL, valueR);
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          iconColor: icon_color,
          side: const BorderSide(
            color: icon_color,
            width: 1,
          ),
        ),
        child: icon,
      ),
    ),
  );
}
Widget bold_button(context,TextEditingController bodyController){
  return base_button(context, bodyController, "**","**", Icon(Icons.format_bold));
}

Widget italic_button(context,TextEditingController bodyController) {
  return base_button(context, bodyController, "*","*", Icon(Icons.format_italic));
}

Widget code_button(context,TextEditingController bodyController) {
  return base_button(context, bodyController, "```\n", "\n```", Icon(Icons.code));
}

Widget block_button(context,TextEditingController bodyController) {
  return base_button(context, bodyController, "> ", "", Icon(Icons.format_quote));
}

Widget checklist_button(context,TextEditingController bodyController) {
  return base_button(context, bodyController, "- [x] \n- [ ] ", "", Icon(Icons.checklist_rounded));
}

Widget numbered_list_button(context,TextEditingController bodyController) {
  return base_button(context, bodyController, "1.\n2.\n3.\n4. ", "", Icon(Icons.format_list_numbered_sharp));
}
Widget dot_list_button(context,TextEditingController bodyController) {
  return base_button(context, bodyController, "- \n- \n- \n- ", "", Icon(Icons.format_list_bulleted));
}

Widget table_button(
    BuildContext context,
    TextEditingController bodyController,
    ) {
  return Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: SizedBox(
      width: 35,
      height: 35,
      child: OutlinedButton(
        onPressed: () {
          table_picker(context, bodyController);
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          iconColor: icon_color,
          side: const BorderSide(
            color: icon_color,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.table_chart_outlined,
        ),
      ),
    ),
  );
}

Widget headings_dropdown(bodyController) {
  return Transform.translate(
      offset: const Offset(0, 2),
      child: Container(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  height: 35,
  width: 180,
  decoration: BoxDecoration(
    color: BG,
    border: Border.all( color: icon_color, width: 1),
    borderRadius: BorderRadius.circular(18),
  ),
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      isDense: true,
      borderRadius: BorderRadius.circular(12),
      iconEnabledColor: icon_color,
      dropdownColor: BG,
      hint: Text( 'Heading', style: AppStyles.bodytext.copyWith(color: icon_color)),
      items: [
        DropdownMenuItem(value: '# ', child: MarkdownBody(data: '# Heading 1' ,shrinkWrap: true,styleSheet: markdown_style(14.0))),
        DropdownMenuItem(value: '## ', child: MarkdownBody(data: '## Heading 2', shrinkWrap: true,styleSheet: markdown_style(14.0))),
        DropdownMenuItem(value: '### ', child: MarkdownBody(data: '### Heading 3' ,shrinkWrap: true,styleSheet: markdown_style(14.0))),
        DropdownMenuItem(value: '#### ', child: MarkdownBody(data: '#### Heading 4' ,shrinkWrap: true,styleSheet: markdown_style(14.0))),
        DropdownMenuItem(value: '##### ', child: MarkdownBody(data: '##### Heading 5', shrinkWrap: true,styleSheet: markdown_style(14.0))),
      ],
      onChanged: (heading) {
        if (heading == null) return;
        wrapSelection(bodyController, heading, "");
      },
    ),
  ),
  )
  );
}
