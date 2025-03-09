import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  String? _motivationAnswer;
  String? _separationAnswer;
  String? _knowledgeAnswer;
  bool _isSubmitting = false;
  bool _hasCompletedSurvey = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkSurveyStatus();
  }

  Future<void> _checkSurveyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    final hasCompletedSurvey = prefs.getBool('hasCompletedSurvey') ?? false;

    setState(() {
      _userEmail = email;
      _hasCompletedSurvey = hasCompletedSurvey;
    });

    if (email != null && !hasCompletedSurvey) {
      try {
        final response = await http.get(
          Uri.parse('https://api-wasteapp.vercel.app/api/submit/check/survey/$email'),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['completed'] == true) {
            setState(() {
              _hasCompletedSurvey = true;
            });
            await prefs.setBool('hasCompletedSurvey', true);
          }
        }
      } catch (error) {
        print('Error checking survey status: $error');
      }
    }
  }

  Future<void> _submitSurvey() async {
    if (_userEmail == null) {
      _showErrorDialog('User email not found. Please login again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final requestBody = {
        'email': _userEmail,
        'answers': {
          'motivation': _motivationAnswer,
          'separation': _separationAnswer,
          'knowledge': _knowledgeAnswer,
        }
      };

      final response = await http.post(
        Uri.parse('https://api-wasteapp.vercel.app/api/submit/survey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasCompletedSurvey', true);
        
        setState(() {
          _hasCompletedSurvey = true;
        });
        
        await _showSuccessDialog();
      } else {
        final responseData = json.decode(response.body);
        _showErrorDialog(responseData['error'] ?? 'Gagal mengirim survei');
      }
    } catch (error) {
      _showErrorDialog('Network error. Silakan periksa koneksi Anda dan coba lagi.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
                  'Survey Submitted Successfully',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Thank you for your feedback!',
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

  Widget _buildCompletedSurveyCard() {
    return Center(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/svg/check-circle-svgrepo-com.svg',
                width: 60,
                height: 60,
                color: const Color(0xFF2cac69),
              ),
              const SizedBox(height: 20),
              const Text(
                'Survei Telah Diisi',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Terima kasih telah berpartisipasi dalam survei kami!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Kembali',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2cac69),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Survei',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Survei ini bertujuan untuk memahami motivasi pengguna dalam memisahkan sampah serta yang mendorong kebisaaan membuang sampah secara benar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _hasCompletedSurvey
                  ? _buildCompletedSurveyCard()
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question 1
                          const Text(
                            'Apakah anda memiliki niat yang kuat untuk membuang sampah pada tempatnya?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Radio buttons for question 1
                          RadioListTile<String>(
                            title: const Text('Sangat Setuju'),
                            value: 'Sangat Setuju',
                            groupValue: _motivationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _motivationAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Setuju'),
                            value: 'Setuju',
                            groupValue: _motivationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _motivationAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Tidak Setuju'),
                            value: 'Tidak Setuju',
                            groupValue: _motivationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _motivationAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Sangat tidak setuju'),
                            value: 'Sangat tidak setuju',
                            groupValue: _motivationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _motivationAnswer = value;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // Question 2
                          const Text(
                            'Seberapa sering anda membuang sampah pada tempat sampah yang telah ditentukan?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Radio buttons for question 2
                          RadioListTile<String>(
                            title: const Text('Selalu'),
                            value: 'Selalu',
                            groupValue: _separationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _separationAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Sering'),
                            value: 'Sering',
                            groupValue: _separationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _separationAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Jarang'),
                            value: 'Jarang',
                            groupValue: _separationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _separationAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Tidak pernah'),
                            value: 'Tidak pernah',
                            groupValue: _separationAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _separationAnswer = value;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // Question 3
                          const Text(
                            'Apakah menurut mulailkah perlu diberi hadiah akan kebiasaan membuang sampah secara benar?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Radio buttons for question 3
                          RadioListTile<String>(
                            title: const Text('Ya, sangat'),
                            value: 'Ya, sangat',
                            groupValue: _knowledgeAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _knowledgeAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Ya, cukup'),
                            value: 'Ya, cukup',
                            groupValue: _knowledgeAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _knowledgeAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Tidak cukup'),
                            value: 'Tidak cukup',
                            groupValue: _knowledgeAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _knowledgeAnswer = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Tidak perlu'),
                            value: 'Tidak perlu',
                            groupValue: _knowledgeAnswer,
                            activeColor: const Color(0xFF2cac69),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() {
                                _knowledgeAnswer = value;
                              });
                            },
                          ),

                          const SizedBox(height: 30),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_motivationAnswer != null &&
                                      _separationAnswer != null &&
                                      _knowledgeAnswer != null &&
                                      !_isSubmitting)
                                  ? _submitSurvey
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2cac69),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Submit Survey',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}