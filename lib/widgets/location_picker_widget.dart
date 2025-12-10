import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  late TextEditingController _addressController;
  bool _isSearching = false;

  // Một số vị trí mặc định ở Việt Nam
  static const LatLng _defaultHanoi = LatLng(21.0285, 105.8542);
  static const LatLng _defaultHCM = LatLng(10.8231, 106.6297);
  static const LatLng _defaultDaNang = LatLng(16.0544, 108.2022);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? _defaultHanoi;
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _confirmLocation() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ')),
      );
      return;
    }
    widget.onLocationSelected(_selectedLocation, _addressController.text.trim());
    Navigator.pop(context);
  }

  void _moveToLocation(LatLng location, String cityName) {
    setState(() {
      _selectedLocation = location;
      _addressController.text = cityName;
    });
    _mapController.move(location, 13.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí công việc'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
            tooltip: 'Xác nhận',
          ),
        ],
      ),
      body: Column(
        children: [
          // Address input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ cụ thể',
                    hintText: 'VD: 123 Nguyễn Huệ, Quận 1, TP.HCM',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _addressController.clear(),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Quick location buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickLocationButton(
                        'Hà Nội',
                        Icons.location_city,
                        _defaultHanoi,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickLocationButton(
                        'TP.HCM',
                        Icons.location_city,
                        _defaultHCM,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickLocationButton(
                        'Đà Nẵng',
                        Icons.location_city,
                        _defaultDaNang,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Coordinate display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tọa độ: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _mapController.move(_selectedLocation, 15.0);
                  },
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Zoom'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                onTap: _onMapTap,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.recruitment_app',
                  maxZoom: 19,
                ),
                // Marker layer
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60.0,
                      height: 60.0,
                      point: _selectedLocation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Instruction
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nhấn vào bản đồ để chọn vị trí chính xác của công ty',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confirm button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _confirmLocation,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Xác nhận vị trí',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLocationButton(String label, IconData icon, LatLng location) {
    final isSelected = _selectedLocation.latitude == location.latitude &&
        _selectedLocation.longitude == location.longitude;

    return OutlinedButton.icon(
      onPressed: () => _moveToLocation(location, label),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : const Color(0xFF667eea),
        backgroundColor: isSelected ? const Color(0xFF667eea) : Colors.white,
        side: BorderSide(
          color: const Color(0xFF667eea),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
