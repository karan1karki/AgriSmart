import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Standard path for local databases on Android/iOS/Linux
    String path = join(await getDatabasesPath(), 'agrismart.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }


  Future _onCreate(Database db, int version) async {
   await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        phone TEXT,
        location TEXT,
        password TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE disease_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_name TEXT,
        disease_name TEXT,
        confidence REAL,
        medicine TEXT,
        prevention TEXT,
        image_path TEXT,
        date TEXT
      )
    ''');
  }

  Future<int> registerUser(Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert('user', data);
  }
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'user',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return results.isNotEmpty ? results.first : null;
  }
  Future<Map<String, dynamic>?> checkLogin(String identifier, String password) async {
    Database db = await database;
    // This checks both email and phone columns against the identifier
    List<Map<String, dynamic>> result = await db.query(
      'user',
      where: '(email = ? OR phone = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertData(String table, Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getData(String table) async {
    Database db = await database;
    return await db.query(table, orderBy: "id DESC");
  }
}