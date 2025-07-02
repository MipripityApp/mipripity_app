import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shared/bottom_navigation.dart';
import 'dart:async';

class GetCoordinateScreen extends StatefulWidget {
  const GetCoordinateScreen({Key? key}) : super(key: key);

  @override
  State<GetCoordinateScreen> createState() => _GetCoordinateScreenState();
}

class _GetCoordinateScreenState extends State<GetCoordinateScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double? _latitude;
  double? _longitude;
  String _address = 'Fetching address...';
  bool _isCopied = false;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Location permissions are denied';
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Location permissions are permanently denied, we cannot request permissions.';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoading = false;
        
        // In a real app, you would use a geocoding service to get the address
        // For this example, we'll just use the coordinates
        _address = 'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}';
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  // Function to copy coordinates to clipboard
  void _copyCoordinates() {
    if (_latitude != null && _longitude != null) {
      Clipboard.setData(ClipboardData(
        text: '${_latitude!.toStringAsFixed(6)},${_longitude!.toStringAsFixed(6)}'
      ));
      
      setState(() {
        _isCopied = true;
      });
      
      // Reset the copied state after 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinates copied to clipboard'),
          backgroundColor: Color(0xFF000080),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Function to open in Google Maps
  Future<void> _openInGoogleMaps() async {
    if (_latitude != null && _longitude != null) {
      final url = 'https://maps.google.com/?q=${_latitude!.toStringAsFixed(6)},${_longitude!.toStringAsFixed(6)}';
      final Uri uri = Uri.parse(url);
      
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $url');
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
  }

  // Function to share coordinates
  void _shareCoordinates() {
    if (_latitude != null && _longitude != null) {
      // In a real app, you would use a share plugin
      // For this example, we'll just copy to clipboard
      Clipboard.setData(ClipboardData(
        text: 'Check out this location: https://maps.google.com/?q=${_latitude!.toStringAsFixed(6)},${_longitude!.toStringAsFixed(6)}'
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share link copied to clipboard'),
          backgroundColor: Color(0xFF000080),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Get Coordinates',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF000080)),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),
          
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SharedBottomNavigation(
              activeTab: "get-coordinate", // You can change this to match the current screen context
              onTabChange: (tab) {
                SharedBottomNavigation.handleNavigation(context, tab);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Bottom padding for nav bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Current Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLocationContent(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Map Preview Card (if coordinates are available)
          if (_latitude != null && _longitude != null && !_isLoading && !_hasError)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Map Preview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000080),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openInGoogleMaps,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open in Maps'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFFF39322),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // In a real app, you would use a proper map widget
                            // For this example, we'll use a placeholder
                            Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.map,
                                      size: 64,
                                      color: Color(0xFF000080),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Map Preview\nLatitude: ${_latitude!.toStringAsFixed(6)}\nLongitude: ${_longitude!.toStringAsFixed(6)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF000080),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _openInGoogleMaps,
                                      icon: const Icon(Icons.map, size: 16),
                                      label: const Text('View in Google Maps'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: const Color(0xFF000080),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFFF39322),
            ),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(
                color: Color(0xFF000080),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_hasError) {
      return Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getCurrentLocation,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFF39322),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      );
    }
    
    if (_latitude == null || _longitude == null) {
      return const Center(
        child: Text(
          'Location data not available',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address
        Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Color(0xFFF39322),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000080),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Coordinates
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coordinates',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000080),
                    ),
                  ),
                  GestureDetector(
                    onTap: _copyCoordinates,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isCopied ? Colors.green : const Color(0xFFF39322),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCopied ? Icons.check : Icons.copy,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isCopied ? 'Copied' : 'Copy',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCoordinateItem(
                      'Latitude',
                      _latitude!.toStringAsFixed(6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCoordinateItem(
                      'Longitude',
                      _longitude!.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(Icons.map, size: 16),
                label: const Text('Open in Maps'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF000080),
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
                onPressed: _shareCoordinates,
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share Location'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF39322),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinateItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF000080),
          ),
        ),
      ],
    );
  }
}