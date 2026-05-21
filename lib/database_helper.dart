import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
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

  // --- PERBAIKAN DI SINI: Kolom disesuaikan dengan Supabase & UI Dashboard ---
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menus (
        id TEXT PRIMARY KEY,       -- Pakai TEXT agar cocok dengan ID dari Supabase
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        desc TEXT,                 -- Ditambahkan biar deskripsi menu gak hilang
        tag TEXT,                  -- Ditambahkan untuk label (TERLARIS, MANUAL BREW, dll)
        image_url TEXT,
        stock INTEGER DEFAULT 0
      )
    ''');
  }

  // Fungsi menyimpan/mengupdate menu dari Supabase ke lokal handphone
  Future<int> createOrUpdateMenu(Map<String, dynamic> row) async {
    final db = await instance.database;
    // conflictAlgorithm: replace fungsinya jika data ID sudah ada, otomatis diupdate yang terbaru
    return await db.insert(
      'menus', 
      row, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // Fungsi mengambil semua menu saat offline
  Future<List<Map<String, dynamic>>> readAllMenus() async {
    final db = await instance.database;
    return await db.query('menus');
  }

  // Tambahan: Fungsi hapus semua data lama (berguna saat mau sync ulang)
  Future<int> clearAllMenus() async {
    final db = await instance.database;
    return await db.delete('menus');
  }
}