import 'package:flutter/material.dart';
import 'api_service.dart';
import 'player_detail_screen.dart';

class PlayerListScreen extends StatefulWidget {
  @override
  _PlayerListScreenState createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> allPlayers = [];
  List<dynamic> filteredPlayers = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPlayers();
    searchController.addListener(() {
      filterPlayers();
    });
  }

  Future<void> loadPlayers() async {
    setState(() {
      isLoading = true;
    });
    await apiService.fetchAndStorePlayers();
    final players = await apiService.getAllPlayersFromDB();
    setState(() {
      allPlayers = players;
      filterPlayers();
      isLoading = false;
    });
  }

  void filterPlayers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPlayers = allPlayers.where((player) {
        final playerName = player['name'].toLowerCase();
        final teamName = player['team'].toLowerCase();
        return playerName.contains(query) || teamName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Players'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for players or teams...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                },
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = filteredPlayers[index];
          return ListTile(
            leading: Image.network(player['photo'] ?? 'https://via.placeholder.com/150'),
            title: Text(player['name'] ?? 'Unknown'),
            subtitle: Text(player['team'] ?? 'Unknown'),
            onTap: () {
              final playerId = player['id'];
              if (playerId != null && playerId is int) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerDetailScreen(playerId: playerId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid player ID')),
                );
              }
            },
          );
        },
      ),
    );
  }
}
