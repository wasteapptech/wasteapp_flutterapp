import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TempatSampahPage extends StatefulWidget {
  const TempatSampahPage({super.key});

  @override
  State<TempatSampahPage> createState() => _TempatSampahPageState();
}

class _TempatSampahPageState extends State<TempatSampahPage> {
  late GoogleMapController _mapController;
  final Location _location = Location();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng _initialCameraPosition =
      const LatLng(-6.9733, 107.6298); // Bandung center as default
  LatLng? _currentUserLocation;
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final String _openRouteServiceApiKey =
      '5b3ce3597851110001cf62489813e9e1ff0748c1a2c5f2232f31c216';
  BitmapDescriptor? _customMarkerIcon;

  final List<Map<String, dynamic>> _wasteBinLocations = [
    {
      'name': 'Open Library',
      'location': const LatLng(-6.9717188811077895, 107.63241546931336),
      'status': 'Available',
    },
    {
      'name': 'Tult',
      'location': const LatLng(-6.969079651231849, 107.62815699654476),
      'status': 'Available',
    },
    {
      'name': 'Gedung Rektorat',
      'location': const LatLng(-6.973997663997622, 107.63038396036787),
      'status': 'Almost Full',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _getUserLocation();
    _loadCustomMarker();
  }

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    final customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(35, 35)),
      'assets/images/marker.png',
    );

    setState(() {
      _customMarkerIcon = customIcon;
      _setupMarkers();
    });
  }

  void _setupMarkers() {
    if (_customMarkerIcon == null) return;

    for (final location in _wasteBinLocations) {
      final marker = Marker(
        markerId: MarkerId(location['name']),
        position: location['location'],
        infoWindow:
            InfoWindow(title: location['name'], snippet: location['status']),
        icon: _customMarkerIcon!,
      );

      _markers.add(marker);
    }

    if (_currentUserLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: _currentUserLocation!,
        infoWindow: const InfoWindow(title: "Your Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ));
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _initialCameraPosition =
              LatLng(locationData.latitude!, locationData.longitude!);
          _currentUserLocation = _initialCameraPosition;

          _markers.add(Marker(
            markerId: const MarkerId("currentLocation"),
            position: _initialCameraPosition,
            infoWindow: const InfoWindow(title: "Your Location"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ));
        });

        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_initialCameraPosition, 15),
        );
      }
    } catch (e) {
      print("Error getting user location: $e");
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
      return;
    }

    try {
      setState(() {
        _polylines.clear();
      });
      final directions = await _getRouteCoordinates(
        _currentUserLocation!,
        destination,
      );

      if (directions != null &&
          directions['features'] != null &&
          directions['features'].isNotEmpty) {
        final coordinates =
            directions['features'][0]['geometry']['coordinates'];
        final points = coordinates
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.green,
              width: 5,
              points: points,
            ),
          );
        });
        LatLngBounds bounds = boundsFromLatLngList(points);
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      }
    } catch (e) {
      print("Error getting directions: $e");
      showCustomPopup(
        context: context,
        message: 'Tidak dapat menampilkan route',
        backgroundColor: Colors.green,
        icon: Icons.route_outlined,
      );
    }
  }

  void showCustomPopup({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.green,
    IconData icon = Icons.info_outline,
  }) {
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
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  Future<Map<String, dynamic>?> _getRouteCoordinates(
      LatLng origin, LatLng destination) async {
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
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  LatLngBounds boundsFromLatLngList(List<LatLng> list) {
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
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
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
    final selectedLocation = _wasteBinLocations.firstWhere(
      (location) => location['name'] == locationName,
      orElse: () => _wasteBinLocations[0],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status $locationName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${selectedLocation['status']}'),
            const SizedBox(height: 8),
            const Text('Last updated: Today, 10:30 AM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
    );
  }

  Widget _buildLocationItem(String name, String status) {
    Color statusColor = Colors.green;
    if (status == 'Almost Full') {
      statusColor = Colors.orange;
    } else if (status == 'Full') {
      statusColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _showRoute(name),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(60, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Rute'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _showStatus(name),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(60, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Status'),
            ),
          ],
        ),
      ),
    );
  }
}
