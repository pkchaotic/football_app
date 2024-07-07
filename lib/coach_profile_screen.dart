import 'package:flutter/material.dart';
import 'api_service.dart';
import 'player_detail_screen.dart';
import 'login_screen.dart';
import 'database_helper.dart';

class CoachProfileScreen extends StatefulWidget {
  final int userId;

  CoachProfileScreen({required this.userId});

  @override
  _CoachProfileScreenState createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final ApiService apiService = ApiService();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  Map<String, dynamic>? coach;
  List<Map<String, dynamic>> watchlist = [];
  List<Map<String, dynamic>> searchResults = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await fetchCoach();
    await fetchWatchlist();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCoach() async {
    final coachData = await apiService.getUserById(widget.userId);
    setState(() {
      coach = coachData;
    });
  }

  Future<void> fetchWatchlist() async {
    final players = await apiService.getPlayerWatchList(widget.userId);
    setState(() {
      watchlist = players;
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

  Future<void> addToWatchlist(int playerId) async {
    await apiService.watchPlayer(playerId, widget.userId);
    await fetchWatchlist();
  }

  Future<void> removeFromWatchlist(int playerId) async {
    await dbHelper.removeFromWatchList(playerId, widget.userId);
    await fetchWatchlist();
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
        title: Text(coach != null ? coach!['name'] : 'Loading...'),
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
                    coach!['photo'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: ${coach!['name']}',
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    Text('Role: ${coach!['role']}'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Text(
              'Watchlist',
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
                            addToWatchlist(player['id']);
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
                itemCount: watchlist.length,
                itemBuilder: (context, index) {
                  final player = watchlist[index];
                  return Dismissible(
                    key: Key(player['id'].toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      removeFromWatchlist(player['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${player['name']} removed from watchlist')),
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
