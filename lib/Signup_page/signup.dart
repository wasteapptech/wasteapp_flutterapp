import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Show success dialog with SVG
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Pendaftaran Berhasil',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/svg/success-svgrepo-com.svg', 
              width: 50,
              height: 50,
            ),
            const SizedBox(height: 20),
            const Text(
              'Akun Anda berhasil terdaftar.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); 
            },
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF0B894B),
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show error dialog with SVG
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Terjadi Kesalahan',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/svg/error-svgrepo-com.svg', 
              width: 50,
              height: 50,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); 
            },
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF0B894B),
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show user already registered dialog
  void _showUserAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'User Sudah Terdaftar',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/svg/error-svgrepo-com.svg', 
              width: 50,
              height: 50,
            ),
            const SizedBox(height: 20),
            const Text(
              'User ini sudah terdaftar sebelumnya.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close the dialog
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF0B894B),
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    final String apiUrl = 'https://api-wasteapp.vercel.app/api/auth/signup';
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    final Map<String, dynamic> body = {
      'email': _emailController.text,
      'name': _usernameController.text,
      'password': _passwordController.text,
    };

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Success - show success dialog
        _showSuccessDialog();
      } else if (response.statusCode == 400 && responseData['error'] == 'User ini sudah terdaftar') {
        // User already registered - show specific error dialog
        _showUserAlreadyRegisteredDialog();
      } else {
        // Other failure - show generic error dialog
        _showErrorDialog(responseData['error'] ?? 'Signup gagal');
      }
    } catch (error) {
      // Handle any errors that occur during the HTTP request
      _showErrorDialog('Terjadi kesalahan, coba lagi');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B894B),
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
                          'assets/images/logo1.png',
                          width: 150,
                          height: 150,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    // Email field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Username field
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Nama Pengguna',
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Kata Sandi',
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B894B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
