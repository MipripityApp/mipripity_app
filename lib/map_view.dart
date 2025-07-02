import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapView extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;
  final String propertyAddress;
  final double latitude;
  final double longitude;

  const MapView({
    Key? key,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyAddress,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Simulate loading time for the map
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _openInGoogleMaps() async {
    final String googleMapsUrl = 
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
    
    try {
      final Uri uri = Uri.parse(googleMapsUrl);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getDirections() async {
    final String directionsUrl = 
        'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';
    
    try {
      final Uri uri = Uri.parse(directionsUrl);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch directions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshMap() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Property Location',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF000080)),
            onPressed: _refreshMap,
            tooltip: 'Refresh Map',
          ),
        ],
      ),
      body: Column(
        children: [
          // Property Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.propertyTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFFF39322),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.propertyAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lat: ${widget.latitude.toStringAsFixed(6)}, Lng: ${widget.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map Container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Interactive Map Component
                    if (_isLoading)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[100],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFFF39322),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading map...',
                                style: TextStyle(
                                  color: Color(0xFF000080),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_error != null)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshMap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF39322),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Simulated Interactive Map
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[100]!,
                              Colors.green[100]!,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Map grid pattern
                            CustomPaint(
                              size: Size.infinite,
                              painter: MapGridPainter(),
                            ),
                            // Property marker
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF39322),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.propertyTitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF000080),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Zoom controls
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Zoom in'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                        Container(
                                          height: 1,
                                          width: 24,
                                          color: Colors.grey[300],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Zoom out'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Map type indicator
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Interactive Map',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF000080),
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
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getDirections,
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.map),
                        label: const Text('Live View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF39322),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/property-details/${widget.propertyId}',
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Property Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for map grid pattern
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
