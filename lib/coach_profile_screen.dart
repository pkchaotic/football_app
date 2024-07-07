import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'database_helper.dart';  // Import the DatabaseHelper

class CoachProfileScreen extends StatefulWidget {
  final int userId;

  CoachProfileScreen({required this.userId});

  @override
  _CoachProfileScreenState createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final ApiService apiService = ApiService();
  final DatabaseHelper dbHelper = DatabaseHelper.instance; // Initialize DatabaseHelper
  Map<String, dynamic>? coach;
  List<Map<String, dynamic>> watchlist = [];
  List<Map<String, dynamic>> searchResults = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeData();
    printWatchList();  // Call printWatchList in initState
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
    print('Fetched watchlist: $watchlist');
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

  Future<void> printWatchList() async {
    final watchListEntries = await dbHelper.getAllWatchListEntries();
    print('Watch List Table: $watchListEntries');
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
              'Name: ${coach!['name']}',
              style: TextStyle(
                  fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            Text('Role: ${coach!['role']}'),
            SizedBox(height: 16.0),
            Text(
              'Watchlist',
              style: TextStyle(
                  fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: watchlist.length,
                itemBuilder: (context, index) {
                  final player = watchlist[index];
                  return ListTile(
                    title: Text(player['name']),
                    subtitle: Text('Team: ${player['team']}'),
                    onTap: () {
                      // Implement navigation to player details
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
                    title: Text(player['name'] ?? 'Unknown'),
                    subtitle: Text('Team: ${player['team'] ?? 'Unknown'}'),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        addToWatchlist(player['id']);
                      },
                    ),
                    onTap: () {
                      // Implement navigation to player details
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
