import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secure_notes_app/services/database_service.dart';
import 'package:secure_notes_app/services/pin_service.dart';
import 'package:secure_notes_app/models/note_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('PT-01: Note creation time', (tester) async {
      final db = DatabaseService.instance;
      final note = Note(
        title: 'Performance Test Note',
        content: 'This is a performance test note with some content to measure encryption overhead.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final start = DateTime.now();
      final created = await db.createNote(note);
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      print('PT-01 Note creation time: ${elapsed}ms');
      expect(elapsed, lessThan(2000)); // PT-01
      await db.deleteNote(created.id!);
    });

    testWidgets('PT-02: Note read time', (tester) async {
      final db = DatabaseService.instance;
      final note = Note(
        title: 'Read Performance Test',
        content: 'Content for read performance test.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final created = await db.createNote(note);

      final start = DateTime.now();
      await db.readNote(created.id!);
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      print('PT-02 Note read time: ${elapsed}ms');
      expect(elapsed, lessThan(500));
      await db.deleteNote(created.id!);
    });

    testWidgets('PT-03: Read all notes time', (tester) async {
      final db = DatabaseService.instance;

      final start = DateTime.now();
      await db.readAllNotes();
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      print('PT-03 Read all notes time: ${elapsed}ms');
      expect(elapsed, lessThan(1000));
    });

    testWidgets('PT-04: PIN hashing time', (tester) async {
      final start = DateTime.now();
      await PinService.instance.setPin('123456');
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      print('PT-04 PIN hashing and storage time: ${elapsed}ms');
      expect(elapsed, lessThan(1500)); // PT-04
    });

    testWidgets('PT-05: PIN verification time', (tester) async {
      await PinService.instance.setPin('123456');

      final start = DateTime.now();
      await PinService.instance.verifyPin('123456');
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      print('PT-05 PIN verification time: ${elapsed}ms');
      expect(elapsed, lessThan(500));
    });
  });
}