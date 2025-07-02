import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class LeaderboardUserPage extends StatefulWidget {
  final String email;
  final String username;
  final String? avatarUrl;

  const LeaderboardUserPage({
    super.key,
    required this.email,
    required this.username,
    this.avatarUrl,
  });

  @override
  State<LeaderboardUserPage> createState() => _LeaderboardUserPageState();
}

class _LeaderboardUserPageState extends State<LeaderboardUserPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String userRank = "Pemula";
  Color rankColor = Colors.grey;
  AnimationController? _animationController;
  Animation<double>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
      );
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
      );
      _fetchUserData();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api-wasteapp.vercel.app/api/transaksi/user/${widget.email}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = data;
          isLoading = false;
          _calculateUserRank();
        });
        _animationController?.forward();
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching user data: $e');
    }
  }

  void _calculateUserRank() {
    final totalTransactions =
        userData?['transactionSummary']['totalSemuaTransaksi'] ?? 0;
    if (totalTransactions > 5000) {
      userRank = "Penabung Sampah Legendaris";
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (totalTransactions > 3000) {
      userRank = "Penabung Sampah Handal";
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (totalTransactions > 1000) {
      userRank = "Penabung Sampah Aktif";
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      userRank = "Penabung Pemula";
      rankColor = const Color(0xFF64B5F6); // Blue
    }
  }

  double _getRankProgress() {
    final totalTransactions =
        userData?['transactionSummary']['totalSemuaTransaksi'] ?? 0;
    if (totalTransactions > 5000) return 1.0;
    if (totalTransactions > 3000) return 0.8;
    if (totalTransactions > 1000) return 0.6;
    return totalTransactions / 1000.0;
  }

  String _getLastTransactionDate() {
    final transactions = (userData?['transactions'] as List?) ?? [];
    if (transactions.isEmpty) return "Belum ada transaksi";

    final lastTransaction = transactions.first;
    final date = DateTime.parse(lastTransaction['createdAt']);
    return DateFormat('dd MMMM yyyy', 'id').format(date);
  }

  Widget _buildModernHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation?.value ?? 0.0),
          child: Opacity(
            opacity: _fadeAnimation?.value ?? 1.0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2cac69),
                    Color(0xFF1f8f54),
                    Color(0xFF16724a),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2cac69).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: widget.avatarUrl != null
                              ? NetworkImage(widget.avatarUrl!)
                              : const AssetImage('assets/images/profile.png')
                                  as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: rankColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            _getRankIcon(),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      userRank,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRankProgressBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getRankIcon() {
    final totalTransactions =
        userData?['transactionSummary']['totalSemuaTransaksi'] ?? 0;
    if (totalTransactions > 5000) return Icons.emoji_events;
    if (totalTransactions > 3000) return Icons.military_tech;
    if (totalTransactions > 1000) return Icons.star;
    return Icons.person;
  }

  Widget _buildRankProgressBar() {
    final progress = _getRankProgress();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress ke Level Berikutnya',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastTransactionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2cac69).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF2cac69),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Terakhir Menabung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2cac69),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getLastTransactionDate(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTable() {
    final transactions = (userData?['transactions'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Riwayat Transaksi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2cac69),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DataTable(
              columnSpacing: 20,
              dataRowHeight: 70,
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF2cac69).withOpacity(0.1),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2cac69),
              ),
              columns: const [
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Total Item')),
                DataColumn(label: Text('Total')),
              ],
              rows: transactions.map<DataRow>((transaction) {
                final date = DateTime.parse(transaction['createdAt']);
                final items = (transaction['items'] as List);

                // Calculate total items
                final totalItems = items.fold<int>(
                    0, (sum, item) => sum + (item['jumlah'] as int));

                String itemDisplay = items.first['nama'].toString();

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2cac69).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yy').format(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2cac69),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          itemDisplay,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$totalItems pcs',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(transaction['totalTransaksi']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2cac69)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Memuat data penabung...',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final summary = userData?['transactionSummary'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF2cac69),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detail Penabung',
          style: TextStyle(
            color: Color(0xFF2cac69),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: const Color(0xFF2cac69),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernHeader(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernStatCard(
                        'Total Transaksi',
                        summary['totalTransactions'].toString(),
                        Icons.repeat_rounded,
                        const Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernStatCard(
                        'Total Tabungan',
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(summary['totalSemuaTransaksi']),
                        Icons.account_balance_wallet_rounded,
                        const Color(0xFF2cac69),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLastTransactionCard(),
                const SizedBox(height: 24),
                _buildTransactionTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
