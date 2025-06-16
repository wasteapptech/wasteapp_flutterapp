import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class WastePrice {
  final String name;
  int price;

  WastePrice({
    required this.name,
    required this.price,
  });

  factory WastePrice.fromJson(MapEntry<String, dynamic> entry) {
    return WastePrice(
      name: entry.key,
      price: entry.value as int,
    );
  }
}

class SensorNotification {
  final String id;
  final DateTime createdAt;
  final String nameSensor;
  final DateTime timestamp;
  final double value;

  SensorNotification({
    required this.id,
    required this.createdAt,
    required this.nameSensor,
    required this.timestamp,
    required this.value,
  });

  factory SensorNotification.fromJson(Map<String, dynamic> json) {
    return SensorNotification(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      nameSensor: json['nameSensor'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      value: (json['value'] is int) 
          ? json['value'].toDouble() 
          : json['value']?.toDouble() ?? 0.0,
    );
  }
}

class _AdminPageState extends State<AdminPage> {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _showKegiatanForm = false;
  bool _showPassword = false;
  int _selectedTabIndex = 0;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  DateTime? _selectedDate;
  String? _currentKegiatanId;
  File? _selectedImage;

  List<WastePrice> _wastePrices = [];
  bool _isEditingPrice = false;
  final Map<String, TextEditingController> _priceControllers = {};

  List<dynamic> _kegiatanList = [];
  final ImagePicker _picker = ImagePicker();

  List<SensorNotification> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _selectedDate = DateTime.now();
    if (_isLoggedIn) {
      _fetchPrices();
      _fetchNotifications();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _judulController.dispose();
    _deskripsiController.dispose();
    _tanggalController.dispose();
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoadingNotifications = true);

    try {
      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/sensor/data'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data
              .map((item) => SensorNotification.fromJson(item))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      _showErrorDialog('Failed to load notifications');
    } finally {
      setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> _selectImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
    });
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2cac69),
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
        await _showSuccessDialog(
          title: 'Login Berhasil',
          message: 'Kamu berhasil login ke admin panel',
          buttonText: 'Lanjutkan',
        );
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
        await _fetchPrices();
        await _fetchKegiatan();
        await _fetchNotifications();
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

  Future<void> _fetchPrices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api-wasteapp.vercel.app/api/harga'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _wastePrices =
              data.entries.map((entry) => WastePrice.fromJson(entry)).toList();

          // Initialize controllers
          _priceControllers.clear();
          for (var price in _wastePrices) {
            _priceControllers[price.name] = TextEditingController(
              text: price.price.toString(),
            );
          }
        });
      } else {
        _showErrorDialog('Gagal mengambil data harga: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching prices: $e');
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedPrices = {};
      for (var price in _wastePrices) {
        updatedPrices[price.name] =
            int.parse(_priceControllers[price.name]!.text);
      }

      final response = await http.put(
        Uri.parse('https://api-wasteapp.vercel.app/api/harga'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedPrices),
      );

      if (response.statusCode == 200) {
        await _showSuccessDialog(
          title: 'Berhasil',
          message: 'Harga berhasil diperbarui',
        );
        await _fetchPrices();
        setState(() {
          _isEditingPrice = false;
        });
      } else {
        _showErrorDialog('Gagal memperbarui harga: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating prices: $e');
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  Future<void> _uploadKegiatan() async {
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      _showErrorDialog('Judul dan deskripsi harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        _currentKegiatanId != null ? 'PUT' : 'POST',
        Uri.parse(_currentKegiatanId != null
            ? 'https://api-wasteapp.vercel.app/api/kegiatan/$_currentKegiatanId'
            : 'https://api-wasteapp.vercel.app/api/kegiatan'),
      );

      request.fields['judul'] = _judulController.text;
      request.fields['tanggal'] = _tanggalController.text;
      request.fields['deskripsi'] = _deskripsiController.text;

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'gambar',
            _selectedImage!.path,
          ),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        _judulController.clear();
        _deskripsiController.clear();
        setState(() {
          _showKegiatanForm = false;
          _isLoading = false;
          _currentKegiatanId = null;
          _selectedImage = null;
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

  Future<void> _hapusKegiatan(String id) async {
    try {
      final url = 'https://api-wasteapp.vercel.app/api/kegiatan/$id';
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
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
                  Image.asset(
                    'assets/images/ohno.png',
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                  const SizedBox(height: 40),
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
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2cac69),
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
                Image.asset(
                  'assets/images/congrats.png',
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
                const SizedBox(height: 40),
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2cac69),
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
      _selectedImage = null;
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
            const Text(
              'Admin Login',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2cac69),
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
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF2cac69)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2cac69), width: 2),
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
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF2cac69)),
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
                borderSide:
                    const BorderSide(color: Color(0xFF2cac69), width: 2),
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
                backgroundColor: const Color(0xFF2cac69),
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
              _buildNotificationsContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2cac69),
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
          _buildTabItem(0, Icons.event, 'Kegiatan'),
          _buildTabItem(1, Icons.monetization_on, 'Daftar Harga'),
          _buildTabItem(2, Icons.notifications, 'Notifikasi'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedTabIndex == index
                ? const Color(0xFF2cac69)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _selectedTabIndex == index
                    ? Colors.white
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _selectedTabIndex == index
                      ? Colors.white
                      : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsContent() {
    if (_isLoadingNotifications) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: const Color(0xFF2cac69),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          
          IconData icon;
          Color color;
          String sensorDisplay;
          String valueDisplay;
          
          switch (notification.nameSensor) {
            case 'mq4':
              icon = Icons.local_fire_department;
              color = Colors.red;
              sensorDisplay = 'Gas Sensor';
              valueDisplay = '${notification.value.toStringAsFixed(0)} ppm';
              break;
            case 'dht-temp':
              icon = Icons.thermostat;
              color = Colors.orange;
              sensorDisplay = 'Temperature Sensor';
              valueDisplay = '${notification.value.toStringAsFixed(1)}°C';
              break;
            case 'dht-humidity':
              icon = Icons.water_drop;
              color = Colors.blue;
              sensorDisplay = 'Humidity Sensor';
              valueDisplay = '${notification.value.toStringAsFixed(1)}%';
              break;
            case 'ultrasonic1':
              icon = Icons.height;
              color = Colors.green;
              sensorDisplay = 'Organic Waste Level';
              valueDisplay = '${notification.value.toStringAsFixed(0)} %';
              break;
            case 'ultrasonic2':
              icon = Icons.height;
              color = Colors.purple;
              sensorDisplay = 'Inorganic Waste Level';
              valueDisplay = '${notification.value.toStringAsFixed(0)} %';
              break;
            default:
              icon = Icons.sensors;
              color = Colors.grey;
              sensorDisplay = notification.nameSensor;
              valueDisplay = notification.value.toString();
          }

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sensorDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      valueDisplay,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy HH:mm').format(notification.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
              const Text(
                'Daftar Kegiatan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
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
                  backgroundColor: const Color(0xFF2cac69),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Harga Sampah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
                ),
              ),
              if (!_isEditingPrice)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditingPrice = true;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Harga'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
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
                ..._wastePrices
                    .map((price) => Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    price.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _isEditingPrice
                                      ? TextField(
                                          controller:
                                              _priceControllers[price.name],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            prefixText: 'Rp ',
                                            suffixText: '/Pcs',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Rp ${price.price}/pcs',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2cac69),
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                ),
                              ],
                            ),
                            if (_wastePrices.last != price)
                              const Divider(height: 24),
                          ],
                        ))
                    .toList(),
                if (_isEditingPrice) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditingPrice = false;
                              // Reset controllers to original values
                              for (var price in _wastePrices) {
                                _priceControllers[price.name]!.text =
                                    price.price.toString();
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2cac69),
                            side: const BorderSide(color: Color(0xFF2cac69)),
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
                          onPressed: _updatePrices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2cac69),
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
              ],
            ),
          ),
        ],
      ),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
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
                    _selectedImage = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _judulController,
            decoration: InputDecoration(
              labelText: 'Judul Kegiatan',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.event, color: Color(0xFF2cac69)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2cac69), width: 2),
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
              prefixIcon:
                  const Icon(Icons.calendar_today, color: Color(0xFF2cac69)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2cac69), width: 2),
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
              prefixIcon:
                  const Icon(Icons.description, color: Color(0xFF2cac69)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF2cac69), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
          // Image upload section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gambar Kegiatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                Stack(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.red[700],
                        radius: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: Colors.white),
                          onPressed: _removeImage,
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan Gambar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
                      _selectedImage = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2cac69),
                    side: const BorderSide(color: Color(0xFF2cac69)),
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
                  onPressed: _uploadKegiatan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
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
          child: Column(
            children: [
              if (kegiatan['gambar'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    kegiatan['gambar'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Color(0xFF2cac69),
                  ),
                ),
                title: Text(
                  kegiatan['judul'] ?? 'No Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
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
                        _currentKegiatanId = kegiatan['id'];
                        _selectedImage = null;
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
            ],
          ),
        );
      },
    );
  }
}
