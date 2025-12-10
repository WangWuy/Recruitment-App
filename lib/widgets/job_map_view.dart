import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class JobMapView extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  final Function(Map<String, dynamic>)? onJobTap;

  const JobMapView({
    super.key,
    required this.jobs,
    this.onJobTap,
  });

  @override
  State<JobMapView> createState() => _JobMapViewState();
}

class _JobMapViewState extends State<JobMapView> {
  late MapController _mapController;
  Map<String, dynamic>? _selectedJob;

  // Default center (Vietnam)
  static const LatLng _defaultCenter = LatLng(16.0544, 108.2022); // Đà Nẵng

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  List<Map<String, dynamic>> get _jobsWithLocation {
    return widget.jobs.where((job) {
      final lat = job['latitude'];
      final lng = job['longitude'];
      return lat != null && lng != null;
    }).toList();
  }

  LatLng _getCenterPoint() {
    if (_jobsWithLocation.isEmpty) return _defaultCenter;

    double avgLat = 0;
    double avgLng = 0;
    for (var job in _jobsWithLocation) {
      avgLat += (job['latitude'] as num).toDouble();
      avgLng += (job['longitude'] as num).toDouble();
    }
    avgLat /= _jobsWithLocation.length;
    avgLng /= _jobsWithLocation.length;

    return LatLng(avgLat, avgLng);
  }

  void _onMarkerTap(Map<String, dynamic> job) {
    setState(() {
      _selectedJob = job;
    });

    // Move map to job location
    final lat = (job['latitude'] as num).toDouble();
    final lng = (job['longitude'] as num).toDouble();
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_jobsWithLocation.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getCenterPoint(),
            initialZoom: 12.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.recruitment_app',
              maxZoom: 19,
            ),
            // Job markers
            MarkerLayer(
              markers: _jobsWithLocation.map((job) {
                final lat = (job['latitude'] as num).toDouble();
                final lng = (job['longitude'] as num).toDouble();
                final isSelected = _selectedJob?['id'] == job['id'];

                return Marker(
                  width: isSelected ? 80.0 : 60.0,
                  height: isSelected ? 80.0 : 60.0,
                  point: LatLng(lat, lng),
                  child: GestureDetector(
                    onTap: () => _onMarkerTap(job),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Shadow
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: isSelected ? 16 : 12,
                              height: isSelected ? 8 : 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          // Marker icon
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSelected ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF667eea)
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected
                                              ? const Color(0xFF667eea)
                                              : Colors.red)
                                          .withOpacity(0.5),
                                      blurRadius: isSelected ? 10 : 6,
                                      spreadRadius: isSelected ? 2 : 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.work,
                                  color: Colors.white,
                                  size: isSelected ? 28 : 20,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${job['applications_count'] ?? 0} ứng viên',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF667eea),
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
              }).toList(),
            ),
          ],
        ),

        // Job info card (when selected)
        if (_selectedJob != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildJobCard(_selectedJob!),
          ),

        // Legend
        Positioned(
          top: 16,
          right: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onJobTap != null) {
            widget.onJobTap!(job);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company_name'] ?? 'Unknown Company',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedJob = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job['location'] ?? 'Location not specified',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatSalary(job),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onJobTap != null)
                    const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Color(0xFF667eea),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.work, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_jobsWithLocation.length} việc làm',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có việc làm nào có vị trí trên bản đồ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSalary(Map<String, dynamic> job) {
    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    if (salaryMin == null && salaryMax == null) {
      return 'Thỏa thuận';
    }

    String format(int salary) {
      if (salary >= 1000000) {
        return '${(salary / 1000000).toStringAsFixed(0)}M';
      }
      return salary.toString();
    }

    if (salaryMin != null && salaryMax != null) {
      return '${format(salaryMin)} - ${format(salaryMax)} VNĐ';
    } else if (salaryMin != null) {
      return 'Từ ${format(salaryMin)} VNĐ';
    } else {
      return 'Lên đến ${format(salaryMax!)} VNĐ';
    }
  }
}
