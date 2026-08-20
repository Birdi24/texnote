import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> createDirectory(String title, String body) async {
  final base = await getApplicationDocumentsDirectory();

  final projectDir = Directory(
    '${base.path}/$title',
  );

  await projectDir.create(recursive: true);

  final mainFile = File(
    '${projectDir.path}/main.tex',
  );

  await mainFile.writeAsString(
    body,
  );

  return projectDir.path;
}
