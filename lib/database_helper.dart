import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'player_stats.db');
    return await openDatabase(
      path,
      version: 5, // Aktualisierte Versionsnummer
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE players(
        id INTEGER PRIMARY KEY,
        name TEXT,
        age INTEGER,
        nationality TEXT,
        photo TEXT,
        team TEXT,
        games_played INTEGER,
        goals INTEGER,
        assists INTEGER,
        rating REAL,
        shots_total INTEGER,
        shots_on INTEGER,
        passes_accuracy REAL,
        dribbles_attempts INTEGER,
        dribbles_success INTEGER,
        tackles_total INTEGER,
        fouls_committed INTEGER,
        cards_yellow INTEGER,
        cards_yellowred INTEGER,
        cards_red INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE players ADD COLUMN tackles_total INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN fouls_committed INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN cards_yellow INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN cards_yellowred INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN cards_red INTEGER');
    }
  }

  Future<void> insertPlayer(Map<String, dynamic> player) async {
    final db = await database;
    await db.insert('players', player, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertPlayers(List<Map<String, dynamic>> players) async {
    final db = await database;
    final batch = db.batch();
    for (var player in players) {
      batch.insert('players', player, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    final db = await database;
    return await db.query('players');
  }

  Future<Map<String, dynamic>?> getPlayer(int id) async {
    final db = await database;
    final result = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
