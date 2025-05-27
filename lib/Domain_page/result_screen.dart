import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/transaction.dart';

class DetectionResult {
  final List<Detection> detections;
  final int imageHeight;
  final int imageWidth;
  final double inferenceTime;  // Server-side inference time
  final DateTime clientStartTime; // Client-side total time

  DetectionResult({
    required this.detections,
    required this.imageHeight,
    required this.imageWidth,
    required this.inferenceTime,
    required this.clientStartTime,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      detections: (json['detections'] as List)
          .map((detection) => Detection.fromJson(detection))
          .toList(),
      imageHeight: json['image_height'],
      imageWidth: json['image_width'],
      inferenceTime: double.tryParse(json['inference_time']?.toString() ?? '0') ?? 0.0,
      clientStartTime: json['client_start_time'] != null 
          ? DateTime.parse(json['client_start_time'])
          : DateTime.now(),
    );
  }
}

class Detection {
  final BoundingBox bbox;
  final int classId;
  final String className;
  final double confidence;
  final int id;

  Detection({
    required this.bbox,
    required this.classId,
    required this.className,
    required this.confidence,
    required this.id,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      bbox: BoundingBox.fromJson(json['bbox']),
      classId: json['class_id'],
      className: json['class_name'],
      confidence: json['confidence'].toDouble(),
      id: json['id'],
    );
  }
}

class BoundingBox {
  final double height;
  final double width;
  final double x1;
  final double x2;
  final double y1;
  final double y2;

  BoundingBox({
    required this.height,
    required this.width,
    required this.x1,
    required this.x2,
    required this.y1,
    required this.y2,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      height: json['height'].toDouble(),
      width: json['width'].toDouble(),
      x1: json['x1'].toDouble(),
      x2: json['x2'].toDouble(),
      y1: json['y1'].toDouble(),
      y2: json['y2'].toDouble(),
    );
  }
}

class WastePrices {
  final Map<String, int> prices;

  WastePrices({required this.prices});

  int operator [](String itemName) {
    return prices[itemName.toLowerCase()] ?? 0;
  }

  factory WastePrices.fromJson(Map<String, dynamic> json) {
    Map<String, int> priceMap = {};
    json.forEach((key, value) {
      priceMap[key] = value as int;
    });
    return WastePrices(prices: priceMap);
  }

  int getPriceForItem(String itemName) {
    return prices[itemName.toLowerCase()] ?? 0;
  }
}

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> detectionResult;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.detectionResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  WastePrices? _prices;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final response = await http
          .get(Uri.parse('https://api-wasteapp.vercel.app/api/harga'));

      if (response.statusCode == 200) {
        setState(() {
          _prices = WastePrices.fromJson(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        print('Failed to load prices: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching prices: $e');
      setState(() => _isLoading = false);
    }
  }

  int _calculateTotalPrice(List<Detection> detections) {
    if (_prices == null) return 0;
    return detections.fold(0, (total, detection) {
      return total + _prices!.getPriceForItem(detection.className);
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = DetectionResult.fromJson(widget.detectionResult);
    final totalPrice = _calculateTotalPrice(result.detections);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Hasil Deteksi Sampah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with detection count
                  Container(
                    width: double.infinity,
                    color: Colors.green,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Center(
                      child: Text(
                        'Ditemukan ${result.detections.length} objek sampah',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Image with bounding boxes
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BoundingBoxPainter(
                                detections: result.detections,
                                imageWidth: result.imageWidth,
                                imageHeight: result.imageHeight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detection details
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Deteksi:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...result.detections
                            .map((detection) => _buildDetectionCard(detection, result)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Summary
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.recycling,
                                color: Colors.green, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Rp.$totalPrice',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionPage(
                                  detectedItems: result.detections
                                      .map((detection) => {
                                            'className': detection.className,
                                            'price': _prices?.getPriceForItem(detection.className) ?? 0,
                                          })
                                      .toList(),
                                  totalAmount: totalPrice,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Tabung',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildDetectionCard(Detection detection, DetectionResult result) {
    final itemPrice = _prices?.getPriceForItem(detection.className) ?? 0;
    final endTime = DateTime.now();
    final totalProcessingTime = endTime.difference(result.clientStartTime).inMilliseconds;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorForClass(detection.classId),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection.className,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Server Processing: ${result.inferenceTime.toStringAsFixed(1)}ms',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Total Time: ${totalProcessingTime}ms',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '1 pcs • Rp.$itemPrice',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForClass(int classId) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[classId % colors.length];
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;

  BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (var detection in detections) {
      final paint = Paint()
        ..color = _getColorForClass(detection.classId)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final rect = Rect.fromLTWH(
        detection.bbox.x1 * scaleX,
        detection.bbox.y1 * scaleY,
        detection.bbox.width * scaleX,
        detection.bbox.height * scaleY,
      );

      canvas.drawRect(rect, paint);

      // Draw label background
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '${detection.className} ${(detection.confidence * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        detection.bbox.x1 * scaleX,
        detection.bbox.y1 * scaleY - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(
        labelRect,
        Paint()..color = _getColorForClass(detection.classId),
      );

      // Draw text
      textPainter.paint(
        canvas,
        Offset(
          detection.bbox.x1 * scaleX + 4,
          detection.bbox.y1 * scaleY - textPainter.height - 2,
        ),
      );
    }
  }

  Color _getColorForClass(int classId) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[classId % colors.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
