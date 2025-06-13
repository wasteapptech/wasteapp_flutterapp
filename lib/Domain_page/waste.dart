import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

    class WasteData {
    final String deviceId;
    final int timestamp;
    final double temperature;
    final double humidity;
    final int mq4Value;
    final int distance1;
    final int distance2;
    final int uptime;

    WasteData({
        required this.deviceId,
        required this.timestamp,
        required this.temperature,
        required this.humidity,
        required this.mq4Value,
        required this.distance1,
        required this.distance2,
        required this.uptime,
    });

    factory WasteData.fromJson(Map<String, dynamic> json) {
        return WasteData(
        deviceId: json['device_id'],
        timestamp: json['timestamp'],
        temperature: json['temperature']?.toDouble() ?? 0.0,
        humidity: json['humidity']?.toDouble() ?? 0.0,
        mq4Value: json['mq4_value'] ?? 0,
        distance1: json['distance1'] ?? 0,
        distance2: json['distance2'] ?? 0,
        uptime: json['uptime'] ?? 0,
        );
    }
    }

    double calculateFillLevel(int distance) {
    const maxHeight = 45;

    if (distance >= maxHeight) return 0.0;
    if (distance <= 0) return 1.0;

    return (maxHeight - distance) / maxHeight;
    }

    String getFillStatus(double fillLevel) {
    if (fillLevel >= 1.0) return 'PENUH';
    if (fillLevel >= 0.625) return 'HAMPIR PENUH';
    return 'TERSEDIA';
    }

    Color getFillColor(double fillLevel) {
    if (fillLevel >= 1.0) return Colors.red;
    if (fillLevel >= 0.625) return Colors.orange;
    return const Color(0xFF2cac69);
    }

    String formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    parts.add('${remainingSeconds}s');

    return parts.join(' ');
    }

    class WasteBinStatus extends StatefulWidget {
    const WasteBinStatus({super.key});

    @override
    _WasteBinStatusState createState() => _WasteBinStatusState();
    }

    class _WasteBinStatusState extends State<WasteBinStatus> {
    WasteData? _wasteData;
    late MqttServerClient client;
    bool isConnected = false;
    final List<FlSpot> temperatureData = [];
    final List<FlSpot> humidityData = [];
    final List<FlSpot> gasData = [];
    final int maxDataPoints = 20;
    final List<DateTime> timestamps = [];
    bool _mounted = true;

    @override
    void initState() {
        super.initState();
        _mounted = true;
        setupMqttClient();
    }

    Future<void> setupMqttClient() async {
        if (!_mounted) return;

        client = MqttServerClient('broker.hivemq.com',
            'flutter_client${DateTime.now().millisecondsSinceEpoch}');
        client.port = 1883;
        client.keepAlivePeriod = 60;
        client.onConnected = onConnected;
        client.onDisconnected = onDisconnected;

        try {
        await client.connect();
        if (_mounted) {
            subscribeToTopics();
        }
        } catch (e) {
        print('Exception: $e');
        if (_mounted) {
            client.disconnect();
        }
        }
    }

    void subscribeToTopics() {
        client.subscribe('waste/+/sensor_data', MqttQos.atLeastOnce);
        client.subscribe('waste/+/status', MqttQos.atLeastOnce);

        client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final String payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);

        updateData(payload);
        });
    }

    void updateData(String payload) {
        if (!_mounted) return;


        try {
        final data = json.decode(payload);
        if (!_mounted) return;

        setState(() {
            _wasteData = WasteData.fromJson(data);
            isConnected = true;
            
            final now = DateTime.now();
            timestamps.add(now);

            if (timestamps.length > maxDataPoints) {
            timestamps.removeAt(0);
            temperatureData.removeAt(0);
            humidityData.removeAt(0);
            gasData.removeAt(0);
            }

            final xValue = now.millisecondsSinceEpoch.toDouble();
            temperatureData.add(FlSpot(xValue, _wasteData!.temperature));
            humidityData.add(FlSpot(xValue, _wasteData!.humidity));
            gasData.add(FlSpot(xValue, _wasteData!.mq4Value.toDouble()));
        });
        } catch (e) {
        print('Error parsing data: $e');
        }
    }

    void onConnected() {
        if (!_mounted) return;
        setState(() => isConnected = true);
    }

    void onDisconnected() {
        if (!_mounted) return;
        setState(() => isConnected = false);
    }

    Widget _buildStatusCard() {
        return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                const Color(0xFF2cac69).withOpacity(0.9),
                const Color(0xFF2cac69).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
                BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
                ),
            ],
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                children: [
                    Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.insights,
                        color: Colors.white,
                        size: 24,
                    ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                    'Device Status',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                    ),
                    ),
                ],
                ),
                const SizedBox(height: 20),
                _buildStatusRow(
                Icons.power_settings_new,
                'Connection',
                isConnected ? 'Connected' : 'Disconnected',
                isConnected ? Colors.white : Colors.red.shade200,
                ),
                _buildStatusRow(
                Icons.device_thermostat,
                'Device ID',
                _wasteData?.deviceId ?? 'N/A',
                Colors.white,
                ),
                _buildStatusRow(
                Icons.timer_outlined,
                'Uptime',
                formatUptime(_wasteData?.uptime ?? 0),
                Colors.white,
                ),
            ],
            ),
        ),
        );
    }

    Widget _buildStatusRow(
        IconData icon, String title, String value, Color valueColor) {
        return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
            children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
            const SizedBox(width: 15),
            Text(
                title,
                style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                ),
            ),
            const Spacer(),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                value,
                style: TextStyle(
                    color: valueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                ),
                ),
            ),
            ],
        ),
        );
    }

    Widget _buildWasteBinCard(String title, double fillLevel,
        {Map<String, dynamic>? additionalInfo}) {
        final statusText = getFillStatus(fillLevel);
        final progressColor = getFillColor(fillLevel);
        final percentage = (fillLevel * 100).toStringAsFixed(1);

        return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
                BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
                ),
            ],
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                children: [
                    Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        Icons.delete_outline,
                        color: progressColor,
                        size: 28,
                    ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                    title,
                    style: TextStyle(
                        fontSize: 20,
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                ],
                ),
                const SizedBox(height: 8),
                Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                ),
                decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    statusText,
                    style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    ),
                ),
                ),
                const SizedBox(height: 25),
                Stack(
                children: [
                    Container(
                    height: 16,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                    ),
                    ),
                    FractionallySizedBox(
                    widthFactor: fillLevel,
                    child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                            colors: [
                            progressColor,
                            progressColor.withOpacity(0.7),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                        ),
                        ),
                    ),
                    ),
                ],
                ),
                const SizedBox(height: 10),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text(
                    'Kapasitas',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                    ),
                    ),
                    Row(
                    children: [
                        Text(
                        '$percentage%',
                        style: TextStyle(
                            color: progressColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                        ),
                        ),
                        const SizedBox(width: 4),
                    ],
                    ),
                ],
                ),
                if (additionalInfo != null) ...[
                const SizedBox(height: 25),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: additionalInfo.entries
                        .map((e) => _buildInfoItem(
                            e.key,
                            e.value['value'],
                            e.value['icon'],
                            e.value['unit'],
                            ))
                        .toList(),
                ),
                ],
            ],
            ),
        ),
        );
    }

    Widget _buildInfoItem(
        String label, dynamic value, IconData icon, String unit) {
        return Column(
        children: [
            Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF2cac69).withOpacity(0.1),
                shape: BoxShape.circle,
            ),
            child: Icon(
                icon,
                color: const Color(0xFF2cac69),
                size: 24,
            ),
            ),
            const SizedBox(height: 8),
            Text(
            '$value$unit',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF2cac69),
            ),
            ),
            const SizedBox(height: 4),
            Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
            ),
            ),
        ],
        );
    }

    Widget _buildLineChart() {
        if (temperatureData.isEmpty) {
        return Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text(
            'Waiting for data...',
            style: TextStyle(color: Colors.grey),
            ),
        );
        }

        // Calculate min and max Y values with some padding
        double minY = 0;
        double maxY = 100;

        // Adjust for gas data if it's higher than 100
        final maxGas = gasData.isNotEmpty
            ? gasData.map((e) => e.y).reduce((a, b) => a > b ? a : b)
            : 0;
        if (maxGas > maxY) {
        maxY = maxGas * 1.1; // Add 10% padding
        }

        return SizedBox(
        height: 200,
        child: LineChart(
            LineChartData(
                clipData:
                    const FlClipData.all(), // Ensure chart stays within bounds
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                        final date =
                            DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            DateFormat('HH:mm').format(date),
                            style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            ),
                        ),
                        );
                    },
                    reservedSize: 30,
                    ),
                ),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY > 100 ? (maxY / 5) : 20,
                    getTitlesWidget: (value, meta) {
                        return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                        ),
                        );
                    },
                    reservedSize: 40,
                    ),
                ),
                ),
                borderData: FlBorderData(show: false),
                minX: temperatureData.first.x,
                maxX: temperatureData.last.x,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                LineChartBarData(
                    spots: temperatureData,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                    show: true,
                    color: Colors.orange.withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                    spots: humidityData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                    spots: gasData,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.1),
                    ),
                    dotData: const FlDotData(show: false),
                ),
                ]),
        ),
        );
    }

    Widget _buildChartCard() {
        return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
                BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
                ),
            ],
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text(
                'Sensor Data History',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2cac69),
                ),
                ),
                const SizedBox(height: 15),
                const Text(
                'Temperature, Humidity & Gas Levels',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                ),
                ),
                const SizedBox(height: 20),
                _buildLineChart(),
                const SizedBox(height: 20),
                Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    _buildChartLegend(Colors.orange, 'Temperature (°C)'),
                    const SizedBox(width: 20),
                    _buildChartLegend(Colors.blue, 'Humidity (%)'),
                    const SizedBox(width: 20),
                    _buildChartLegend(Colors.red, 'Gas Level'),
                ],
                ),
            ],
            ),
        ),
        );
    }

    Widget _buildChartLegend(Color color, String text) {
        return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
            ),
            ),
            const SizedBox(width: 6),
            Text(
            text,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
            ),
            ),
        ],
        );
    }

    @override
    Widget build(BuildContext context) {
        double organicFillLevel =
            _wasteData != null ? calculateFillLevel(_wasteData!.distance1) : 0;
        double inorganicFillLevel =
            _wasteData != null ? calculateFillLevel(_wasteData!.distance2) : 0;

        return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
            backgroundColor: const Color(0xFF2cac69),
            elevation: 0,
            title: const Text(
            'Waste Bin Monitoring',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
            ),
            ),
            centerTitle: true,
            leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            ),
            shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
            ),
            ),
        ),
        body: RefreshIndicator(
            color: const Color(0xFF2cac69),
            backgroundColor: Colors.white,
            onRefresh: () async {
            await setupMqttClient();
            },
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
                children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildWasteBinCard(
                    'Tempat Sampah Oganik',
                    organicFillLevel,
                    additionalInfo: {
                    'Temperature': {
                        'value': _wasteData?.temperature ?? 0,
                        'unit': '°C',
                        'icon': Icons.thermostat,
                    },
                    'Humidity': {
                        'value': _wasteData?.humidity ?? 0,
                        'unit': '%',
                        'icon': Icons.water_drop,
                    },
                    'Gas': {
                        'value': _wasteData?.mq4Value ?? 0,
                        'unit': ' ppm',
                        'icon': Icons.air,
                    },
                    },
                ),
                const SizedBox(height: 16),
                _buildWasteBinCard(
                    'Tempat Sampah Anorganik',
                    inorganicFillLevel,
                ),
                const SizedBox(height: 16),
                _buildChartCard(),
                ],
            ),
            ),
        ),
        );
    }

    @override
    void dispose() {
        _mounted = false;
        client.disconnect();
        super.dispose();
    }
    }
