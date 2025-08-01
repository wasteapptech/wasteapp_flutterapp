import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';
import 'package:wasteapptest/Domain_page/waste.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class TempatSampahPage extends StatefulWidget {
  const TempatSampahPage({super.key});

  @override
  State<TempatSampahPage> createState() => _TempatSampahPageState();
}

class _TempatSampahPageState extends State<TempatSampahPage> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final LatLng _initialCameraPosition =
      const LatLng(-6.9733, 107.6298); // Bandung center as default
  LatLng? _currentUserLocation;
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final String _openRouteServiceApiKey =
      '5b3ce3597851110001cf62489813e9e1ff0748c1a2c5f2232f31c216';
  BitmapDescriptor? _customMarkerIcon;
  BitmapDescriptor? _userLocationMarker;
  bool _isMapLoading = true;
  bool _isLocationLoading = false;
  int _mapLoadRetryCount = 0;
  final int _maxRetryAttempts = 3;
  Timer? _mapLoadingTimer;

  final List<Map<String, dynamic>> _wasteBinLocations = [
    {
      'name': 'Open Library',
      'location': const LatLng(-6.9717188811077895, 107.63241546931336),
      'status': 'Available', // Add status field
    },
    {
      'name': 'Tult',
      'location': const LatLng(-6.969079651231849, 107.62815699654476),
      'status': 'Available',
    },
    {
      'name': 'Gedung Rektorat',
      'location': const LatLng(-6.973997663997622, 107.63038396036787),
      'status': 'Available',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _loadUserData();
    // Start map loading timeout timer
    _mapLoadingTimer = Timer(const Duration(seconds: 10), () {
      if (_isMapLoading && mounted) {
        setState(() {
          _isMapLoading = false;
        });
        _handleMapLoadFailure('Timeout loading map');
      }
    });
  }

  @override
  void dispose() {
    _mapLoadingTimer?.cancel();
    _mapController?.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  // Handle map loading failures
  void _handleMapLoadFailure(String reason) {
    print('Map load failure: $reason');
    if (_mapLoadRetryCount < _maxRetryAttempts) {
      _mapLoadRetryCount++;
      showCustomPopup(
        context: context,
        message:
            'Mencoba memuat peta kembali... ($_mapLoadRetryCount/$_maxRetryAttempts)',
        backgroundColor: Colors.orange,
        icon: Icons.refresh,
      );

      // Force rebuild after short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isMapLoading = true;
          });
        }
      });
    } else {
      showCustomPopup(
        context: context,
        message: 'Gagal memuat peta. Coba restart aplikasi.',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _loadCustomMarker() async {
    try {
      final customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(35, 35)),
        'assets/images/marker.png',
      );

      if (mounted) {
        setState(() {
          _customMarkerIcon = customIcon;
        });
      }
    } catch (e) {
      print('Error loading custom marker: $e');
      // Fallback to default marker
      if (mounted) {
        setState(() {
          _customMarkerIcon = BitmapDescriptor.defaultMarker;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Pengguna';
    if (userName.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
              'https://api-wasteapp.vercel.app/api/user/profile?name=$userName'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final avatarUrl = data['avatarUrl'];
          if (avatarUrl != null) {
            await _createCustomUserMarker(avatarUrl);
          }
        }
      } catch (e) {
        print('Error fetching avatar: $e');
      }
    }
  }

  Future<void> _createCustomUserMarker(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 150,
        targetHeight: 150,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()..isAntiAlias = true;

      paint.color = Colors.white;
      canvas.drawCircle(const Offset(75, 75), 35, paint);

      paint.color = const Color(0xFF2cac69);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 8;
      canvas.drawCircle(const Offset(75, 75), 35, paint);

      final shader = await _createCircularShader(image);
      paint
        ..style = PaintingStyle.fill
        ..shader = shader;
      canvas.drawCircle(const Offset(75, 75), 30, paint);

      final markerImage =
          await pictureRecorder.endRecording().toImage(150, 150);
      final byteData =
          await markerImage.toByteData(format: ui.ImageByteFormat.png);
      final markerBytes = byteData!.buffer.asUint8List();

      if (mounted) {
        setState(() {
          _userLocationMarker = BitmapDescriptor.fromBytes(markerBytes);
        });
        _setupMarkers(); // Refresh markers
      }
    } catch (e) {
      print('Error creating custom marker: $e');
    }
  }

  Future<ui.Shader> _createCircularShader(ui.Image image) async {
    return ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );
  }

  void _setupMarkers() {
    if (_customMarkerIcon == null) return;

    final Set<Marker> newMarkers = {};

    for (final location in _wasteBinLocations) {
      final marker = Marker(
        markerId: MarkerId(location['name']),
        position: location['location'],
        infoWindow:
            InfoWindow(title: location['name'], snippet: location['status']),
        icon: _customMarkerIcon!,
      );

      newMarkers.add(marker);
    }

    if (_currentUserLocation != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: _currentUserLocation!,
        infoWindow: const InfoWindow(title: "My Location"),
        icon: _userLocationMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ));
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  Future<void> _getUserLocation() async {
    if (_isLocationLoading) return;

    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLocationLoading = false;
          });
          showCustomPopup(
            context: context,
            message: 'Layanan lokasi tidak diaktifkan',
            backgroundColor: Colors.orange,
            icon: Icons.location_off,
          );
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLocationLoading = false;
          });
          showCustomPopup(
            context: context,
            message: 'Izin lokasi ditolak',
            backgroundColor: Colors.orange,
            icon: Icons.location_disabled,
          );
          return;
        }
      }

      final locationData = await _location.getLocation();
      if (!mounted) return;

      setState(() {
        _currentUserLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _isLocationLoading = false;
      });

      _setupMarkers();

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentUserLocation!, 15),
        );

        showCustomPopup(
          context: context,
          message: 'Lokasi Anda ditemukan',
          backgroundColor: Colors.green,
          icon: Icons.location_on,
        );
      }
    } catch (e) {
      print("Error getting user location: $e");
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
        showCustomPopup(
          context: context,
          message: 'Gagal mendapatkan lokasi: ${e.toString()}',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _getDirections(LatLng destination) async {
    if (_currentUserLocation == null) {
      showCustomPopup(
        context: context,
        message: 'Lokasi pengguna belum tersedia',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );

      // Try to get user location first
      await _getUserLocation();

      // Check again
      if (_currentUserLocation == null) return;
    }

    try {
      setState(() {
        _polylines.clear();
      });

      showCustomPopup(
        context: context,
        message: 'Mencari rute terbaik...',
        backgroundColor: Colors.blue,
        icon: Icons.directions,
      );

      final directions = await _getRouteCoordinates(
        _currentUserLocation!,
        destination,
      );

      if (!mounted) return;

      if (directions != null &&
          directions['features'] != null &&
          directions['features'].isNotEmpty) {
        final coordinates =
            directions['features'][0]['geometry']['coordinates'];
        final List<LatLng> points = coordinates
            .map<LatLng>(
                (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.green,
              width: 5,
              points: List<LatLng>.from(points),
            ),
          );
        });

        if (_mapController != null && points.isNotEmpty) {
          LatLngBounds bounds = boundsFromLatLngList(points);
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }

        showCustomPopup(
          context: context,
          message: 'Rute ditemukan',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      } else {
        showCustomPopup(
          context: context,
          message: 'Tidak dapat menemukan rute',
          backgroundColor: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );
      }
    } catch (e) {
      print("Error getting directions: $e");
      showCustomPopup(
        context: context,
        message: 'Gagal mendapatkan rute: ${e.toString()}',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  void showCustomPopup({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.green,
    IconData icon = Icons.info_outline,
  }) {
    // Make sure we're in a valid context
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  Future<Map<String, dynamic>?> _getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/foot-walking?'
        'api_key=$_openRouteServiceApiKey&'
        'start=${origin.longitude},${origin.latitude}&'
        'end=${destination.longitude},${destination.latitude}',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept':
              'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
            'Error from OpenRouteService API: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network error getting directions: $e');
      return null;
    }
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;

    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }

    // Add padding
    final latPadding = (x1! - x0!) * 0.1;
    final lngPadding = (y1! - y0!) * 0.1;

    return LatLngBounds(
        northeast: LatLng(x1 + latPadding, y1 + lngPadding),
        southwest: LatLng(x0 - latPadding, y0 - lngPadding));
  }

  void _showRoute(String locationName) {
    final selectedLocation = _wasteBinLocations.firstWhere(
      (location) => location['name'] == locationName,
      orElse: () => _wasteBinLocations[0],
    );

    showCustomPopup(
      context: context,
      message: 'Menampilkan rute ke $locationName',
      backgroundColor: Colors.green,
      icon: Icons.route_outlined,
    );

    _getDirections(selectedLocation['location']);
  }

  void _showStatus(String locationName) {
    // Replace existing dialog with navigation to WasteBinStatus
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WasteBinStatus(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCameraPosition,
                zoom: 15,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // We'll add our own button
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                setState(() {
                  _mapController = controller;
                  _isMapLoading = false;
                  _mapLoadingTimer?.cancel();
                });

                print('Map controller initialized successfully');
                _setupMarkers();
                _getUserLocation();
              },
            ),

            // Loading overlay
            if (_isMapLoading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Memuat Peta...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      )
                    ],
                  ),
                ),
              ),

            // Location button
            Positioned(
              right: 16,
              bottom: 120,
              child: FloatingActionButton(
                onPressed: _getUserLocation,
                backgroundColor: Colors.white,
                mini: true,
                child: _isLocationLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.green),
              ),
            ),

            // Bottom sheet
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                return true;
              },
              child: DraggableScrollableSheet(
                controller: _draggableController,
                initialChildSize: 0.15,
                minChildSize: 0.15,
                maxChildSize: (() {
                  final count = _wasteBinLocations.length;
                  final estimated = 0.15 + (count * 0.10);
                  return estimated.clamp(0.15, 0.7);
                })(),
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                width: double.infinity,
                                child: const Text(
                                  'Tempat Sampah Terdekat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._wasteBinLocations.map((location) {
                              return _buildLocationItem(
                                  location['name'], location['status']);
                            }),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(String name, String? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Location Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Route Button
                  Expanded(
                    child: InkWell(
                      onTap: () => _showRoute(name),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rute',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey[300],
                  ),

                  // Status Button
                  Expanded(
                    child: InkWell(
                      onTap: () => _showStatus(name),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
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
          ],
        ),
      ),
    );
  }
}
