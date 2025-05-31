import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class WasteBinStatus extends StatefulWidget {
  const WasteBinStatus({super.key});

  @override
  State<WasteBinStatus> createState() => _WasteBinStatusState();
}

class _WasteBinStatusState extends State<WasteBinStatus> {
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;

  // Sensor data
  double organicDistance = 0;
  double inorganicDistance = 0;
  double humidity = 0;
  double temperature = 0;
  double airQuality = 0;
  bool isConnected = false;
  bool _hasShownConnectedPopup = false;
  bool _isConnecting = false;
  String _connectionError = '';

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    if (!mounted) return;
    
    setState(() {
      _isConnecting = true;
      _connectionError = '';
    });
    
    try {
      await _connectWebSocket();
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionError = 'Gagal menghubungkan: $e';
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      // Dispose existing connection if any
      await _disposeConnection();
      
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.1.19:81'),
      );

      // Add timeout for connection
      _streamSubscription = _channel!.stream.timeout(
        const Duration(seconds: 10),
        onTimeout: (sink) {
          if (mounted) {
            setState(() {
              _connectionError = 'Koneksi timeout';
              isConnected = false;
              _isConnecting = false;
            });
            _showConnectionStatus(false);
          }
          sink.close();
        },
      ).listen(
        (message) {
          if (!mounted) return;
          
          try {
            final data = jsonDecode(message);
            setState(() {
              organicDistance = (data['organicDistance'] ?? 0).toDouble();
              inorganicDistance = (data['inorganicDistance'] ?? 0).toDouble();
              humidity = (data['humidity'] ?? 0).toDouble();
              temperature = (data['temperature'] ?? 0).toDouble();
              airQuality = (data['airQuality'] ?? 0).toDouble();
              isConnected = true;
              _isConnecting = false;
              _connectionError = '';
            });

            // Show success popup only once when first connected
            if (!_hasShownConnectedPopup && mounted) {
              _showConnectionStatus(true);
              _hasShownConnectedPopup = true;
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
            if (mounted) {
              setState(() {
                _connectionError = 'Error parsing data: $e';
              });
            }
          }
        },
        onError: (error) {
          if (!mounted) return;
          
          setState(() {
            isConnected = false;
            _isConnecting = false;
            _connectionError = 'WebSocket error: $error';
          });
          _showConnectionStatus(false);
          print('WebSocket error: $error');
        },
        onDone: () {
          if (!mounted) return;
          
          setState(() {
            isConnected = false;
            _isConnecting = false;
          });
          if (!_hasShownConnectedPopup) {
            _showConnectionStatus(false);
          }
          print('WebSocket connection closed');
        },
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          _isConnecting = false;
          _connectionError = 'Connection failed: $e';
        });
        _showConnectionStatus(false);
      }
      print('WebSocket connection error: $e');
    }
  }

  Future<void> _disposeConnection() async {
    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      await _channel?.sink.close();
      _channel = null;
    } catch (e) {
      print('Error disposing connection: $e');
    }
  }

  void _showConnectionStatus(bool connected) {
    // Check if context is still valid and widget is mounted
    if (!mounted || !context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connected ? Icons.check_circle : Icons.error,
                size: 80,
                color: connected ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                connected ? 'Terhubung!' : 'Koneksi Terputus',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                connected
                    ? 'Berhasil terhubung ke IoT device'
                    : _connectionError.isNotEmpty 
                        ? _connectionError 
                        : 'Gagal terhubung ke IoT device',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!connected)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _initializeConnection();
                      },
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(
                          color: Color(0xFF2cac69),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      connected ? 'OK' : 'Tutup',
                      style: const TextStyle(
                        color: Color(0xFF2cac69),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2cac69),
        elevation: 0,
        title: const Text(
          'Status Tempat Sampah',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.white : Colors.red,
            ),
            onPressed: _isConnecting ? null : _initializeConnection,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildContent(),
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2cac69)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Menghubungkan ke IoT Device...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_connectionError.isNotEmpty && !isConnected && !_isConnecting) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _initializeConnection,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOrganicWasteBin(),
            const SizedBox(height: 20),
            _buildInorganicWasteBin(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak dapat terhubung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _connectionError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2cac69),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganicWasteBin() {
    final fillPercentage = organicDistance > 0 ? 
        (1 - (organicDistance / 100)).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.delete_outline, color: Color(0xFF2cac69)),
                SizedBox(width: 8),
                Text(
                  'Tempat Sampah Organik',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSensorCard(
              'Kapasitas',
              fillPercentage * 100,
              Icons.storage,
              Colors.blue,
              suffix: '%',
              description: _getCapacityDescription(fillPercentage),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _getCapacityDescription(double fillPercentage) {
    if (fillPercentage < 0.5) return 'Tersedia';
    if (fillPercentage < 0.8) return 'Hampir Penuh';
    return 'Penuh';
  }

  Widget _buildInorganicWasteBin() {
    final fillPercentage = inorganicDistance > 0 ? 
        (1 - (inorganicDistance / 100)).clamp(0.0, 1.0) : 0.0;
    final odorLevel = airQuality > 0 ? 
        (airQuality / 1000).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tempat Sampah Anorganik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSensorCard(
              'Kapasitas',
              fillPercentage * 100,
              Icons.storage,
              Colors.blue,
              suffix: '%',
              description: _getCapacityDescription(fillPercentage),
            ),
            const SizedBox(height: 12),
            _buildSensorCard(
              'Kelembapan',
              humidity.isFinite ? humidity : 0.0,
              Icons.water_drop,
              Colors.cyan,
              suffix: '%',
            ),
            const SizedBox(height: 12),
            _buildSensorCard(
              'Tingkat Kebusukan',
              odorLevel * 100,
              Icons.science_outlined,
              Colors.red,
              suffix: '%',
              description: _getOdorDescription(odorLevel),
            ),
            const SizedBox(height: 20),
            _buildHistoryGraph(),
          ],
        ),
      ),
    );
  }

  String _getOdorDescription(double odorLevel) {
    if (odorLevel < 0.3) return 'Normal';
    if (odorLevel < 0.6) return 'Mulai Membusuk';
    if (odorLevel < 0.8) return 'Pembusukan Tinggi';
    return 'Sangat Busuk';
  }

  Widget _buildSensorCard(
    String title,
    double value,
    IconData icon,
    Color color, {
    String suffix = '',
    String? description,
  }) {
    // Ensure value is finite
    final safeValue = value.isFinite ? value : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearPercentIndicator(
                      percent: (safeValue / 100).clamp(0.0, 1.0),
                      lineHeight: 8,
                      animation: true,
                      progressColor: color,
                      backgroundColor: Colors.grey[200],
                      barRadius: const Radius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${safeValue.toStringAsFixed(1)}$suffix',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryGraph() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(2.6, 2),
                FlSpot(4.9, 5),
                FlSpot(6.8, 3.1),
                FlSpot(8, 4),
                FlSpot(9.5, 3),
                FlSpot(11, 4),
              ],
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.5),
                  Colors.blue,
                ],
              ),
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeConnection();
    super.dispose();
  }
}