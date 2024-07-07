import 'package:flutter/material.dart';
import 'api_service.dart';
import 'player_detail_screen.dart';
import 'login_screen.dart';

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
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await fetchAgent();
    await fetchPortfolio();
    setState(() {
      isLoading = false;
    });
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
    if (query.isNotEmpty) {
      final players = await apiService.searchPlayers(query);
      setState(() {
        searchResults = players;
      });
    } else {
      setState(() {
        searchResults = [];
      });
    }
  }

  Future<void> addToPortfolio(int playerId) async {
    await apiService.claimPlayer(playerId, widget.userId);
    await fetchPortfolio();
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(agent != null ? agent!['name'] : 'Loading...'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: isLoading
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
              controller: searchController,
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
