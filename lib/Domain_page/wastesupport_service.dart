import 'package:flutter/material.dart';
import 'package:flutter_tawk_to_chat/flutter_tawk_to_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TawkChatPage extends StatefulWidget {
  const TawkChatPage({super.key});

  @override
  State<TawkChatPage> createState() => _TawkChatPageState();
}

class _TawkChatPageState extends State<TawkChatPage> {
  TawkController? _controller;
  String _userName = 'Pengguna';
  String _userEmail = 'user@example.com';
  bool _isLoading = true;
  bool _hasError = false;
  bool _tawkLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? 'Pengguna';
        _userEmail = prefs.getString('userEmail') ?? 'user@example.com';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2cac69),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _controller == null || !_tawkLoaded
                ? null
                : () async {
                    if (await _controller!.isChatOngoing()) {
                      bool? confirm = await showAlert();
                      if (confirm == true) {
                        _controller!.endChat();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tidak ada chat yang berlangsung'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: _buildChatContent(),
    );
  }

  Widget _buildChatContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Gagal memuat data pengguna'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryLoading,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Tawk(
          directChatLink: 'https://tawk.to/chat/67ed0b6f6a958f190fb7e41a/1inqv9b4n',
          visitor: TawkVisitor(
            name: _userName,
            email: _userEmail,
          ),
          onLoad: () {
            debugPrint('Tawk.to loaded');
            setState(() {
              _tawkLoaded = true;
            });
          },
          onLinkTap: (String url) {
            debugPrint('Link tapped: $url');
          },
          placeholder: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                Text('Memuat layanan pelanggan...'),
              ],
            ),
          ),
          onControllerChanged: (value) {
            setState(() {
              _controller = value;
            });
          },
        ),
        if (!_tawkLoaded)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2cac69),
            ),
          ),
      ],
    );
  }

  Future<void> _retryLoading() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _tawkLoaded = false;
    });
    await _loadUserData();
  }

  Future<bool?> showAlert() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Akhiri Chat'),
          content: const Text('Anda yakin ingin mengakhiri chat?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey,
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.purple,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Akhiri'),
            ),
          ],
        );
      },
    );
  }
}