import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wasteapptest/Dasboard_Page/dashboard.dart';
import 'package:wasteapptest/Signup_page/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> getLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

Future<void> _signin() async {
  setState(() {
    _isLoading = true;
  });

  final String name = _usernameController.text.trim();
  final String password = _passwordController.text.trim();

  if (name.isEmpty || password.isEmpty) {
    setState(() {
      _isLoading = false;
    });
    _showNoInputDialog();
    return;
  }

  final Uri url = Uri.parse('https://api-wasteapp.vercel.app/api/auth/signin');

  try {
    final http.Response response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'password': password}),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
    
      await prefs.setBool('isLoggedIn', true);
      if (responseData['email'] != null) {
        await prefs.setString('userEmail', responseData['email']);
      } else {
        await prefs.setString('userEmail', name);
      }
      
      await _showSuccessDialog();
    } else {
      final responseBody = json.decode(response.body);
      _showErrorDialog(responseBody['error'] ?? 'SignIn gagal');
    }
  } catch (error) {
    _showErrorDialog('Network error. Please check your connection and try again.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showNoInputDialog() {
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
                  'Data Belum Diisi',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Anda belum menginputkan data apa pun. Silakan isi data Anda terlebih dahulu.',
                  style: TextStyle(
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
                    'OK',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFF9800),
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

  Future<void> _showSuccessDialog() async {
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
                'SignIn Success',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kamu berhasil login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushReplacement( 
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2cac69),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 280,
                          height: 280,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Column(
                        children: [
                          Text(
                            'Hey there,',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              color: Color(0xFF2cac69),
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Color(0xFF2cac69)),
                          hintStyle: const TextStyle(fontFamily: 'Poppins'),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFF2cac69)),
                          hintStyle: const TextStyle(fontFamily: 'Poppins'),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2cac69),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum punya akun?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupScreen()),
                                );
                              },
                              child: const Text(
                                'Daftar',
                                style: TextStyle(
                                  color: Color(0xFF2cac69),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
