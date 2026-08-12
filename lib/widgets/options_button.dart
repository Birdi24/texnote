import 'package:flutter/material.dart';

import '../app_style.dart';

Widget options_button(context, Future<void> Function() save, double fontSize,
    Function(double) change_font_size, void Function() change_markdown_view) {
  bool is_selected =true;
  return Padding(
      padding: const EdgeInsets.only(top: 4.0), // Move down by 4 pixels
      child: Container(
        width: 35,
        height:35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent,
              width: 1,
            ),
          ),
        child: PopupMenuButton(
          color: BG,
          icon: const Icon(
            Icons.density_medium_rounded,
            size: 16,
            color: accent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Font Size',
                    style: AppStyles.bodytext,
                  ),

                  Spacer(),

                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.remove,
                      color: accent,
                      size: 18,
                    ),
                    onPressed: () {
                      fontSize--;
                      change_font_size(fontSize);
                    },
                  ),

                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    icon: const Icon(
                      Icons.add,
                      color: accent,
                      size: 18,
                    ),
                    onPressed: () {
                      fontSize++;
                      change_font_size(fontSize);
                    },
                  ),
                ],
              ),
            ),

            const PopupMenuItem(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              child: Divider(
                height: 1,
                thickness: 1,
              ),
            ),

            PopupMenuItem(
              height: 42,
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, menuSetState) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      menuSetState(() {
                        is_selected = !is_selected;
                      });

                      change_markdown_view();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Markdown",
                            style: AppStyles.bodytext,
                          ),

                          Spacer(),

                          IgnorePointer(
                            child: Transform.scale(
                              scale: 0.65,
                              child: Switch(
                                value: is_selected,
                                onChanged: (_) {},
                                activeTrackColor: icon_color,
                                inactiveTrackColor: icon_color,
                                trackOutlineColor: WidgetStateProperty.all(BG),
                                thumbColor: WidgetStateProperty.all(BG),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        )
      )
  );
}

