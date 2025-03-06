import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wasteapptest/Dasboard_Page/dashboard.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, dynamic>> newsItems = [];
  bool isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

Future<void> fetchNews() async {
  const apiKey = '4976a49c841d4519b5a32851ccc51f54';
  const url = 'https://newsapi.org/v2/everything?' 'q=sampah+OR+waste+management+OR+recycling&' 'language=id&' 'sortBy=publishedAt&' 'apiKey=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          newsItems = List<Map<String, dynamic>>.from(data['articles'])
              .take(5)
              .toList();
          isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to load news');
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
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
        break;
      case 2:
        break;
      case 3:
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf1f4ff),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2cac69),
        title: const Text(
          'Berita & Komunitas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: fetchNews,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Berita Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      Column(
                        children: List.generate(5, (_) => _buildSkeletonCard()),
                      )
                    else if (newsItems.isEmpty)
                      const Center(
                        child: Text('Tidak ada berita tersedia'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: newsItems.length,
                        itemBuilder: (context, index) {
                          final article = newsItems[index];
                          return _buildNewsCard(article);
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
         Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
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
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Home button
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(0, context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                color: _selectedIndex == 0
                                    ? const Color(0xFF2cac69)
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Home',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedIndex == 0
                                      ? const Color(0xFF2cac69)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 4,
                                width: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedIndex == 0
                                      ? const Color(0xFF2cac69)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(1, context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                color: _selectedIndex == 1
                                    ? const Color(0xFF2cac69)
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'News',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedIndex == 1
                                      ? const Color(0xFF2cac69)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 4,
                                width: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedIndex == 1
                                      ? const Color(0xFF2cac69)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(3, context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart_outlined,
                                color: _selectedIndex == 3
                                    ? const Color(0xFF2cac69)
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Leaderboard',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedIndex == 3
                                      ? const Color(0xFF2cac69)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 4,
                                width: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedIndex == 3
                                      ? const Color(0xFF2cac69)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onItemTapped(4, context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: _selectedIndex == 4
                                    ? const Color(0xFF2cac69)
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedIndex == 4
                                      ? const Color(0xFF2cac69)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height: 4,
                                width: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedIndex == 4
                                      ? const Color(0xFF2cac69)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF2cac69),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    final DateTime publishedAt = DateTime.parse(article['publishedAt']);
    final String formattedDate = DateFormat('dd MMM yyyy').format(publishedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article['urlToImage'] != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                article['urlToImage'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article['description'] ?? 'No Description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      article['source']['name'] ?? 'Unknown Source',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2cac69),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
