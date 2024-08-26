import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages(id INTEGER PRIMARY KEY AUTOINCREMENT, chatId TEXT, sendedAt DATETIME DEFAULT CURRENT_TIMESTAMP, senderId TEXT, contentType TEXT, contentName TEXT, imagePathSmall TEXT, imagePathOriginal TEXT)',
        );
      },
    );
  }

  Future<void> insertMessage(String chatId, String senderId, String contentType, String contentName, String imagePathSmall, String imagePathOriginal) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'chatId': chatId,
        'sendedAt': DateTime.now().toIso8601String(),
        'senderId': senderId,
        'contentType': contentType,
        'contentName': contentName,
        'imagePathSmall': imagePathSmall,
        'imagePathOriginal': imagePathOriginal,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ページング用のメッセージ取得メソッド
  Future<List<Map<String, dynamic>>> getMessages(String chatId, int offset, int pageSize) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'sendedAt DESC', // 最新のメッセージを先に取得
      limit: pageSize,
      offset: offset,
    );
  }

/* テーブルを用意する */
  Future<void> insertChat(String chatId, String receiverId, String name, String profileImagePath) async {
    return;
    final db = await database;
    await db.insert(
      'messages',
      {'chatId': chatId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}