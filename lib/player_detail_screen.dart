import 'package:flutter/material.dart';
import 'package:flutter_radar_chart/flutter_radar_chart.dart';
import 'api_service.dart';

class PlayerDetailScreen extends StatefulWidget {
  final int playerId;
  final int userId;

  PlayerDetailScreen({required this.playerId, required this.userId});

  @override
  _PlayerDetailScreenState createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? player;
  Map<String, dynamic>? agent;

  @override
  void initState() {
    super.initState();
    fetchPlayer();
  }

  Future<void> fetchPlayer() async {
    try {
      final playerData = await apiService.fetchPlayerStats(widget.playerId, 2023);
      final agentData = await apiService.getAgentByPlayerId(widget.playerId);
      setState(() {
        player = playerData;
        agent = agentData;
      });
    } catch (e) {
      print(e);
      setState(() {
        player = {};
      });
    }
  }

  double calculateShotAccuracy(Map<String, dynamic> player) {
    int? totalShots = player['shots_total'];
    int? shotsOnTarget = player['shots_on'];
    if (totalShots != null && shotsOnTarget != null && totalShots > 0) {
      return shotsOnTarget / totalShots;
    }
    return 0.0;
  }

  double calculatePassAccuracy(Map<String, dynamic> player) {
    return player['passes_accuracy'] != null ? player['passes_accuracy'] / 100 : 0.0;
  }

  double calculateDribbleSuccess(Map<String, dynamic> player) {
    int? dribbleAttempts = player['dribbles_attempts'];
    int? dribbleSuccess = player['dribbles_success'];
    if (dribbleAttempts != null && dribbleSuccess != null && dribbleAttempts > 0) {
      return dribbleSuccess / dribbleAttempts;
    }
    return 0.0;
  }

  double calculateFairness(Map<String, dynamic> player) {
    int tackles = player['tackles_total'] ?? 0;
    int fouls = player['fouls_committed'] ?? 0;
    int yellowCards = player['cards_yellow'] ?? 0;
    int yellowRedCards = player['cards_yellowred'] ?? 0;
    int redCards = player['cards_red'] ?? 0;

    double tackleWeight = 1;
    double foulWeight = 1;
    double yellowCardPenalty = 1;
    double yellowRedCardPenalty = 2;
    double redCardPenalty = 3;

    double fairnessScore = (fouls * foulWeight) / ((tackles * tackleWeight) - (yellowCards * yellowCardPenalty) - (yellowRedCards * yellowRedCardPenalty) - (redCards * redCardPenalty));

    if (fairnessScore < 0) fairnessScore = 0;
    if (fairnessScore > 1) fairnessScore = 1;

    return fairnessScore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player != null && player!['name'] != null ? player!['name'] : 'Loading...'),
      ),
      body: player == null
          ? Center(child: CircularProgressIndicator())
          : Container(
        color: Colors.green[400],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(player!['photo'] ?? 'https://via.placeholder.com/150'),
                ),
              ),
              SizedBox(height: 16.0),
              Center(
                child: Text(
                  player!['name'] ?? 'Unknown',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8.0),
              buildCard('Team', player!['team']),
              buildCard('Age', player!['age'].toString()),
              buildCard('Nationality', player!['nationality']),
              buildCard('Games Played', player!['games_played'].toString()),
              buildCard('Goals', player!['goals'].toString()),
              buildCard('Assists', player!['assists'].toString()),
              if (player!['rating'] != null) buildCard('Rating', player!['rating']!.toStringAsFixed(2)),
              if (agent != null) ...[
                SizedBox(height: 16.0),
                Text(
                  'Agent Information',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                buildCard('Agent Name', agent!['name']),
                buildCard('Agent Email', agent!['email']),
              ],
              SizedBox(height: 16.0),
              Text(
                'Player Performance',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              playerPerformanceChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard(String title, String subtitle) {
    return Card(
      color: Colors.lightBlue[50],
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget playerPerformanceChart() {
    double shotAccuracy = calculateShotAccuracy(player!);
    double passAccuracy = calculatePassAccuracy(player!);
    double dribbleSuccess = calculateDribbleSuccess(player!);
    double fairness = calculateFairness(player!);

    print("Shot Accuracy: $shotAccuracy, Pass Accuracy: $passAccuracy, Dribble Success: $dribbleSuccess, Fairness: $fairness");

    return SizedBox(
      height: 300,
      child: RadarChart.light(
        ticks: [0, 20, 40, 60, 80, 100],
        features: ['Shot Accuracy', 'Pass Accuracy', 'Dribble Success', 'Fairness'],
        data: [
          [shotAccuracy * 100, passAccuracy * 100, dribbleSuccess * 100, fairness * 100]
        ],
      ),
    );
  }
}
