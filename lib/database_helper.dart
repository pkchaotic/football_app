import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT,
        password TEXT,
        role TEXT,
        assignedPlayers TEXT,
        team TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE players (
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
        passes_accuracy INTEGER,
        dribbles_attempts INTEGER,
        dribbles_success INTEGER,
        tackles_total INTEGER,
        fouls_committed INTEGER,
        cards_yellow INTEGER,
        cards_yellowred INTEGER,
        cards_red INTEGER,
        agentId INTEGER,
        FOREIGN KEY (agentId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE watch_list (
        playerId INTEGER,
        userId INTEGER,
        PRIMARY KEY (playerId, userId),
        FOREIGN KEY (playerId) REFERENCES players(id),
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE portfolio (
        playerId INTEGER,
        userId INTEGER,
        PRIMARY KEY (playerId, userId),
        FOREIGN KEY (playerId) REFERENCES players(id),
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
    await _loadInitialData(db);
  }

  Future<void> _loadInitialData(Database db) async {
    String usersJson = await rootBundle.loadString('assets/agents_and_coaches.json');
    List<dynamic> users = jsonDecode(usersJson)['users'];
    for (var user in users) {
      await db.insert('users', {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'password': user['password'],
        'role': user['role'],
        'assignedPlayers': jsonEncode(user['assignedPlayers']),
        'team': user['team']
      });
    }
  }

  Future<void> addToWatchList(int playerId, int userId) async {
    Database db = await instance.database;
    await db.insert(
      'watch_list',
      {
        'playerId': playerId,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('DatabaseHelper: Player $playerId added to watchlist for user $userId');
  }

  Future<List<Map<String, dynamic>>> getWatchList(int userId) async {
    Database db = await instance.database;
    final watchListEntries = await db.query(
      'watch_list',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    List<Map<String, dynamic>> watchList = [];
    for (var entry in watchListEntries) {
      final playerId = entry['playerId'] as int?;
      if (playerId != null) {
        final player = await getPlayer(playerId);
        if (player != null) {
          watchList.add(player);
        }
      } else {
        print('DatabaseHelper: playerId is null or not an int for entry $entry');
      }
    }

    print('DatabaseHelper: Watchlist from DB: $watchList');
    return watchList;
  }

  Future<void> removeFromWatchList(int playerId, int userId) async {
    Database db = await instance.database;
    await db.delete(
      'watch_list',
      where: 'playerId = ? AND userId = ?',
      whereArgs: [playerId, userId],
    );
  }

  Future<void> addToPortfolio(int playerId, int userId) async {
    Database db = await instance.database;
    await db.insert(
      'portfolio',
      {
        'playerId': playerId,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('DatabaseHelper: Player $playerId added to portfolio for user $userId');
  }

  Future<List<Map<String, dynamic>>> getPortfolio(int userId) async {
    Database db = await instance.database;
    final portfolioEntries = await db.query(
      'portfolio',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    List<Map<String, dynamic>> portfolio = [];
    for (var entry in portfolioEntries) {
      final playerId = entry['playerId'] as int?;
      if (playerId != null) {
        final player = await getPlayer(playerId);
        if (player != null) {
          portfolio.add(player);
        }
      } else {
        print('DatabaseHelper: playerId is null or not an int for entry $entry');
      }
    }

    print('DatabaseHelper: Portfolio from DB: $portfolio');
    return portfolio;
  }

  Future<void> removeFromPortfolio(int playerId, int userId) async {
    Database db = await instance.database;
    await db.delete(
      'portfolio',
      where: 'playerId = ? AND userId = ?',
      whereArgs: [playerId, userId],
    );
  }

  Future<Map<String, dynamic>?> getUser(String email, String password, String role) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ? AND role = ?',
      whereArgs: [email, password, role],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getAgentByPlayerId(int playerId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'portfolio',
      where: 'playerId = ?',
      whereArgs: [playerId],
    );
    if (results.isNotEmpty) {
      final agentId = results.first['userId'];
      return getUserById(agentId);
    }
    return null;
  }

  Future<void> insertPlayers(List<Map<String, dynamic>> players) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var player in players) {
      batch.insert('players', player, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    Database db = await instance.database;
    return await db.query('players');
  }

  Future<Map<String, dynamic>?> getPlayer(int playerId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [playerId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> claimPlayer(int playerId, int userId) async {
    Database db = await instance.database;
    await db.update(
      'players',
      {'agentId': userId},
      where: 'id = ?',
      whereArgs: [playerId],
    );
  }

  Future<List<Map<String, dynamic>>> getPlayerClaims(int userId) async {
    Database db = await instance.database;
    return await db.query(
      'players',
      where: 'agentId = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    Database db = await instance.database;
    return await db.query(
      'players',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  Future<List<Map<String, dynamic>>> getAllWatchListEntries() async {
    Database db = await instance.database;
    final watchListEntries = await db.query('watch_list');
    return watchListEntries;
  }
}
