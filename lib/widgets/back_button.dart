import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../app_style.dart';

Widget back_button(context, Future<void> Function() save,changed) {
  return Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: SizedBox(
      width:35,
      height:35,
      child: OutlinedButton(
        onPressed: () async {
          if (changed){
            await save();
          }
          Navigator.pop(context,true);
        },
        child: const Icon(Icons.arrow_back),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          iconColor: icon_color,
          side: const BorderSide(
            color: icon_color,
            width: 1,
          ),
        ),
      ),
    )
  );
}