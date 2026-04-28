import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SettingsDatabase {
  static final SettingsDatabase instance = SettingsDatabase._init();
  static Database? _database;

  SettingsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bodylog_settings.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dark_mode INTEGER NOT NULL DEFAULT 0,
        language TEXT NOT NULL DEFAULT 'English'
      )
    ''');

    await db.insert('settings', {
      'dark_mode': 0,
      'language': 'English',
    });
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await instance.database;
    final result = await db.query('settings', limit: 1);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> updateSettings({
    required bool darkMode,
    required String language,
  }) async {
    final db = await instance.database;

    await db.update(
      'settings',
      {
        'dark_mode': darkMode ? 1 : 0,
        'language': language,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
