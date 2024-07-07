import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'database_helper.dart';

class ApiService {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<void> fetchAndStorePlayers() async {
    int currentPage = 1;
    bool hasMorePages = true;

    while (hasMorePages) {
      final response = await http.get(
        Uri.parse('$apiUrl/players?league=39&season=2023&page=$currentPage'), // Example: Premier League
        headers: {
          'x-apisports-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final players = data['response'] ?? [];
        if (players.isEmpty) {
          hasMorePages = false;
        } else {
          List<Map<String, dynamic>> playerList = players.map<Map<String, dynamic>>((player) {
            final playerData = player['player'];
            final statistics = player['statistics'][0];

            return {
              'id': playerData['id'],
              'name': playerData['name'] ?? 'N/A',
              'age': playerData['age'] ?? 0,
              'nationality': playerData['nationality'] ?? 'N/A',
              'photo': playerData['photo'] ?? 'https://via.placeholder.com/150',
              'team': statistics['team']['name'] ?? 'N/A',
              'games_played': statistics['games']['appearences'] ?? 0,
              'goals': statistics['goals']['total'] ?? 0,
              'assists': statistics['goals']['assists'] ?? 0,
              'rating': statistics['games']['rating'] != null ? double.parse(statistics['games']['rating']) : null,
              'shots_total': statistics['shots']['total'],
              'shots_on': statistics['shots']['on'],
              'passes_accuracy': statistics['passes']['accuracy'],
              'dribbles_attempts': statistics['dribbles']['attempts'],
              'dribbles_success': statistics['dribbles']['success'],
              'tackles_total': statistics['tackles']['total'],
              'fouls_committed': statistics['fouls']['committed'],
              'cards_yellow': statistics['cards']['yellow'],
              'cards_yellowred': statistics['cards']['yellowred'],
              'cards_red': statistics['cards']['red'],
            };
          }).toList();
          await dbHelper.insertPlayers(playerList);

          // Update pagination
          final paging = data['paging'];
          currentPage = paging['current'] + 1;
          if (currentPage > paging['total']) {
            hasMorePages = false;
          }
        }
      } else {
        throw Exception('Failed to load players');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getAllPlayersFromDB() async {
    return await dbHelper.getAllPlayers();
  }

  Future<Map<String, dynamic>> fetchPlayerStats(int playerId, int season) async {
    final localData = await dbHelper.getPlayer(playerId);
    if (localData != null) {
      return localData;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/players?id=$playerId&season=$season'),
      headers: {
        'x-apisports-key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final playerData = data['response'][0]['player'];
      final statistics = data['response'][0]['statistics'][0];

      final player = {
        'id': playerId,
        'name': playerData['name'] ?? 'N/A',
        'age': playerData['age'] ?? 0,
        'nationality': playerData['nationality'] ?? 'N/A',
        'photo': playerData['photo'] ?? 'https://via.placeholder.com/150',
        'team': statistics['team']['name'] ?? 'N/A',
        'games_played': statistics['games']['appearences'] ?? 0,
        'goals': statistics['goals']['total'] ?? 0,
        'assists': statistics['goals']['assists'] ?? 0,
        'rating': statistics['games']['rating'] != null ? double.parse(statistics['games']['rating']) : null,
        'shots_total': statistics['shots']['total'],
        'shots_on': statistics['shots']['on'],
        'passes_accuracy': statistics['passes']['accuracy'],
        'dribbles_attempts': statistics['dribbles']['attempts'],
        'dribbles_success': statistics['dribbles']['success'],
        'tackles_total': statistics['tackles']['total'],
        'fouls_committed': statistics['fouls']['committed'],
        'cards_yellow': statistics['cards']['yellow'],
        'cards_yellowred': statistics['cards']['yellowred'],
        'cards_red': statistics['cards']['red'],
      };

      await dbHelper.insertPlayers([player]);

      return player;
    } else {
      throw Exception('Failed to load player stats');
    }
  }

  Future<void> claimPlayer(int playerId, int userId) async {
    await dbHelper.claimPlayer(playerId, userId);
  }

  Future<List<Map<String, dynamic>>> getPlayerClaims(int userId) async {
    return await dbHelper.getPlayerClaims(userId);
  }

  Future<void> watchPlayer(int playerId, int userId) async {
    await dbHelper.addToWatchList(playerId, userId);
  }

  Future<List<Map<String, dynamic>>> getPlayerWatchList(int userId) async {
    return await dbHelper.getWatchList(userId);
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    return await dbHelper.searchPlayers(query);
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final user = await dbHelper.getUserById(userId);
    if (user != null) {
      return user;
    } else {
      throw Exception('User not found');
    }
  }
}
