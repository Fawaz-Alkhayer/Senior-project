
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  static const String _dbPassword = 'your_secure_password_here_2024';


  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

   
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      password: _dbPassword,
    );
  }
  
 

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNull = 'TEXT';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE notes (
        id $idType,
        title $textType,
        content $textType,
        createdAt $textType,
        updatedAt $textType,
        isFavorite $intType,
        imagePath $textTypeNull
      )
    ''');
 }
 

  // Create a new note
  Future<Note> createNote(Note note) async {
    final db = await instance.database;
    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  // Read a single note
  Future<Note?> readNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Read all notes
  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    // Order by favorite first (DESC = 1 before 0), then by updated date
    const orderBy = 'isFavorite DESC, updatedAt DESC';
    final result = await db.query('notes', orderBy: orderBy);
    print('📚 Read ${result.length} notes from database');
    return result.map((json) => Note.fromMap(json)).toList();
  }
  

  // Update a note
  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Delete a note
  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Toggle favorite status
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await instance.database;
    print('⭐ Toggling favorite for note ID: $id to $isFavorite');
    return db.update(
      'notes',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}