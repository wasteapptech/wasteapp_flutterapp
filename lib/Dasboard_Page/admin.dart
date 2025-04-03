import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _showKegiatanForm = false;
  bool _showPassword = false;
  int _selectedTabIndex = 0;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  DateTime? _selectedDate;
  String? _currentKegiatanId;

  List<dynamic> _kegiatanList = [];

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _judulController.dispose();
    _deskripsiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[700]!,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _adminLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api-wasteapp.vercel.app/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        json.decode(response.body);
        await _showSuccessDialog(
          title: 'Login Berhasil',
          message: 'Kamu berhasil login ke admin panel',
          buttonText: 'Lanjutkan',
        );
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
        _fetchKegiatan();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Login gagal. Periksa username dan password Anda.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

  // Update the fetch kegiatan function
  Future<void> _fetchKegiatan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/kegiatan'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _kegiatanList = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Gagal mengambil data kegiatan');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

// Update the tambah/update kegiatan function
  Future<void> _tambahKegiatan() async {
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      _showErrorDialog('Judul dan deskripsi harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response;
      if (_currentKegiatanId != null) {
        response = await http.put(
          Uri.parse(
              'https://api-wasteapp.vercel.app/api/kegiatan/$_currentKegiatanId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'judul': _judulController.text,
            'tanggal': _tanggalController.text,
            'deskripsi': _deskripsiController.text,
          }),
        );
      } else {
        response = await http.post(
          Uri.parse('https://api-wasteapp.vercel.app/api/kegiatan'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'judul': _judulController.text,
            'tanggal': _tanggalController.text,
            'deskripsi': _deskripsiController.text,
          }),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _judulController.clear();
        _deskripsiController.clear();
        setState(() {
          _showKegiatanForm = false;
          _isLoading = false;
          _currentKegiatanId = null;
        });
        _fetchKegiatan();
        _showSuccessDialog(
            message: _currentKegiatanId != null
                ? 'Kegiatan berhasil diupdate'
                : 'Kegiatan berhasil ditambahkan');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(_currentKegiatanId != null
            ? 'Gagal mengupdate kegiatan'
            : 'Gagal menambahkan kegiatan');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Terjadi kesalahan. Coba lagi nanti.');
    }
  }

// Update the delete function
  Future<void> _hapusKegiatan(String id) async {
    try {
      final url = 'https://api-wasteapp.vercel.app/api/kegiatan/$id';
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        // Refresh the kegiatan list after successful deletion
        _fetchKegiatan();
        await _showSuccessDialog(message: 'Kegiatan berhasil dihapus');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Gagal menghapus kegiatan';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/svg/error-svgrepo-com.svg',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
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

  Future<void> _showSuccessDialog({
    String title = 'Berhasil',
    String message = 'Operasi berhasil',
    String buttonText = 'Lanjutkan',
    VoidCallback? onPressed,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/svg/success-svgrepo-com.svg',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onPressed ?? () => Navigator.of(ctx).pop(),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
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

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Text('Konfirmasi Hapus'),
            content:
                const Text('Apakah Anda yakin ingin menghapus kegiatan ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _usernameController.clear();
      _passwordController.clear();
      _kegiatanList.clear();
      _selectedTabIndex = 0;
      _currentKegiatanId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              )
            : _isLoggedIn
                ? _buildAdminContent()
                : _buildLoginScreen(),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo1.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Admin Login',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.green[700],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            _buildLoginCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.person, color: Colors.green[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _adminLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: Colors.green.withOpacity(0.3),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContent() {
    return Column(
      children: [
        _buildAdminHeader(),
        _buildTabBar(),
        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildKegiatanContent(),
              _buildDaftarHargaContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green[700],
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selamat datang, Admin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? Colors.green[700]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event,
                      color: _selectedTabIndex == 0
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kegiatan',
                      style: TextStyle(
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? Colors.green[700]
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: _selectedTabIndex == 1
                          ? Colors.white
                          : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daftar Harga',
                      style: TextStyle(
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKegiatanContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Kegiatan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showKegiatanForm = true;
                    _currentKegiatanId = null;
                    _judulController.clear();
                    _deskripsiController.clear();
                  });
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Tambah Kegiatan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showKegiatanForm) _buildKegiatanForm(),
          const SizedBox(height: 16),
          _buildKegiatanList(),
        ],
      ),
    );
  }

  Widget _buildDaftarHargaContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Daftar Harga Sampah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
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
            child: Column(
              children: [
                _buildHargaItem('Plastik', 'Rp 3.000/kg'),
                const Divider(height: 24),
                _buildHargaItem('Kertas', 'Rp 2.500/kg'),
                const Divider(height: 24),
                _buildHargaItem('Kaleng', 'Rp 4.000/kg'),
                const Divider(height: 24),
                _buildHargaItem('Kaca', 'Rp 1.500/kg'),
                const Divider(height: 24),
                _buildHargaItem('Elektronik', 'Rp 5.000/kg'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to edit harga page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Edit Daftar Harga'),
          ),
        ],
      ),
    );
  }

  Widget _buildHargaItem(String jenis, String harga) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          jenis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          harga,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }

  Widget _buildKegiatanForm() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentKegiatanId != null
                    ? 'Edit Kegiatan'
                    : 'Tambah Kegiatan Baru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _showKegiatanForm = false;
                    _currentKegiatanId = null;
                    _judulController.clear();
                    _deskripsiController.clear();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _judulController,
            decoration: InputDecoration(
              labelText: 'judul Kegiatan',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.event, color: Colors.green[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tanggalController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Tanggal',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.calendar_today, color: Colors.green[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deskripsiController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.description, color: Colors.green[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showKegiatanForm = false;
                      _currentKegiatanId = null;
                      _judulController.clear();
                      _deskripsiController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    side: BorderSide(color: Colors.green[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _tambahKegiatan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKegiatanList() {
    if (_kegiatanList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            Icon(
              Icons.event_note,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada kegiatan tersedia',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kegiatanList.length,
      itemBuilder: (context, index) {
        final kegiatan = _kegiatanList[index];
        return Container(
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event,
                color: Colors.green[700],
              ),
            ),
            title: Text(
              kegiatan['judul'] ?? 'No Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  kegiatan['deskripsi'] ?? 'No Description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tanggal: ${kegiatan['tanggal'] ?? 'No Date'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus'),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  _judulController.text = kegiatan['judul'] ?? '';
                  _deskripsiController.text = kegiatan['deskripsi'] ?? '';
                  _tanggalController.text = kegiatan['tanggal'] ??
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
                  _selectedDate =
                      DateTime.tryParse(kegiatan['tanggal'] ?? '') ??
                          DateTime.now();

                  setState(() {
                    _showKegiatanForm = true;
                    _currentKegiatanId =
                        kegiatan['id']; 
                  });
                } else if (value == 'delete') {
                  bool confirm = await _showDeleteConfirmationDialog();
                  if (confirm) {
                    _hapusKegiatan(kegiatan['id']);
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}
