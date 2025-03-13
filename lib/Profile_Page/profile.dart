import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wasteapptest/Dasboard_Page/dashboard.dart';
import 'package:wasteapptest/Signin_Page/login.dart';
import 'package:wasteapptest/Support_Page/news_page.dart';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadSavedImage();
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

  Future<void> _saveImageToPrefs(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userProfileImage', path);
  }

  Future<void> _getUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? '';
      final userEmail = prefs.getString('userEmail') ?? '';

      if (userName.isEmpty) {
        setState(() {
          isLoading = false;
        });
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
          _emailController.text = data['email'] ??
              userEmail; // Pastikan email diambil dari API atau SharedPreferences
          isLoading = false;
        });
      } else {
        // Jika API gagal, gunakan data dari SharedPreferences
        setState(() {
          userData = {'name': userName, 'email': userEmail};
          _nameController.text = userName;
          _emailController.text =
              userEmail; // Pastikan email diambil dari SharedPreferences
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(
          'Network error. Please check your connection and try again.');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final response = await http.put(
        Uri.parse('https://api-wasteapp.vercel.app/api/user/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'name': _nameController.text,
          'newEmail': _newEmailController.text.isNotEmpty
              ? _newEmailController.text
              : null,
        }),
      );

      if (response.statusCode == 200) {
        if (_newEmailController.text.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', _newEmailController.text);
          _emailController.text = _newEmailController.text;
        }

        _newEmailController.clear();

        _showSuccessDialog(message: 'Profile updated successfully');
        await _getUserData();
      } else {
        _showErrorDialog('Failed to update profile');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail') ?? '';

      if (userEmail.isEmpty) {
        _showErrorDialog('User email not found. Please log in again.');
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

      if (response.statusCode == 200) {
        _passwordController.clear();
        _confirmPasswordController.clear();

        _showSuccessDialog(message: 'Password updated successfully').then((_) {
          Navigator.of(context).pop();
        });
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await _saveImageToPrefs(pickedFile.path);

      setState(() {
        _image = imageFile;
      });

      _showSuccessDialog(message: 'Profile picture updated');
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
                SvgPicture.asset(
                  'assets/svg/success-svgrepo-com.svg',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Success',
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Tutup dialog sukses
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
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _resetPassword,
            child: const Text('Update',
                style: TextStyle(color: Color(0xFF2cac69))),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
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
        // Tambahkan navigasi untuk halaman Scan
        break;
      case 3:
        // Tambahkan navigasi untuk halaman Statistics
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2cac69),
        title: const Text(
          'Profile',
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
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2cac69)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _image != null
                                    ? FileImage(_image!)
                                    : const AssetImage(
                                            'assets/images/TU-logogram.webp')
                                        as ImageProvider,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2cac69),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['name'] ??
                              'User Name', // Tampilkan nama dari userData
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userData['email'] ??
                              'Waste@example.com', // Tampilkan email dari userData
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Profile Sections
                        _buildSectionCard(
                          title: 'Personal Information',
                          icon: Icons.person,
                          onTap: _showEditProfileDialog,
                          subtitle: 'Edit your profile information',
                        ),

                        _buildSectionCard(
                          title: 'Security',
                          icon: Icons.security,
                          onTap: _showResetPasswordDialog,
                          subtitle: 'Change your password',
                        ),

                        _buildSectionCard(
                          title: 'About',
                          icon: Icons.info_outline,
                          onTap: () {
                            // Show app information
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('About WasteApp'),
                                content: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('WasteApp v1.0.0'),
                                    SizedBox(height: 8),
                                    Text(
                                        'A sustainable waste management solution'),
                                    SizedBox(height: 8),
                                    Text('© 2025 WasteApp Team'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          subtitle: 'Application information',
                        ),

                        _buildSectionCard(
                          title: 'Logout',
                          icon: Icons.logout,
                          onTap: _showLogoutConfirmationDialog,
                          subtitle: 'Sign out from your account',
                          isLogout: true,
                        ),

                        const SizedBox(
                            height: 100), // For bottom navigation bar space
                      ],
                    ),
                  ),
                ),

          // Bottom Navigation Bar
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required String subtitle,
    bool isLogout = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout ? Colors.red[50] : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : const Color(0xFF2cac69),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
