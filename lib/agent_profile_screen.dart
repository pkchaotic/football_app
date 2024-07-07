import 'package:flutter/material.dart';
import 'api_service.dart';
import 'player_detail_screen.dart';
import 'login_screen.dart';
import 'database_helper.dart';

class AgentProfileScreen extends StatefulWidget {
  final int userId;

  AgentProfileScreen({required this.userId});

  @override
  _AgentProfileScreenState createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  final ApiService apiService = ApiService();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
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
    final players = await apiService.getPlayerPortfolio(widget.userId);
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
    await apiService.addToPortfolio(playerId, widget.userId);
    await fetchPortfolio();
  }

  Future<void> removeFromPortfolio(int playerId) async {
    await apiService.removeFromPortfolio(playerId, widget.userId);
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Container(
        color: Colors.green[400], // Background color
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    agent!['photo'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${agent!['name']}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    Text('Role: ${agent!['role']}'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              'Portfolio',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Players',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                searchPlayers(query);
              },
            ),
            if (searchResults.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: Card(
                  margin: EdgeInsets.only(top: 8.0),
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final player = searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            player['photo'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
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
              ),
            Expanded(
              child: ListView.builder(
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  final player = portfolio[index];
                  return Dismissible(
                    key: Key(player['id'].toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      removeFromPortfolio(player['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${player['name']} removed from portfolio')),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Card(
                      color: Colors.lightBlue[50], // Custom card color
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            player['photo'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
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
                      ),
                    ),
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
