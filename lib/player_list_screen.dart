import 'package:flutter/material.dart';
import 'api_service.dart';
import 'player_detail_screen.dart';

class PlayerListScreen extends StatefulWidget {
  final int userId;

  PlayerListScreen({required this.userId});

  @override
  _PlayerListScreenState createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    fetchPlayers();
  }

  Future<void> fetchPlayers() async {
    final playerList = await apiService.getAllPlayersFromDB();
    setState(() {
      players = playerList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player List'),
      ),
      body: players.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return ListTile(
            title: Text(player['name']),
            subtitle: Text('Team: ${player['team']}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailScreen(
                    playerId: player['id'],
                    userId: widget.userId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
