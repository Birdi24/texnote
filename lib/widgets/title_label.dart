import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_style.dart';

Widget title_label(context, titleController){
  return SizedBox(
    height: 40,
    child: TextField(
      controller: titleController,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: "Title",
        hintStyle: AppStyles.title2,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: AppStyles.title2,
      cursorHeight: 22,
    ),
  );
}