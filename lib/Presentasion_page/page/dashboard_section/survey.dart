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
  String? _q1Answer;
  String? _q2Answer;
  String? _q3Answer;
  String? _q4Answer;
  String? _q5Answer;
  String? _q6Answer;
  String? _q7Answer;
  String? _q8Answer;
  String? _q9Answer;
  String? _q10Answer;

  bool _isSubmitting = false;
  bool _hasCompletedSurvey = false;
  String? _userEmail;

  late Future<void> _surveyStatusFuture;

  @override
  void initState() {
    super.initState();
    _surveyStatusFuture = _checkSurveyStatus();
  }

  Future<void> _checkSurveyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    final hasCompletedSurvey = prefs.getBool('hasCompletedSurvey') ?? false;

    setState(() {
      _userEmail = email;
      _hasCompletedSurvey = hasCompletedSurvey;
    });

    if (email != null) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://api-wasteapp.vercel.app/api/submit/check/survey/$email'),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['completed'] == true) {
            setState(() {
              _hasCompletedSurvey = true;
            });
            await prefs.setBool('hasCompletedSurvey', true);
          } else {
            setState(() {
              _hasCompletedSurvey = false;
            });
            await prefs.setBool('hasCompletedSurvey', false);
          }
        }
      } catch (error) {
        // Handle error silently
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
          'q1_responsibility': _q1Answer,
          'q2_disposal_location': _q2Answer,
          'q3_waste_separation_difficulty': _q3Answer,
          'q4_waste_separation_importance': _q4Answer,
          'q5_comfortable_with_separated_bins': _q5Answer,
          'q6_app_understanding_help': _q6Answer,
          'q7_technology_ease': _q7Answer,
          'q8_incentive_motivation': _q8Answer,
          'q9_progress_tracking': _q9Answer,
          'q10_environmental_impact': _q10Answer,
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
      _showErrorDialog(
          'Network error. Silakan periksa koneksi Anda dan coba lagi.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Method to create radio list tiles
  List<RadioListTile<String>> _buildRadioListTiles(String? groupValue,
      List<String> options, void Function(String?)? onChanged) {
    return options
        .map((option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: groupValue,
              activeColor: const Color(0xFF2cac69),
              contentPadding: EdgeInsets.zero,
              onChanged: onChanged,
            ))
        .toList();
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
        color: Colors.white,
        elevation: 0, // Set to 0 since we're using custom BoxShadow
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkSurveyStatus();
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
              'Survei ini bertujuan untuk memahami perilaku dan persepsi pengguna dalam pengelolaan sampah',
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
              child: FutureBuilder<void>(
                future: _surveyStatusFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2cac69),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Terjadi kesalahan: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    );
                  } else {
                    return _hasCompletedSurvey
                        ? _buildCompletedSurveyCard()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question 1
                                const Text(
                                  '1. Apakah anda memiliki rasa tanggung jawab untuk membuang sampah pada tempatnya?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q1Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q1Answer = value)),

                                // Question 2
                                const SizedBox(height: 24),
                                const Text(
                                  '2. Apakah anda sering membuang sampah pada tempat sampah yg telah disediakan?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q2Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q2Answer = value)),

                                // Question 3
                                const SizedBox(height: 24),
                                const Text(
                                  '3. Apakah anda merasa kesulitan dalam membedakan sampah organik dan anorganik?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q3Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q3Answer = value)),

                                // Question 4
                                const SizedBox(height: 24),
                                const Text(
                                  '4. Apakah anda merasa penting untuk memisahkan sampah organik dan anorganik sebelum membuangnya?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q4Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q4Answer = value)),

                                // Question 5
                                const SizedBox(height: 24),
                                const Text(
                                  '5. Apakah anda merasa lebih nyaman membuang sampah jika tersedia tempat sampah untuk sampah organik dan anorganik?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q5Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q5Answer = value)),

                                // Question 6
                                const SizedBox(height: 24),
                                const Text(
                                  '6. Apakah aplikasi membantu pengguna dalam memahami jenis sampah organik dan anorganik?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q6Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q6Answer = value)),

                                // Question 7
                                const SizedBox(height: 24),
                                const Text(
                                  '7. Apakah anda akan lebih rajin memilah sampah organik dan anorganik jika ada teknologi dan alat yg memudahkan prosesnya?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q7Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q7Answer = value)),

                                // Question 8
                                const SizedBox(height: 24),
                                const Text(
                                  '8. Apakah insentif (misalnya poin yang dapat ditukar dengan uang) akan meningkatkan motivasi anda dalam membuang sampah dengan benar?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q8Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q8Answer = value)),

                                // Question 9
                                const SizedBox(height: 24),
                                const Text(
                                  '9. Apakah anda akan lebih semangat dalam memilah sampah jika terdapat laporan progress dalam aplikasi?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q9Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q9Answer = value)),

                                // Question 10
                                const SizedBox(height: 24),
                                const Text(
                                  '10. Apakah anda percaya bahwa memilah sampah organik dan anorganik dapat memberikan dampak positif bagi lingkungan?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildRadioListTiles(
                                    _q10Answer,
                                    [
                                      'Sangat Setuju',
                                      'Setuju',
                                      'Tidak Setuju',
                                      'Sangat Tidak Setuju'
                                    ],
                                    (value) =>
                                        setState(() => _q10Answer = value)),

                                const SizedBox(height: 30),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: (_q1Answer != null &&
                                            _q2Answer != null &&
                                            _q3Answer != null &&
                                            _q4Answer != null &&
                                            _q5Answer != null &&
                                            _q6Answer != null &&
                                            _q7Answer != null &&
                                            _q8Answer != null &&
                                            _q9Answer != null &&
                                            _q10Answer != null &&
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
                          );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
