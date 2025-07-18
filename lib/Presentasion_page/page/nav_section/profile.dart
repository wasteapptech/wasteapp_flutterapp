import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteapptest/Domain_page/machinelearning.dart';
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';
import 'package:wasteapptest/Presentasion_page/page/auth_section/signin.dart';
import 'package:wasteapptest/Presentasion_page/page/nav_section/about_page.dart';
import 'package:wasteapptest/Presentasion_page/page/nav_section/leaderboard_page.dart';
import 'package:wasteapptest/Presentasion_page/page/nav_section/news_page.dart';
import 'package:wasteapptest/Domain_page/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4;
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _notificationsEnabled = false;
  bool _isCheckingNotificationStatus = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadSavedImage();
    _checkNotificationStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('userProfileImage');

    if (imagePath != null && imagePath.isNotEmpty) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        setState(() {
          _image = imageFile;
        });
      }
    }
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getFcmToken();
      setState(() {
        _notificationsEnabled = token != null;
        _isCheckingNotificationStatus = false;
      });
    } catch (e) {
      print('Error checking notification status: $e');
      setState(() {
        _notificationsEnabled = false;
        _isCheckingNotificationStatus = false;
      });
    }
  }

  Future<void> _toggleNotifications() async {
    try {
      setState(() => _isCheckingNotificationStatus = true);

      final notificationService = NotificationService();

      if (_notificationsEnabled) {
        // Disable notifications
        await notificationService.cleanupToken();
        setState(() => _notificationsEnabled = false);
        _showSuccessDialog(message: 'Notifikasi berhasil dinonaktifkan');
      } else {
        // Enable notifications
        await notificationService.initialize();
        final success = await notificationService.registerDeviceToken();
        if (success) {
          setState(() => _notificationsEnabled = true);
          _showSuccessDialog(message: 'Notifikasi berhasil diaktifkan');
        }
      }
    } catch (e) {
      _showErrorDialog('Gagal mengubah status notifikasi: $e');
    } finally {
      setState(() => _isCheckingNotificationStatus = false);
    }
  }

  Future<void> _getUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? '';

      if (userName.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://api-wasteapp.vercel.app/api/user/profile?name=$userName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = data;
          _nameController.text = data['name'] ?? userName;
          _emailController.text = data['email'] ?? '';
          _avatarUrl = data['avatarUrl']; // Store avatar URL
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Network error: ${e.toString()}');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentName = prefs.getString('userName') ?? '';

      // Check if there are any changes
      bool hasChanges = false;
      if (_nameController.text != currentName) hasChanges = true;
      if (_newEmailController.text.isNotEmpty && _newEmailController.text != _emailController.text) {
        hasChanges = true;
      }

      var uri = Uri.parse('https://api-wasteapp.vercel.app/api/user/profile');
      var request = http.MultipartRequest('PUT', uri);

      // Add text fields
      request.fields['currentName'] = currentName;
      request.fields['newName'] = _nameController.text;
      
      if (_newEmailController.text.isNotEmpty) {
        request.fields['newEmail'] = _newEmailController.text;
      }

      // Add image file if selected
      if (_image != null) {
        hasChanges = true;
        var stream = http.ByteStream(_image!.openRead());
        var length = await _image!.length();
        var multipartFile = http.MultipartFile(
          'avatar',
          stream,
          length,
          filename: 'avatar.jpg',
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        // Handle both update and no-changes scenarios
        final message = jsonResponse['message'];
        final updatedUser = jsonResponse['user'];

        // Update SharedPreferences only if name changed
        if (updatedUser['name'] != currentName) {
          await prefs.setString('userName', updatedUser['name']);
        }

        // Update email in SharedPreferences if changed
        if (updatedUser['email'] != _emailController.text) {
          await prefs.setString('userEmail', updatedUser['email']);
        }

        setState(() {
          userData = {
            ...userData,
            'name': updatedUser['name'],
            'email': updatedUser['email'],
            'avatarUrl': updatedUser['avatarUrl'],
          };
          _nameController.text = updatedUser['name'];
          _emailController.text = updatedUser['email'];
          _avatarUrl = updatedUser['avatarUrl'];
        });

        _newEmailController.clear();

        if (hasChanges) {
          _showSuccessDialog(message: message ?? 'Profile updated successfully');
        } else {
          _showSuccessDialog(message: message ?? 'No changes were needed');
        }
      } else {
        final error = jsonResponse['error'] ?? 'Failed to update profile';
        if (error.contains('Username already in use')) {
          _showErrorDialog('This username is already taken');
        } else if (error.contains('Email already in use')) {
          _showErrorDialog('This email is already registered');
        } else {
          _showErrorDialog(error);
        }
      }
    } catch (e) {
      _showErrorDialog('Error updating profile: $e');
    }
  }

  bool _validatePassword(String password) {
    // Check minimum length
    if (password.length < 8) return false;

    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;

    return true;
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('Password tidak boleh kosong');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Password tidak cocok');
      return;
    }

    if (!_validatePassword(_passwordController.text)) {
      _showErrorDialog(
        'Password harus mengandung:\n'
        '• Minimal 8 karakter\n'
        '• Huruf besar (A-Z)\n'
        '• Huruf kecil (a-z)\n'
        '• Angka (0-9)\n'
        '• Karakter khusus (!@#\$%^&*(),.?":{}|<>)'
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? '';

      if (userEmail.isEmpty) {
        _showErrorDialog('Email pengguna tidak ditemukan. Silakan login kembali.');
        return;
      }

      final response = await http.post(
        Uri.parse('https://api-wasteapp.vercel.app/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'newPassword': _passwordController.text,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _passwordController.clear();
        _confirmPasswordController.clear();

        _showSuccessDialog(message: responseData['message'] ?? 'Password berhasil diperbarui')
            .then((_) => Navigator.of(context).pop());
      } else {
        _showErrorDialog(responseData['error'] ?? 'Gagal mereset password');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  Future<void> _logout() async {
    try {
      final notificationService = NotificationService();
      await notificationService.cleanupToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      // Continue with logout even if token cleanup fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => isLoading = true);

        // Prepare the update request with the new image
        final imageFile = File(pickedFile.path);
        final prefs = await SharedPreferences.getInstance();
        final currentName = prefs.getString('userName') ?? '';

        var uri = Uri.parse('https://api-wasteapp.vercel.app/api/user/profile');
        var request = http.MultipartRequest('PUT', uri);

        // Add current user data
        request.fields['currentName'] = currentName;
        request.fields['newName'] = _nameController.text;

        // Add the image file
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'avatar',
          stream,
          length,
          filename: 'avatar.jpg',
        );
        request.files.add(multipartFile);

        // Send the request
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          final updatedUser = jsonResponse['user'];
          setState(() {
            _avatarUrl = updatedUser['avatarUrl'];
            userData = updatedUser;
          });
          _showSuccessDialog(message: 'Profile picture updated successfully');
        } else {
          _showErrorDialog(
              jsonResponse['error'] ?? 'Failed to update profile picture');
        }
      }
    } catch (e) {
      _showErrorDialog('Error updating profile picture: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showSuccessDialog({required String message}) async {
    return showDialog(
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
                const Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
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
                  'assets/images/ohno.png',
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
                const SizedBox(height: 40),
                const SizedBox(height: 20),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
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

  void _showLogoutDialog() {
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
                    'assets/images/logout.png',
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Logout Confirmation',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Kamu yakin ingin keluar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _logout();
                        },
                        child: const Text(
                          'Logout',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Current Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'New Email (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateProfile();
            },
            child:
                const Text('Save', style: TextStyle(color: Color(0xFF2cac69))),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Password harus mengandung:\n'
                '• Minimal 8 karakter\n'
                '• Huruf besar (A-Z)\n'
                '• Huruf kecil (a-z)\n'
                '• Angka (0-9)\n'
                '• Karakter khusus (!@#\$%^&*(),.?":{}|<>)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword();
            },
            child: const Text('Perbarui',
                style: TextStyle(color: Color(0xFF2cac69))),
          ),
        ],
      ),
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

  void _showImagePopup() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : const AssetImage('assets/images/profile.png')
                        as ImageProvider,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Close',
                  style: TextStyle(
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
        backgroundColor: const Color(0xFFFEFEFE),
        body: Stack(
          children: [
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2cac69)),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Row(
                            children: [
                              SizedBox(width: 8),
                              Text(
                                'Profile',
                                style: TextStyle(
                                  color: Color(0xFF2cac69),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showImagePopup,
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundImage: _avatarUrl != null
                                            ? NetworkImage(_avatarUrl!)
                                            : const AssetImage(
                                                    'assets/images/profile.png')
                                                as ImageProvider,
                                        child: isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: _pickImage,
                                          child: Container(
                                            height: 30,
                                            width: 30,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2cac69),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  userData['name'] ?? 'User Name',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _showEditProfileDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2cac69),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    minimumSize: const Size(150, 46),
                                  ),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Account Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2cac69),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.person,
                                      color: Color(0xFF2cac69)),
                                  title: const Text('Personal Data'),
                                  trailing: const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                  onTap: _showEditProfileDialog,
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.lock,
                                      color: Color(0xFF2cac69)),
                                  title: const Text('Update Password'),
                                  trailing: const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                  onTap: _showResetPasswordDialog,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Other Section
                          _buildOtherSection(),

                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'Version App v1.5.5',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                _showLogoutDialog, // Changed from _logout to _showLogoutDialog
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2cac69),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(),
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

  Widget _buildOtherSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2cac69),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications_active,
                color: Color(0xFF2cac69)),
            title: const Text('Notifikasi'),
            trailing: _isCheckingNotificationStatus
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2cac69)),
                    ),
                  )
                : Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) => _toggleNotifications(),
                    activeColor: const Color(0xFF2cac69),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF2cac69)),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
