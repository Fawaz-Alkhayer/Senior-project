import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secure_notes_app/services/database_service.dart';
import 'package:secure_notes_app/models/note_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService Integration Tests', () {
    late DatabaseService db;

    setUpAll(() async {
      db = DatabaseService.instance;
    });

    testWidgets('TC-20: Create note and verify it is stored', (tester) async {
      final note = Note(
        title: 'Test Note',
        content: 'Test Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await db.createNote(note);
      expect(created.id, isNotNull);
      expect(created.title, 'Test Note');
      expect(created.content, 'Test Content');

      // Cleanup
      await db.deleteNote(created.id!);
    });

    testWidgets('TC-21: Read note returns correct data', (tester) async {
      final note = Note(
        title: 'Read Test',
        content: 'Read Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await db.createNote(note);
      final read = await db.readNote(created.id!);

      expect(read, isNotNull);
      expect(read!.title, 'Read Test');
      expect(read.content, 'Read Content');

      // Cleanup
      await db.deleteNote(created.id!);
    });

    testWidgets('TC-22: Update note changes content correctly', (tester) async {
      final note = Note(
        title: 'Original Title',
        content: 'Original Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await db.createNote(note);
      final updated = created.copyWith(
        title: 'Updated Title',
        content: 'Updated Content',
        updatedAt: DateTime.now(),
      );

      await db.updateNote(updated);
      final read = await db.readNote(created.id!);

      expect(read!.title, 'Updated Title');
      expect(read.content, 'Updated Content');

      // Cleanup
      await db.deleteNote(created.id!);
    });

    testWidgets('TC-23: Delete note removes it from database', (tester) async {
      final note = Note(
        title: 'Delete Test',
        content: 'Delete Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await db.createNote(note);
      await db.deleteNote(created.id!);
      final read = await db.readNote(created.id!);

      expect(read, isNull);
    });

    testWidgets('TC-24: Toggle favorite updates isFavorite field', (tester) async {
      final note = Note(
        title: 'Favorite Test',
        content: 'Favorite Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await db.createNote(note);
      await db.toggleFavorite(created.id!, true);
      final read = await db.readNote(created.id!);

      expect(read!.isFavorite, true);

      // Cleanup
      await db.deleteNote(created.id!);
    });

    testWidgets('TC-25: Toggle note lock updates isLocked field', (tester) async {
      final note = Note(
        title: 'Lock Test',
        content: 'Lock Content',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await db.createNote(note);
      await db.toggleNoteLock(created.id!, true);
      final read = await db.readNote(created.id!);

      expect(read!.isLocked, true);

      // Cleanup
      await db.deleteNote(created.id!);
    });

    testWidgets('TC-26: Read all notes returns list', (tester) async {
      final note1 = Note(
        title: 'List Test 1',
        content: 'Content 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final note2 = Note(
        title: 'List Test 2',
        content: 'Content 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created1 = await db.createNote(note1);
      final created2 = await db.createNote(note2);
      final allNotes = await db.readAllNotes();

      expect(allNotes.length, greaterThanOrEqualTo(2));

      // Cleanup
      await db.deleteNote(created1.id!);
      await db.deleteNote(created2.id!);
    });
  });
}