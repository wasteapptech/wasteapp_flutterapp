import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class Transaction {
  final DateTime date;
  final String type;
  final int amount;
  final String note;
  final String? bankName; // Add this field

  Transaction({
    required this.date,
    required this.type,
    required this.amount,
    required this.note,
    this.bankName, // Add this parameter
  });

  // Add these methods for JSON conversion
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'type': type,
        'amount': amount,
        'note': note,
        'bankName': bankName, // Add this field
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        date: DateTime.parse(json['date']),
        type: json['type'],
        amount: json['amount'],
        note: json['note'],
        bankName: json['bankName'], // Add this field
      );
}

class BankOption {
  final String name;
  final String logo;

  BankOption({required this.name, required this.logo});
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int _userBalance = 0;
  bool _isLoadingBalance = true;
  String _cardNumber = '';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<Transaction> _recentTransactions = [];
  String? _selectedBank;

  final List<BankOption> _bankOptions = [
    BankOption(name: 'Bank Mandiri', logo: 'assets/images/mandiri.png'),
    BankOption(name: 'Bank Rakyat Indonesia', logo: 'assets/images/bri.png'),
    BankOption(name: 'Bank Central Asia', logo: 'assets/images/bca.png'),
    BankOption(name: 'Bank Negara Indonesia', logo: 'assets/images/bni.png'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
    _generateCardNumber();
    _loadTransactions(); // Add this line
  }

  void _generateCardNumber() {
    if (_cardNumber.isEmpty) {
      String number = '4000 1234 5678 9012'; // Static card number
      setState(() {
        _cardNumber = number;
      });
    }
  }

  Future<void> _fetchUserBalance() async {
    setState(() => _isLoadingBalance = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? '';

      if (userEmail.isEmpty) {
        setState(() => _isLoadingBalance = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://api-wasteapp.vercel.app/api/transaksi/user/$userEmail'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userBalance = data['totalSemuaTransaksi'] ?? 0;
          _isLoadingBalance = false;
        });
      } else {
        setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      print('Error fetching balance: $e');
      setState(() => _isLoadingBalance = false);
    }
  }

  void _showQRCodeDialog() {
    // Only show dialog if card number is valid
    if (_cardNumber.isEmpty) {
      _generateCardNumber(); // Generate if empty
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan QRIS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nomor Kartu: ${_cardNumber.replaceAll(' ', '')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _cardNumber.replaceAll(
                        ' ', ''), // Remove spaces from card number
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (context, error) => const Center(
                      child: Text(
                        'Error generating QR Code',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Saldo: ${NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_userBalance)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tarik Saldo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBank,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      border: InputBorder.none,
                      hintText: 'Pilih Bank',
                    ),
                    items: _bankOptions.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank.name,
                        child: Row(
                          children: [
                            Image.asset(
                              bank.logo,
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(bank.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBank = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedBank == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Silakan pilih bank terlebih dahulu')),
                      );
                      return;
                    }
                    _processWithdrawal();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tarik Saldo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processWithdrawal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? '';
      final withdrawAmount = int.tryParse(_amountController.text) ?? 0;

      if (withdrawAmount > _userBalance) {
        _showInsufficientBalanceDialog();
        return;
      }

      if (withdrawAmount <= 0) {
        _showErrorDialog('Nominal penarikan harus lebih dari 0');
        return;
      }

      final response = await http.put(
        Uri.parse(
            'https://api-wasteapp.vercel.app/api/transaksi/user/$userEmail/balance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'balance': withdrawAmount,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          _recentTransactions.insert(
            0,
            Transaction(
              date: DateTime.now(),
              type: 'withdrawal',
              amount: withdrawAmount,
              note: _noteController.text,
              bankName: _selectedBank, // Add this line
            ),
          );
          _userBalance = responseData['balance'] ?? 0;
        });

        await _saveTransactions();
        Navigator.pop(context);
        await _showSuccessDialog(withdrawAmount);
        await _fetchUserBalance();
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['error'] ?? 'Gagal melakukan penarikan');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      _amountController.clear();
      _noteController.clear();
      _selectedBank = null;
    }
  }

  Future<void> _showSuccessDialog(int amount) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/congrats.png',
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Penarikan Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Rp ${NumberFormat('#,###').format(amount)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _generateReceipt(amount),
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'Download Receipt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(color: Color(0xFF2cac69)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateReceipt(int amount) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WasteApp - Bukti Penarikan',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
              pw.Text('Nomor Kartu: $_cardNumber'),
              pw.Text('Bank Tujuan: $_selectedBank'),
              pw.SizedBox(height: 20),
              pw.Text('Nominal: Rp ${NumberFormat('#,###').format(amount)}'),
              pw.Text('Catatan: ${_noteController.text}'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2cac69)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dompet Digital',
          style: TextStyle(
            color: Color(0xFF2cac69),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWalletCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2cac69),
            Color(0xFF30CF7A),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2cac69).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo Tersedia',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingBalance
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(_userBalance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'WasteApp Card',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.contactless_rounded,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ],
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.qr_code,
          label: 'QRIS',
          onTap: _showQRCodeDialog,
        ),
        _buildActionButton(
          icon: Icons.money_off,
          label: 'Tarik Saldo',
          onTap: _showWithdrawDialog,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2cac69),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2cac69),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi Terakhir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _recentTransactions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Tidak ada transaksi',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _recentTransactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF2cac69).withOpacity(0.1),
                        child: Icon(
                          transaction.type == 'withdrawal'
                              ? Icons.money_off
                              : Icons.attach_money,
                          color: const Color(0xFF2cac69),
                        ),
                      ),
                      title: Text(
                        transaction.type == 'withdrawal'
                            ? 'Penarikan Saldo'
                            : 'Penambahan Saldo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                          if (transaction.bankName != null)
                            Text(
                              'via ${transaction.bankName}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(transaction.amount),
                        style: const TextStyle(
                          color: Color(0xFF2cac69),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/ohno.png',
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Saldo Tidak Mencukupi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Saldo anda saat ini: ${NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_userBalance)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add this method to save transactions to SharedPreferences
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson =
        _recentTransactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions', json.encode(transactionsJson));
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getString('transactions');
    if (transactionsString != null) {
      final transactionsJson = json.decode(transactionsString) as List;
      setState(() {
        _recentTransactions = transactionsJson
            .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
            .toList();
      });
    }
  }
}
