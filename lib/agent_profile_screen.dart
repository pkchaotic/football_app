import 'package:flutter/material.dart';
import 'api_service.dart';
import 'player_detail_screen.dart';

class AgentProfileScreen extends StatefulWidget {
  final int userId;

  AgentProfileScreen({required this.userId});

  @override
  _AgentProfileScreenState createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? agent;
  List<Map<String, dynamic>> portfolio = [];
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    fetchAgent();
    fetchPortfolio();
  }

  Future<void> fetchAgent() async {
    final agentData = await apiService.getUserById(widget.userId);
    setState(() {
      agent = agentData;
    });
  }

  Future<void> fetchPortfolio() async {
    final players = await apiService.getPlayerClaims(widget.userId);
    setState(() {
      portfolio = players;
    });
  }

  Future<void> searchPlayers(String query) async {
    final results = await apiService.searchPlayers(query);
    setState(() {
      searchResults = results;
    });
  }

  void addToPortfolio(int playerId) async {
    await apiService.claimPlayer(playerId, widget.userId);
    fetchPortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(agent != null ? agent!['name'] : 'Loading...'),
      ),
      body: agent == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${agent!['name']}',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            Text('Role: ${agent!['role']}'),
            SizedBox(height: 16.0),
            Text(
              'Portfolio',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  final player = portfolio[index];
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
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Players',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                if (query.isNotEmpty) {
                  searchPlayers(query);
                } else {
                  setState(() {
                    searchResults = [];
                  });
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final player = searchResults[index];
                  return ListTile(
                    title: Text(player['name']),
                    subtitle: Text('Team: ${player['team']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        addToPortfolio(player['id']);
                      },
                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
