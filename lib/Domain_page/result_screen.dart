import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/transaction.dart';

class DetectionResult {
  final List<Detection> detections;
  final int imageHeight;
  final int imageWidth;
  final DateTime scanStartTime;
  final int totalProcessingTime;

  DetectionResult({
    required this.detections,
    required this.imageHeight,
    required this.imageWidth,
    required this.scanStartTime,
    required this.totalProcessingTime,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      detections: (json['detections'] as List)
          .map((detection) => Detection.fromJson(detection))
          .toList(),
      imageHeight: json['image_height'],
      imageWidth: json['image_width'],
      scanStartTime: DateTime.parse(json['scan_start_time']),
      totalProcessingTime: json['total_processing_time'],
    );
  }
}

class Detection {
  final BoundingBox bbox;
  final int classId;
  final String className;
  final double confidence;
  final int id;
  final String? originalClassName;
  final String? reason;

  Detection({
    required this.bbox,
    required this.classId,
    required this.className,
    required this.confidence,
    required this.id,
    this.originalClassName,
    this.reason,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      bbox: BoundingBox.fromJson(json['bbox']),
      classId: json['class_id'],
      className: json['class_name'],
      confidence: json['confidence'].toDouble(),
      id: json['id'],
      originalClassName: json['original_class_name'],
      reason: json['reason'],
    );
  }

  bool get isUnknown => className == 'unknown';
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
    final validDetections = result.detections.where((d) => !d.isUnknown).toList();
    final totalPrice = _calculateTotalPrice(validDetections);
    final unknownCount = result.detections.where((d) => d.isUnknown).length;

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
                    child: Column(
                      children: [
                        Text(
                          'Ditemukan ${validDetections.length} objek yang dapat ditabung',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (unknownCount > 0)
                          Text(
                            '($unknownCount objek tidak dikenali)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Image with bounding boxes (shows ALL detections)
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
                                detections: result.detections, // All detections
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

                  // Detection details (only shows known detections)
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
                        if (validDetections.isEmpty)
                          const Text(
                            'Tidak ada objek yang dapat ditabung',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ...validDetections.map((detection) =>
                            _buildDetectionCard(detection, result)),
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
                              'Total yang dapat ditabung',
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
                            if (validDetections.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tidak ada objek yang dapat ditabung'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionPage(
                                  detectedItems: validDetections
                                      .map((detection) => {
                                            'className': detection.className,
                                            'price': _prices?.getPriceForItem(
                                                    detection.className) ??
                                                0,
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
    final processingTimeStr = '${result.totalProcessingTime}ms';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
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
                    color: Colors.black,
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
                  'Processing Time: $processingTimeStr',
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
        ..color = detection.isUnknown
            ? Colors.black // Black for unknown detections
            : _getColorForClass(detection.classId)
        ..style = PaintingStyle.stroke
        ..strokeWidth = detection.isUnknown ? 2.0 : 3.0;
      if (detection.isUnknown) paint.strokeCap = StrokeCap.butt;

      final rect = Rect.fromLTWH(
        detection.bbox.x1 * scaleX,
        detection.bbox.y1 * scaleY,
        detection.bbox.width * scaleX,
        detection.bbox.height * scaleY,
      );

      canvas.drawRect(rect, paint);

      // Only draw labels for known detections
      if (!detection.isUnknown) {
        final labelText = '${detection.className} ${(detection.confidence * 100).toInt()}%';

        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
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

        textPainter.paint(
          canvas,
          Offset(
            detection.bbox.x1 * scaleX + 4,
            detection.bbox.y1 * scaleY - textPainter.height - 2,
          ),
        );
      }
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