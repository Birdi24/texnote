import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../screens/note_screen/note_body_helper_functions.dart';

class TablePicker extends StatefulWidget {
  final void Function(int rows, int columns) onSelected;

  const TablePicker({
    super.key,
    required this.onSelected,
  });

  @override
  State<TablePicker> createState() => _TablePickerState();
}

class _TablePickerState extends State<TablePicker> {
  int selectedRows = 1;
  int selectedColumns = 1;

  final int maxRows = 8;
  final int maxColumns = 8;

  @override
  Widget build(BuildContext context) {
    const cellSize = 26.0;

    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(details.globalPosition);

        // Account for the padding around the grid
        final x = local.dx - 12;
        final y = local.dy - 45;

        final column = (x / cellSize).floor();
        final row = (y / cellSize).floor();

        if (row >= 0 &&
            row < maxRows &&
            column >= 0 &&
            column < maxColumns) {
          setState(() {
            selectedRows = row + 1;
            selectedColumns = column + 1;
          });
        }
      },

      // THIS fires when the finger is released
      onPanEnd: (_) {
        widget.onSelected(
          selectedRows,
          selectedColumns,
        );
      },

      child: Container(
        padding: const EdgeInsets.all(12),
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$selectedColumns × $selectedRows",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            Column(
              children: List.generate(maxRows, (row) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(maxColumns, (column) {
                    final isSelected =
                        row < selectedRows &&
                            column < selectedColumns;

                    return Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                        ),
                        color: isSelected
                            ? Colors.blue.withOpacity(0.25)
                            : Colors.transparent,
                      ),
                    );
                  }),
                );
              }),
            ),

            const SizedBox(height: 8),

            Text(
              "$selectedColumns columns × $selectedRows rows",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void table_picker(BuildContext context, TextEditingController controller) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: TablePicker(
          onSelected: (rows, columns) {
            Navigator.pop(context);

            final table = generateMarkdownTable(
              rows,
              columns,
            );

            // Insert table into your TextField
            insertTextAtCursor(table, controller);
          },
        ),
      );
    },
  );
}

String generateMarkdownTable(int rows,int columns){
  String ret = "";
  int i = 0;
  while (i < rows) {
    if (i == 1) {ret += "| --- " * (columns ); ret += "| \n";}
    ret += "| " * (columns +1); ret += "\n";
    i++;
  }
  return ret;

}

