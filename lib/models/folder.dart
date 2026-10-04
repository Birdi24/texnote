import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app_style.dart';
import 'Note.dart';

/// Represents a physical folder of notes.
class Folder {
  String title;
  String color;
  String path;
  List<Note> notes = [];
  List<Folder> subfolders = [];
  Folder? parent;

  Folder({
    required this.title,
    required this.color,
    required this.path,
    List<Note>? notes,
    List<Folder>? subfolders,
    this.parent,
  })  : notes = notes ?? [],
        subfolders = subfolders ?? [];

  /// by: 0 means least number of items (notes + subfolders)
  /// by: 1 means most number of items
  /// by: 2 means alphabetical order
  static List<Folder> sort_folders(List<Folder> folders, int by) {
    for (final folder in folders) {
      Note.sort_notes(folder.notes, by);
      sort_folders(folder.subfolders, by);
    }
    switch (by) {
      case 0:
        folders.sort((a, b) => (a.notes.length + a.subfolders.length)
            .compareTo(b.notes.length + b.subfolders.length));
        break;
      case 1:
        folders.sort((a, b) => (b.notes.length + b.subfolders.length)
            .compareTo(a.notes.length + a.subfolders.length));
        break;
      case 2:
        folders.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return folders;
  }

  Future<void> rename_folder(String newName) async {
    final oldDir = Directory(path);
    if (await oldDir.exists()) {
      final oldPath = path;
      final parentPath = p.dirname(path);
      final newPath = p.join(parentPath, newName);
      if (newPath == path) return;
      
      final newDir = await oldDir.rename(newPath);
      path = newDir.path;
      title = newName;
      
      // Update metadata file
      await _update_metadata_paths(oldPath, path);
      
      // Update all nested items paths recursively
      _updateChildPaths(this);
    }
  }

  void _updateChildPaths(Folder folder) {
    for (var note in folder.notes) {
      final fileName = p.basename(note.path);
      note.path = p.join(folder.path, fileName);
    }
    for (var sub in folder.subfolders) {
      final dirName = p.basename(sub.path);
      sub.path = p.join(folder.path, dirName);
      _updateChildPaths(sub);
    }
  }

  static Future<List<Folder>> load_folders(List<Note> allNotes) async {
    debugPrint("Folder.load_folders() started with ${allNotes.length} notes");
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final configPath = p.join(appDir.path, ".folders.json");
      File configFile = File(configPath);

      Map<String, String> folderColors = {};
      if (await configFile.exists()) {
        final contents = await configFile.readAsString();
        if (contents.trim().isNotEmpty) {
          final List<dynamic> data = jsonDecode(contents);
          for (final entry in data) {
            folderColors[p.canonicalize(entry['path'])] = entry['color'];
          }
        }
      }

      Map<String, Folder> folderMap = {};

      // 1. Find all directories recursively
      final List<FileSystemEntity> entities = appDir.listSync(recursive: true);
      
      for (var entity in entities) {
        if (entity is Directory) {
          final relativePath = p.relative(entity.path, from: appDir.path);
          if (relativePath.startsWith('.') || 
              relativePath.contains('/.') || 
              relativePath.startsWith('pdf_imports') ||
              relativePath.contains('flutter_assets') ||
              relativePath.contains('fluttter_assets')) continue;
          if (relativePath == '.') continue;

          final String title = p.basename(entity.path);
          final String color = folderColors[p.canonicalize(entity.path)] ?? "1";
          
          final canonicalPath = p.canonicalize(entity.path);
          folderMap[canonicalPath] = Folder(
            title: title,
            color: color,
            path: entity.path,
          );
        }
      }

      // 2. Link parents and children
      List<Folder> rootFolders = [];
      final String canonicalAppPath = p.canonicalize(appDir.path);
      folderMap.forEach((path, folder) {
        final parentPath = p.canonicalize(p.dirname(path));
        if (folderMap.containsKey(parentPath)) {
          final parent = folderMap[parentPath]!;
          folder.parent = parent;
          parent.subfolders.add(folder);
        } else if (parentPath == canonicalAppPath) {
          rootFolders.add(folder);
        }
      });

      // 3. Assign notes to folders
      int assignedCount = 0;
      for (var note in allNotes) {
        final noteDir = p.canonicalize(p.dirname(note.path));
        if (folderMap.containsKey(noteDir)) {
          folderMap[noteDir]!.notes.add(note);
          assignedCount++;
        }
      }
      debugPrint("Folder.load_folders(): assigned $assignedCount notes to folders");

      return rootFolders;
    } catch (e) {
      debugPrint("Could not load folders: $e");
      return [];
    }
  }

  static Future<void> save_folder_metadata_recursive(List<Folder> folders) async {
    List<Map<String, String>> data = [];
    void collectMetadata(Folder f) {
      data.add({"path": p.canonicalize(f.path), "color": f.color});
      for (var sub in f.subfolders) {
        collectMetadata(sub);
      }
    }
    for (var f in folders) {
      collectMetadata(f);
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(dir.path, ".folders.json");
      final file = File(filePath);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Could not save folders metadata: $e");
    }
  }

  static Future<void> update_folder_color(String folderPath, String color) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = p.join(appDir.path, ".folders.json");
      final file = File(filePath);

      List<dynamic> data = [];
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.trim().isNotEmpty) {
          data = jsonDecode(contents);
        }
      }

      final canonicalPath = p.canonicalize(folderPath);
      bool found = false;
      for (var i = 0; i < data.length; i++) {
        if (p.canonicalize(data[i]['path']) == canonicalPath) {
          data[i]['color'] = color;
          found = true;
          break;
        }
      }

      if (!found) {
        data.add({"path": canonicalPath, "color": color});
      }

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Could not update folder color: $e");
    }
  }

  static Future<void> _update_metadata_paths(String oldPath, String newPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = p.join(appDir.path, ".folders.json");
      final file = File(filePath);

      if (!await file.exists()) return;

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return;

      List<dynamic> data = jsonDecode(contents);
      final canonicalOld = p.canonicalize(oldPath);

      bool changed = false;
      for (var i = 0; i < data.length; i++) {
        final currentPath = p.canonicalize(data[i]['path']);
        if (currentPath == canonicalOld) {
          data[i]['path'] = newPath;
          changed = true;
        } else if (currentPath.startsWith('$canonicalOld${p.separator}')) {
          // It's a subfolder
          final relative = p.relative(currentPath, from: canonicalOld);
          data[i]['path'] = p.join(newPath, relative);
          changed = true;
        }
      }

      if (changed) {
        await file.writeAsString(jsonEncode(data));
      }
    } catch (e) {
      debugPrint("Could not update folder metadata paths: $e");
    }
  }

  Widget display() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 0.72,
          child: Container(
            padding: const EdgeInsets.only(top: 50),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: collection_color(color),
              border: Border.all(
                color: icon_color,
                width: 2,
              ),
            ),
            child: Container(
              alignment: Alignment.bottomCenter,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: icon_color,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: icon_color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "${notes.length + subfolders.length} Items",
          style: TextStyle(
            color: accent,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> move_folder(String newParentPath, {Folder? newParent}) async {
    final oldDir = Directory(path);
    if (!await oldDir.exists()) return;

    final oldPath = path;
    final newPath = p.join(newParentPath, p.basename(path));
    if (newPath == path) return; // no-op, same location

    if (await Directory(newPath).exists()) {
      throw Exception("A folder named '$title' already exists there.");
    }

    final movedDir = await oldDir.rename(newPath);
    path = movedDir.path;

    // update tree linkage
    parent?.subfolders.remove(this);
    parent = newParent;
    newParent?.subfolders.add(this);

    // Update metadata file
    await _update_metadata_paths(oldPath, path);

    _updateChildPaths(this);
  }
}



