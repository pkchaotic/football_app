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
      print('Player stats fetched from local DB: $localData');
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
      print('Player stats fetched from API and stored in local DB: $player');

      return player;
    } else {
      throw Exception('Failed to load player stats');
    }
  }

  Future<void> claimPlayer(int playerId, int userId) async {
    print('Claiming player: $playerId for user: $userId');
    await dbHelper.claimPlayer(playerId, userId);
    print('Player claimed.');
  }

  Future<List<Map<String, dynamic>>> getPlayerClaims(int userId) async {
    print('Fetching player claims for user: $userId');
    final claims = await dbHelper.getPlayerClaims(userId);
    print('Player claims fetched: $claims');
    return claims;
  }

  Future<void> watchPlayer(int playerId, int userId) async {
    print('Adding player: $playerId to watchlist for user: $userId');
    await dbHelper.addToWatchList(playerId, userId);
    print('Player added to watchlist.');
  }

  Future<List<Map<String, dynamic>>> getPlayerWatchList(int userId) async {
    try {
      final watchListEntries = await dbHelper.getWatchList(userId);
      List<Map<String, dynamic>> watchListWithDetails = [];
      print('ApiService: Raw watchListEntries: $watchListEntries');

      for (var entry in watchListEntries) {
        final playerId = entry['id'];
        if (playerId != null && playerId is int) {
          print('ApiService: Found playerId $playerId in watchlist');
          final playerDetails = await dbHelper.getPlayer(playerId);
          if (playerDetails != null) {
            watchListWithDetails.add(playerDetails);
            print('ApiService: Player details added for playerId $playerId');
          } else {
            print('ApiService: No player details found for playerId $playerId');
          }
        } else {
          print('ApiService: playerId is null or not an int for entry $entry');
        }
      }

      print('ApiService: Watchlist fetched: $watchListWithDetails');
      return watchListWithDetails;
    } catch (e) {
      print('ApiService: Error fetching watchlist: $e');
      throw e;
    }
  }

  Future<void> addToPortfolio(int playerId, int userId) async {
    print('Adding player: $playerId to portfolio for user: $userId');
    await dbHelper.addToPortfolio(playerId, userId);
    print('Player added to portfolio.');
  }

  Future<List<Map<String, dynamic>>> getPlayerPortfolio(int userId) async {
    try {
      final portfolioEntries = await dbHelper.getPortfolio(userId);
      List<Map<String, dynamic>> portfolioWithDetails = [];
      print('ApiService: Raw portfolioEntries: $portfolioEntries');

      for (var entry in portfolioEntries) {
        final playerId = entry['id'];
        if (playerId != null && playerId is int) {
          print('ApiService: Found playerId $playerId in portfolio');
          final playerDetails = await dbHelper.getPlayer(playerId);
          if (playerDetails != null) {
            portfolioWithDetails.add(playerDetails);
            print('ApiService: Player details added for playerId $playerId');
          } else {
            print('ApiService: No player details found for playerId $playerId');
          }
        } else {
          print('ApiService: playerId is null or not an int for entry $entry');
        }
      }

      print('ApiService: Portfolio fetched: $portfolioWithDetails');
      return portfolioWithDetails;
    } catch (e) {
      print('ApiService: Error fetching portfolio: $e');
      throw e;
    }
  }

  Future<void> removeFromPortfolio(int playerId, int userId) async {
    print('Removing player: $playerId from portfolio for user: $userId');
    await dbHelper.removeFromPortfolio(playerId, userId);
    print('Player removed from portfolio.');
  }

  Future<Map<String, dynamic>?> getAgentByPlayerId(int playerId) async {
    final agent = await dbHelper.getAgentByPlayerId(playerId);
    return agent;
  }

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    print('Searching players with query: $query');
    final results = await dbHelper.searchPlayers(query);
    print('Search results: $results');
    return results;
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    print('Fetching user by ID: $userId');
    final user = await dbHelper.getUserById(userId);
    if (user != null) {
      print('User fetched: $user');
      return user;
    } else {
      throw Exception('User not found');
    }
  }
}

