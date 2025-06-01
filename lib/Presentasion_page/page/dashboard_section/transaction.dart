import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';

class TransactionItem {
  final String nama;
  final int hargaSatuan;
  final int jumlah;
  final int subtotal;

  TransactionItem({
    required this.nama,
    required this.hargaSatuan,
    required this.jumlah,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    try {
      return TransactionItem(
        nama: json['nama']?.toString() ?? '',
        hargaSatuan: int.tryParse(json['hargaSatuan']?.toString() ?? '0') ?? 0,
        jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
        subtotal: int.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      print('Error parsing TransactionItem from JSON: $e');
      rethrow;
    }
  }
}

class Transaction {
  final String id;
  final DateTime createdAt;
  final String email;
  final List<TransactionItem> items;
  final int totalTransaksi;
  final String username;

  Transaction({
    required this.id,
    required this.createdAt,
    required this.email,
    required this.items,
    required this.totalTransaksi,
    required this.username,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      return Transaction(
        id: json['id']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        email: json['email']?.toString() ?? '',
        items: (json['items'] as List?)
            ?.map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
            .toList() ?? [],
        totalTransaksi: int.tryParse(json['totalTransaksi']?.toString() ?? '0') ?? 0,
        username: json['username']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing Transaction from JSON: $e');
      rethrow;
    }
  }
}

class TransactionPage extends StatefulWidget {
  final List<Map<String, dynamic>> detectedItems;
  final int totalAmount;

  const TransactionPage({
    super.key,
    required this.detectedItems,
    required this.totalAmount,
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}


class _TransactionPageState extends State<TransactionPage> {
  bool _isLoading = false;
  String _username = '';
  String _email = '';
  String? _avatarUrl;

  List<Transaction> _transactions = [];
  bool _isLoadingTransactions = false;
  int _totalSemuaTransaksi = 0;
  int _jumlahTransaksi = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID').then((_) {
      _loadUserData();
      _fetchTransactions();
    });
  }

  Future<void> _fetchTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? '';

      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/transaksi/user/$userEmail'),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        if (responseData == null) {
          throw Exception('Response data is null');
        }

        final List<dynamic>? transactions = responseData['transaksi'] as List<dynamic>?;
        
        if (transactions == null) {
          throw Exception('Transactions data is null');
        }

        final List<Transaction> transactionList = [];
        
        for (var json in transactions) {  
          final transaction = Transaction.fromJson(json as Map<String, dynamic>);
          transactionList.add(transaction);
        }

        setState(() {
          _transactions = transactionList;
          _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Update total values
          _totalSemuaTransaksi = responseData['totalSemuaTransaksi'] ?? 0;
          _jumlahTransaksi = responseData['jumlahTransaksi'] ?? 0;
        });
      } else {
        throw Exception('Failed to fetch transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchTransactions: $e');
      _showErrorDialog('Error loading transactions: $e');
    } finally {
      setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _refreshTransactions() async {
    setState(() => _isLoadingTransactions = true);
    await _fetchTransactions();
  }

  String _formatDate(DateTime date) {
    final jakartaTime = date.toUtc().add(const Duration(hours: 7));
    return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(jakartaTime);
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? '';
      
      setState(() {
        _username = userName;
        _email = prefs.getString('userEmail') ?? '';
      });

      // Fetch avatar URL for the current user
      if (userName.isNotEmpty) {
        _avatarUrl = await _fetchUserAvatar(userName);
        setState(() {});
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _fetchUserAvatar(String username) async {
    try {
      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/user/profile?name=$username'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['avatarUrl'] as String?;
      }
    } catch (e) {
      print('Error fetching avatar: $e');
    }
    return null;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      constraints: const BoxConstraints(maxHeight: 300), // Set maximum height
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/notfound.png',
              height: 120, // Reduced height
              width: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Kamu tidak memiliki sampah yang ingin ditabung',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20), // Reduced spacing
            SizedBox(
              width: 120, // Reduced button width
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2cac69),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10), // Reduced padding
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    fontSize: 14, // Smaller font size
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTransaction() async {
    if (!mounted) return;
    
    if (widget.detectedItems.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: _buildEmptyState(),
        ),
      );
      return;
    }
  
    setState(() => _isLoading = true);
  
    try {
      final items = widget.detectedItems.map((item) => {
        'nama': item['className'].toString().toLowerCase(),
        'jumlah': 1,
      }).toList();
  
      final response = await http.post(
        Uri.parse('https://api-wasteapp.vercel.app/api/transaksi'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _email,
          'username': _username,
          'items': items,
        }),
      );
  
      if (!mounted) return;
  
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchTransactions();
        await _showSuccessDialog();
      } else {
        _showErrorDialog('Gagal mengirim transaksi');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _showSuccessDialog() async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // Prevent dialog dismiss on back button
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/congrats.png',
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Transaksi Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sampah berhasil ditabung ke dalam akun anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(ctx).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2cac69),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2cac69),
        title: const Text(
          'Konfirmasi Tabungan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshTransactions,
              color: const Color(0xFF2cac69),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const AssetImage('assets/images/profile.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  _email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Items List
                    ...widget.detectedItems.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFF2cac69),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['className'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      '1 pcs',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${item['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2cac69),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 24),

                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2cac69),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Transaksi',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                'Rp $_totalSemuaTransaksi',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jumlah Transaksi',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                '$_jumlahTransaksi kali',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2cac69),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tabung Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Transaction History Section
                    const Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingTransactions)
                      const Center(child: CircularProgressIndicator())
                    else if (_transactions.isEmpty)
                      Center(
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    else
                      ...(_transactions.map((transaction) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              title: Text(
                                'Tanggal: ${_formatDate(transaction.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              subtitle: Text(
                                'Total: Rp ${transaction.totalTransaksi}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2cac69),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: transaction.items
                                        .map((item) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.nama,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontFamily: 'Poppins',
                                                          ),
                                                        ),
                                                        Text(
                                                          '${item.jumlah} x Rp ${item.hargaSatuan}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.grey[600],
                                                            fontFamily: 'Poppins',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rp ${item.subtotal}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2cac69),
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                  ],
                ),
              ),
            ),
    );
  }
}
