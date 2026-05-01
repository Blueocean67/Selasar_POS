import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // --- INI KUNCINYA: Tambahkan baris ini biar error merahnya ilang ---
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('selasar_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        image_url TEXT,
        stock INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> createMenu(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('menus', row);
  }

  Future<List<Map<String, dynamic>>> readAllMenus() async {
    final db = await instance.database;
    return await db.query('menus');
  }
}