import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';  
import 'package:wasteapptest/Domain_page/machinelearning.dart';
import 'package:wasteapptest/Presentasion_page/page/nav_section/leaderboard_user_page.dart';
import 'package:wasteapptest/Presentasion_page/page/nav_section/news_page.dart';
import 'package:wasteapptest/Presentasion_page/page/nav_section/profile.dart';
import 'package:intl/intl.dart';


class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<UserScore> _leaderboard = [];
  String _currentUserName = '';
  int _selectedIndex = 3; 
  final Map<String, UserProfile> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _loadUserData(),
        _fetchUserProfiles(),
      ]);
      await _fetchLeaderboardData();
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('userProfileImage');
      final userName = prefs.getString('userName') ?? '';

      setState(() {
        _currentUserName = userName;
        if (imagePath != null && imagePath.isNotEmpty) {
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchUserProfiles() async {
    try {
      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/user/profiles'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        for (var profile in data) {
          final userProfile = UserProfile.fromJson(profile);
          _userProfiles[userProfile.name] = userProfile;
        }
      }
    } catch (e) {
      print('Error fetching user profiles: $e');
    }
  }

  Future<void> _fetchLeaderboardData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/transaksi'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<UserScore> scores = [];
        
        for (var userTransactions in data) {
          scores.add(UserScore(
            username: userTransactions['username'] as String,
            totalScore: userTransactions['totalSemuaTransaksi'] as int,
            transactionCount: userTransactions['jumlahTransaksi'] as int,
            avatarUrl: _userProfiles[userTransactions['username']]?.avatarUrl,
          ));
        }

        scores.sort((a, b) => b.totalScore.compareTo(a.totalScore));

        if (mounted) {
          setState(() {
            _leaderboard = scores;
          });
        }
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
    }
  }

  Widget _buildTopThree() {
    return Stack(
      children: [
        // Background gradient
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2cac69), Colors.white],
            ),
          ),
        ),
        
        Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_leaderboard.length > 1)
                  _buildPodiumItem(_leaderboard[1], 2),
                if (_leaderboard.isNotEmpty)
                  _buildPodiumItem(_leaderboard[0], 1),
                if (_leaderboard.length > 2)
                  _buildPodiumItem(_leaderboard[2], 3),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumItem(UserScore user, int position) {
    final isCurrentUser = user.username == _currentUserName;
    final double height = position == 1 ? 160 : position == 2 ? 140 : 120;
    final Color podiumColor = position == 1 
        ? const Color(0xFFFFD700) 
        : position == 2 
            ? const Color(0xFFE5E4E2) 
            : const Color(0xFFCD7F32);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardUserPage(
              email: _userProfiles[user.username]?.email ?? '',
              username: user.username,
              avatarUrl: user.avatarUrl,
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (position == 1)
            const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 40),
          if (position == 2)
            const Icon(Icons.stars, color: Color(0xFFC0C0C0), size: 40), 
          if (position == 3)
            const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 40), 


          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: podiumColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: podiumColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: position == 1 ? 45 : 35,
              backgroundColor: Colors.white,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : const AssetImage('assets/images/profile.png') as ImageProvider,
            ),
          ),
          const SizedBox(height: 8),
          
          // Username and stats
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: position == 1 ? 16 : 14,
                    color: isCurrentUser ? const Color(0xFF2cac69) : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.transactionCount} transaksi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Score container
          Container(
            width: 100,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  podiumColor,
                  podiumColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              boxShadow: [
                BoxShadow(
                  color: podiumColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(user.totalScore),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
      itemBuilder: (context, index) {
        final userScore = _leaderboard[index + 3];
        final isCurrentUser = userScore.username == _currentUserName;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaderboardUserPage(
                  email: _userProfiles[userScore.username]?.email ?? '',
                  username: userScore.username,
                  avatarUrl: userScore.avatarUrl,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2cac69).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 4}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2cac69),
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    backgroundImage: userScore.avatarUrl != null
                        ? NetworkImage(userScore.avatarUrl!)
                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userScore.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isCurrentUser ? const Color(0xFF2cac69) : Colors.black87,
                          ),
                        ),
                        Text(
                          '${userScore.transactionCount} transaksi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2cac69).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(userScore.totalScore),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2cac69),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NewsPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LeaderboardPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
  return Expanded(
    child: InkWell(
      onTap: () => _onItemTapped(index, context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index
                ? const Color(0xFF2cac69)
                : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _selectedIndex == index
                  ? const Color(0xFF2cac69)
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: _selectedIndex == index ? 20 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF2cac69),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBottomNavigationBar() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.article_outlined, 'News', 1),
              const SizedBox(width: 48), // Space for center button
              _buildNavItem(Icons.bar_chart_outlined, 'Leaderboard', 3),
              _buildNavItem(Icons.person_outlined, 'Profile', 4),
            ],
          ),
        ),
        Positioned(
          top: -25,
          child: GestureDetector(
            onTap: () => _onItemTapped(2, context),
            child: Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2cac69), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2cac69).withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2cac69),
          elevation: 0,
          title: const Text(
            'Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _initializeData, // Update this to use _initializeData
                color: const Color(0xFF2cac69),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildTopThree(),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Ranking Lainnya',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2cac69),
                          ),
                        ),
                      ),
                      _buildLeaderboardList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }
}

class UserScore {
  final String username;
  final int totalScore;
  final int transactionCount;
  final String? avatarUrl;

  UserScore({
    required this.username,
    required this.totalScore,
    required this.transactionCount,
    this.avatarUrl,
  });
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
