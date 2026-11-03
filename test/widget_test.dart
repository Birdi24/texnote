import 'dart:io';

import 'package:birdwrite/models/HandwrittenNote.dart';
import 'package:birdwrite/models/Note.dart';
import 'package:birdwrite/models/TextNote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('birdwrite_notes_');
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  test(
    'saved filenames cannot be hidden and collisions are numbered',
    () async {
      final first = TextNote(
        title: '..meeting',
        body: 'first',
        path: tempDirectory.path,
        date: DateTime(2026),
        type: NoteType.TextNote,
      );
      await first.save('');

      final second = TextNote(
        title: '..meeting',
        body: 'second',
        path: tempDirectory.path,
        date: DateTime(2026),
        type: NoteType.TextNote,
      );
      await second.save('');

      final third = TextNote(
        title: '..meeting',
        body: 'third',
        path: tempDirectory.path,
        date: DateTime(2026),
        type: NoteType.TextNote,
      );
      await third.save('');

      expect(first.title, 'meeting');
      expect(p.basename(first.path), 'meeting.txt');
      expect(p.basename(second.path), 'meeting (1).txt');
      expect(p.basename(third.path), 'meeting (2).txt');
      expect(await File(first.path).readAsString(), 'first');
      expect(await File(second.path).readAsString(), 'second');
      expect(await File(third.path).readAsString(), 'third');
    },
  );

  test('handwritten note saves use visible numbered filenames', () async {
    final first = HandwrittenNote(
      title: '.journal',
      path: tempDirectory.path,
      date: DateTime(2026),
      type: NoteType.HandwrittenNote,
    );
    await first.save('');

    final second = HandwrittenNote(
      title: '.journal',
      path: tempDirectory.path,
      date: DateTime(2026),
      type: NoteType.HandwrittenNote,
    );
    await second.save('');

    expect(first.title, 'journal');
    expect(p.basename(first.path), 'journal.note');
    expect(p.basename(second.path), 'journal (1).note');
    expect(await File(first.path).exists(), isTrue);
    expect(await File(second.path).exists(), isTrue);
  });
}
