import 'package:flutter/material.dart';
import 'package:wasteapptest/Support_Page/news_page.dart';
import 'package:wasteapptest/Survey_Page/survey.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
        // Tambahkan navigasi untuk halaman Scan
        break;
      case 3:
        // Tambahkan navigasi untuk halaman Statistics
        break;
      case 4:
        // Tambahkan navigasi untuk halaman Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffefefe),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2cac69),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 60,
                        child: Image.asset(
                          'assets/images/people_recycling.png',
                          height: 169,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo kamu yang tersedia',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Rp. 50.000,00',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2cac69),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        'Tempat Sampah Terdekat',
                        Icons.location_on_outlined,
                      ),
                      _buildMenuCard(
                        'Hasil Transaksi Sampah',
                        Icons.receipt_long_outlined,
                      ),
                      _buildMenuCard(
                        'Layanan Pelanggan',
                        Icons.headset_mic_outlined,
                      ),
                      _buildMenuCard(
                        'Dompet',
                        Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ),
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildInfoCard(
                      'Survei', // Title
                      'Mohon isi survei berikut untuk membantu kami mengembangkan aplikasi ini', // Description
                      context, // BuildContext
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      'Admin', // Title
                      'Hanya admin yang bisa mengakses fitur ini', // Description
                      context, // BuildContext
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              ],
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

  Widget _buildMenuCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xfff7fef9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFedf9f4), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 50,
              color: const Color(0xFF88C9A2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String description, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SurveyPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfff7fef9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFedf9f4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
