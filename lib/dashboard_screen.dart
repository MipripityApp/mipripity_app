import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'api/property_api.dart';
import 'services/user_service.dart';
import 'map_view.dart';
import 'filter_form.dart';
import 'shared/bottom_navigation.dart';
import 'utils/currency_formatter.dart';
import 'providers/user_provider.dart';
import 'utils/property_prospect_util.dart';

// Data model for listings with database support
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final String city;
  final String state;
  final String country;
  final String category;
  final String status;
  final String createdAt;
  final int views;
  final String listerName;
  final String listerDp;
  final String urgencyPeriod;
  final String listingImage;
  final int? bedrooms;
  final int? bathrooms;
  final int? toilets;
  final int? parkingSpaces;
  final bool? hasInternet;
  final bool? hasElectricity;
  final String? landTitle;
  final double? landSize;
  final String? quantity;
  final String? condition;
  final String? listerWhatsapp;
  final String? listerEmail;
  final String? userId;
  final String latitude;
  final String longitude;

  // Factory constructor to create a Listing from database JSON
  factory Listing.fromJson(Map<String, dynamic> json, String propertyType) {
    // Extract city and state from location
    String location = json['location'] ?? '';
    List<String> locationParts = location.split(',');
    String city = locationParts.isNotEmpty ? locationParts[0].trim() : '';
    String state = locationParts.length > 1 ? locationParts[1].trim() : '';
    String country = locationParts.length > 2 ? locationParts[2].trim() : 'Nigeria';

    // Default values for image path based on category
    String defaultImagePath = 'assets/images/residential1.jpg';
    if (propertyType == 'commercial') {
      defaultImagePath = 'assets/images/commercial1.jpg';
    } else if (propertyType == 'land') {
      defaultImagePath = 'assets/images/land1.jpeg';
    } else if (propertyType == 'material') {
      defaultImagePath = 'assets/images/material1.jpg';
    }

    // Set a default urgency period 7 days from now if not provided
    final DateTime now = DateTime.now();
    final String defaultUrgencyPeriod = now.add(const Duration(days: 7)).toIso8601String();

    return Listing(
      id: json['property_id']?.toString() ?? json['id']?.toString() ?? '0',
      title: json['title'] ?? 'Untitled Property',
      description: json['description'] ?? 'No description available',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      location: location,
      city: city,
      state: state,
      country: country,
      category: json['category'] ?? propertyType,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      views: json['views'] is int ? json['views'] : 0,
      listerName: json['lister_name'] ?? 'Unknown',
      listerDp: json['lister_dp'] ?? 'assets/images/mipripity.png',
      urgencyPeriod: json['urgency_period'] ?? defaultUrgencyPeriod,
      listingImage: (json['images'] is List && json['images'].isNotEmpty)
      ? json['images'][0]
      : defaultImagePath,
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      bedrooms: propertyType == 'residential' ? json['bedrooms'] : null,
      bathrooms: propertyType == 'residential' ? json['bathrooms'] : null,
      toilets: propertyType == 'residential' ? json['toilets'] : null,
      parkingSpaces: propertyType == 'residential' ? json['parking_spaces'] : null,
      hasInternet: json['has_internet'],
      hasElectricity: json['has_electricity'],
      landTitle: propertyType == 'land' ? json['land_title'] : null,
      landSize: json['land_size'] != null
      ? double.tryParse(json['land_size'].toString())
      : null,
      quantity: propertyType == 'material' ? json['quantity'] : null,
      condition: propertyType == 'material' ? json['condition'] : null,
      listerWhatsapp: json['lister_whatsapp'] ?? json['whatsapp_link'],
      listerEmail: json['lister_email'] ?? json['email'],
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
    );
  }
  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.city,
    required this.state,
    required this.country,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.views,
    required this.listerName,
    required this.listerDp,
    required this.urgencyPeriod,
    required this.listingImage,
    required this.latitude,
    required this.longitude,
    this.bedrooms,
    this.bathrooms,
    this.toilets,
    this.parkingSpaces,
    this.hasInternet,
    this.hasElectricity,
    this.landTitle,
    this.landSize,
    this.quantity,
    this.condition,
    this.listerWhatsapp,
    this.listerEmail,
    this.userId,
  });
}

// User profile model with database support
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;

  // Factory constructor to create UserProfile from database data
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '0',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      fullName: json['full_name'] ?? 
                json['fullName'] ?? 
                '${json['first_name'] ?? json['firstName'] ?? ''} ${json['last_name'] ?? json['lastName'] ?? ''}',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? 'assets/images/mipripity-logo.png',
    );
  }
  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
  });
}

// Format price to Nigerian Naira with comma separators
String formatFullPrice(num amount, {String symbol = '₦'}) {
  return CurrencyFormatter.formatNaira(amount, useAbbreviations: false);
}

// Format price to Nigerian Naira
String formatPrice(num amount, {String symbol = '₦'}) {
  return CurrencyFormatter.formatNaira(amount, useAbbreviations: true);
}

// Get RichText with proper Naira symbol using CustomFont
Widget getNairaRichText(
  num price, {
  Color textColor = Colors.black,
  double fontSize = 12.0,
  FontWeight fontWeight = FontWeight.bold,
}) {
  return CurrencyFormatter.formatNairaRichText(
    price,
    textStyle: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
    ),
    symbolStyle: CurrencyFormatter.getNairaTextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
    ),
    useAbbreviations: true,
  );
}

// CountdownTimer Widget
class CountdownTimer extends StatefulWidget {
  final String targetDate;

  const CountdownTimer({super.key, required this.targetDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeRemaining();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final targetDateTime = DateTime.parse(widget.targetDate);
    final now = DateTime.now();
    setState(() {
      _timeRemaining = targetDateTime.difference(now);
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
        _timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeBox(days, 'Days'),
        const SizedBox(width: 4),
        _buildTimeBox(hours, 'Hrs'),
        const SizedBox(width: 4),
        _buildTimeBox(minutes, 'Min'),
        const SizedBox(width: 4),
        _buildTimeBox(seconds, 'Sec'),
      ],
    );
  }

  Widget _buildTimeBox(int value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFFF39322).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// DepositOptions Widget
class DepositOptions extends StatelessWidget {
  final double price;
  final Function(int, double) onDepositClick;
  const DepositOptions({
    super.key,
    required this.price,
    required this.onDepositClick,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deposit Options',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildDepositOption(10),
                  const SizedBox(height: 4),
                  _buildDepositOption(30),
                  const SizedBox(height: 4),
                  _buildDepositOption(50),
                  const SizedBox(height: 4),
                  _buildDepositOption(70),
                  const SizedBox(height: 4),
                  _buildDepositOption(90),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  _buildDepositOption(20),
                  const SizedBox(height: 4),
                  _buildDepositOption(40),
                  const SizedBox(height: 4),
                  _buildDepositOption(60),
                  const SizedBox(height: 4),
                  _buildDepositOption(80),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildDepositOption(int percentage) {
    final depositAmount = price * percentage / 100;
    return GestureDetector(
      onTap: () => onDepositClick(percentage, depositAmount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF000080).withOpacity(0.1), // Blue transparent background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF000080).withOpacity(0.3), // Blue transparent border
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000080).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF000080).withOpacity(0.12),
              const Color(0xFF000080).withOpacity(0.08),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF000080).withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            getNairaRichText(
              depositAmount,
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              textColor: const Color(0xFF000080), // Changed to blue
            ),
          ],
        ),
      ),
    );
  }
}

// BidModal Widget - Updated to be a proper modal dialog
class BidModal extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final double listingPrice;

  const BidModal({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.listingPrice,
  });

  @override
  State<BidModal> createState() => _BidModalState();
}

class _BidModalState extends State<BidModal> {
  final TextEditingController _bidAmountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bidAmountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop(); // Close the modal
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid submitted successfully!'),
            backgroundColor: Color(0xFFF39322),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Place a Bid',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Listing: ${widget.listingTitle}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Asking Price: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                getNairaRichText(
                  widget.listingPrice,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  textColor: const Color(0xFFF39322),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _bidAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Bid Amount (₦)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFF39322),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF39322),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Bid',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// InspectionModal Widget - Updated to be a proper modal dialog
class InspectionModal extends StatefulWidget {
  final String listingId;
  final String listingTitle;

  const InspectionModal({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  State<InspectionModal> createState() => _InspectionModalState();
}

class _InspectionModalState extends State<InspectionModal> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _handleSubmit() {
    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop(); // Close the modal
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection scheduled successfully!'),
            backgroundColor: Color(0xFFF39322),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schedule Inspection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Listing: ${widget.listingTitle}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Preferred Date',
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFF39322),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Preferred Time',
                    suffixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFF39322),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF39322),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Schedule Inspection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LayeredListingCard Widget - Updated to use modal dialogs
class LayeredListingCard extends StatefulWidget {
  final Listing listing;

  const LayeredListingCard({super.key, required this.listing});

  @override
  State<LayeredListingCard> createState() => _LayeredListingCardState();
}

class _LayeredListingCardState extends State<LayeredListingCard> {
  Map<String, dynamic>? _listerData;

  @override
  void initState() {
    super.initState();
    _fetchListerData();
  }

  void _fetchListerData() {
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.listing.userId != null) {
        setState(() {
          _listerData = {
            'id': widget.listing.userId,
            'first_name': widget.listing.listerName.split(' ').first,
            'last_name': widget.listing.listerName.split(' ').length > 1
                ? widget.listing.listerName.split(' ').last
                : '',
            'avatar_url': widget.listing.listerDp,
          };
        });
      }
    });
  }

  void _handleCardClick() {
    // Navigate to property details with all listing data
    Navigator.pushNamed(
      context, 
      '/property-details/${widget.listing.id}',
      arguments: widget.listing,
    );

    // Increment view count in the background
    // This would typically be an API call
  }

  void _handleWhatsappClick(BuildContext context) {
    // Check if listerWhatsapp is available
    if (widget.listing.listerWhatsapp != null && widget.listing.listerWhatsapp!.isNotEmpty) {
      _launchWhatsappUrl(widget.listing.listerWhatsapp!);
    } else {
      // Show a snackbar if WhatsApp link is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp contact not available for this lister'),
          backgroundColor: Color(0xFF000080),
        ),
      );
    }
  }

  // Add this helper method to launch the URL
  Future<void> _launchWhatsappUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp URL: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated to show modal dialog instead of popup
  void _handleBidClick() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BidModal(
          listingId: widget.listing.id,
          listingTitle: widget.listing.title,
          listingPrice: widget.listing.price,
        );
      },
    );
  }

  // Updated to show modal dialog instead of popup
  void _handleInspectClick() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return InspectionModal(
          listingId: widget.listing.id,
          listingTitle: widget.listing.title,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed Stack wrapper since we no longer need overlay popups
    return GestureDetector(
      onTap: _handleCardClick,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
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
          children: [
            // Layer I - Property Image, Title, Location
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: widget.listing.listingImage.startsWith('http')
                      ? Image.network(
                          widget.listing.listingImage,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          widget.listing.listingImage,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Lister's profile picture in top left corner
                Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        // Lister DP
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _listerData != null
                                  ? (_listerData!['lister_dp'] ?? widget.listing.listerDp)
                                  : widget.listing.listerDp,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 20, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Lister Name
                        Text(
                          _listerData != null
                              ? '${_listerData!['first_name']}'
                              : widget.listing.listerName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Category label at top right corner
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.listing.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ),
                ),
                // Bottom gradient with property details
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.listing.city}, ${widget.listing.state}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        getNairaRichText(
                          widget.listing.price,
                          textColor: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Layer K - Countdown Timer positioned at bottom right of image
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Blinking red indicator
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.3, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red.withOpacity(value),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(value * 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Closing in',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 3),
                        CountdownTimer(
                          targetDate: widget.listing.urgencyPeriod,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Divider
            const Divider(height: 1),

            // Property Features
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildPropertyFeatures(),
            ),

            // Divider
            const Divider(height: 1),

            // Layers J and L Container - Rearranged side by side
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Four vertical buttons replacing Layer J
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF000080).withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          
                          // WhatsApp Button
                          _buildActionButton(
                            'WhatsApp',
                            'assets/images/Whatapp.gif',
                            Icons.message,
                            Colors.green,
                            () => _handleWhatsappClick(context),
                            backgroundColor: const Color(0xFF000080),
                            textColor: Colors.white,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Inspect Now Button
                          _buildActionButton(
                            'Inspect Now',
                            'assets/images/Inspect.gif',
                            Icons.search,
                            Colors.blue,
                            _handleInspectClick,
                            backgroundColor: const Color(0xFF000080),
                            textColor: Colors.white,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Bid Now Button
                          _buildActionButton(
                            'Bid Now',
                            'assets/images/Bid Now.gif',
                            Icons.gavel,
                            Colors.orange,
                            _handleBidClick,
                            backgroundColor: const Color(0xFF000080),
                            textColor: Colors.white,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Take a Tour Button
                          _buildActionButton(
                            'Take a Tour',
                            'assets/icons/tour-icon.gif',
                            Icons.view_in_ar,
                            const Color(0xFF000080),
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapView(
                                    propertyId: widget.listing.id,
                                    propertyTitle: widget.listing.title,
                                    propertyAddress: '${widget.listing.location}, ${widget.listing.city}, ${widget.listing.state}',
                                    latitude: double.tryParse(widget.listing.latitude) ?? 0.0,
                                    longitude: double.tryParse(widget.listing.longitude) ?? 0.0,
                                  ),
                                ),
                              );
                            },
                            backgroundColor: const Color(0xFF000080),
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Space between Layer J and L
                  const SizedBox(width: 8),
                  
                  // Layer L - Deposit Options (wider than Layer J)
                  Expanded(
                    flex: 6, // Increased flex value to make it wider
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF000080).withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deposit Options',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000080),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // More compact deposit options grid
                          Column(
                            children: [
                              // Row 1: 10%, 30%, 50%
                              Row(
                                children: [
                                  Expanded(child: _buildDepositOptionButton(10)),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildDepositOptionButton(30)),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildDepositOptionButton(50)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Row 2: 20%, 40%, 60%
                              Row(
                                children: [
                                  Expanded(child: _buildDepositOptionButton(20)),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildDepositOptionButton(40)),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildDepositOptionButton(60)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Row 3: 70%, 80%, 90%
                              Row(
                                children: [
                                  Expanded(child: _buildDepositOptionButton(70)),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildDepositOptionButton(80)),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildDepositOptionButton(90)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Property Prospect Grid - 2 rows x 4 columns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Property Prospects',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Grid of property prospect buttons
                  _buildPropertyProspectGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create action buttons
  Widget _buildActionButton(
    String label,
    String iconPath,
    IconData fallbackIcon,
    Color iconColor,
    VoidCallback onTap, {
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF000080),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF000080).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      fallbackIcon,
                      size: 14,
                      color: iconColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000080),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyFeatures() {
    switch (widget.listing.category) {
      case 'residential':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureItem(
              'Bedrooms',
              'assets/images/bed.gif',
              Icons.bed,
              widget.listing.bedrooms?.toString() ?? '0',
            ),
            _buildFeatureItem(
              'Bathrooms',
              'assets/images/bathtub.gif',
              Icons.bathtub,
              widget.listing.bathrooms?.toString() ?? '0',
            ),
            _buildFeatureItem(
              'Toilets',
              'assets/images/toilet.gif',
              Icons.wc,
              widget.listing.toilets?.toString() ?? '0',
            ),
            _buildFeatureItem(
              'Parking',
              'assets/images/parking.gif',
              Icons.local_parking,
              widget.listing.parkingSpaces?.toString() ?? '0',
            ),
          ],
        );
      case 'commercial':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureItem(
              'Internet',
              'assets/images/internet.gif',
              Icons.wifi,
              widget.listing.hasInternet == true ? 'Available' : 'No Internet',
            ),
            _buildFeatureItem(
              'Power',
              'assets/images/power.gif',
              Icons.power,
              widget.listing.hasElectricity == true ? '24/7' : 'No Power',
            ),
          ],
        );
      case 'land':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureItem(
              'Title',
              'assets/images/Title.gif',
              Icons.description,
              widget.listing.landTitle ?? 'N/A',
            ),
            _buildFeatureItem(
              'Land Size',
              'assets/icons/Size.gif',
              Icons.straighten,
              '${widget.listing.landSize?.toString() ?? '0'} sqm',
            ),
          ],
        );
      case 'material':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureItem(
              'Quantity',
              '',
              Icons.inventory_2,
              widget.listing.quantity ?? 'N/A',
            ),
            _buildFeatureItem(
              'Condition',
              '',
              Icons.check_circle,
              widget.listing.condition ?? 'N/A',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Build the property prospect grid (2 rows x 4 columns)
  Widget _buildPropertyProspectGrid() {
    // Get property type based on listing category
    final propertyType = _getPropertyTypeFromCategory(widget.listing.category);
    
    // Get property prospect suggestions
    final prospects = PropertyProspectUtil.getRandomSuggestionsForType(
      propertyType,
      widget.listing.price,
    );
    
    return Column(
      children: [
        // First row (4 prospects)
        Row(
          children: [
            for (int i = 0; i < 4; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: _buildProspectButton(prospects[i]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Second row (4 prospects)
        Row(
          children: [
            for (int i = 4; i < 8; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: _buildProspectButton(prospects[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  // Helper method to convert listing category to PropertyType
  PropertyType _getPropertyTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'residential':
        return PropertyType.residential;
      case 'commercial':
        return PropertyType.commercial;
      case 'land':
        return PropertyType.land;
      case 'material':
        return PropertyType.material;
      default:
        return PropertyType.residential;
    }
  }
  
  // Build a single property prospect button
    Widget _buildProspectButton(PropertyProspect prospect) {
    return GestureDetector(
      onTap: () => _handleProspectClick(prospect),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white, // White button background
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Subtle shadow
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2), // Drop shadow
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE0E0E0), // Optional soft border
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prospect.title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000080), // Corrected to opaque navy blue
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Handle property prospect button click
  void _handleProspectClick(PropertyProspect prospect) {
    PropertyProspectUtil.showProspectDetails(
      context,
      prospect,
      widget.listing.price,
    );
  }
  
  // Modified for smaller, more compact deposit buttons
  Widget _buildDepositOptionButton(int percentage) {
    final depositAmount = widget.listing.price * percentage / 100;
    return GestureDetector(
      onTap: () {
        // Handle deposit click
        debugPrint('Selected deposit: $percentage% - $depositAmount');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF000080).withOpacity(0.1), // Blue transparent background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF000080).withOpacity(0.3), // Blue transparent border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000080).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF000080).withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            const SizedBox(height: 2),
            getNairaRichText(
              depositAmount,
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              textColor: const Color(0xFF000080),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      String label, String iconPath, IconData fallbackIcon, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: iconPath.isNotEmpty
              ? Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      fallbackIcon,
                      size: 16,
                      color: Colors.grey[600],
                    );
                  },
                )
              : Icon(
                  fallbackIcon,
                  size: 16,
                  color: Colors.grey[600],
                ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF000080),
          ),
        ),
      ],
    );
  }
}

// DashboardSidebar Widget
class DashboardSidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const DashboardSidebar({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Sidebar
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.7,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildMenuItemWithImage(
                      context,
                      'Inbox',
                      'assets/icons/inbox.png',
                      () {
                        Navigator.pushNamed(context, '/inbox');
                        onClose();
                      },
                    ),      
                    _buildMenuItemWithImage(
                      context,
                      'My Listings',
                      'assets/icons/my-listings.png',
                      () {
                        Navigator.pushNamed(context, '/my-listings');
                        onClose();
                      },
                    ),
                    _buildMenuItemWithImage(
                      context,
                      'Chat',
                      'assets/icons/chat.png',
                      () {
                        Navigator.pushNamed(context, '/chat');
                        onClose();
                      },
                    ),
                    _buildMenuItemWithImage(
                      context,
                      'Get Coordinate',
                      'assets/icons/get-coordinates.png',
                      () {
                        Navigator.pushNamed(context, '/get-coordinate');
                        onClose();
                      },
                    ),
                    _buildMenuItemWithImage(
                      context,
                      'Settings',
                      'assets/icons/settings.png',
                      () {
                        Navigator.pushNamed(context, '/settings');
                        onClose();
                      },
                    ),
                    _buildMenuItemWithImage(
                      context,
                      'Verify CAC',
                      'assets/icons/company.gif',
                      () {
                        Navigator.pushNamed(context, '/verify-cac');
                        onClose();
                      },
                    ),
                    const Spacer(),
                    _buildMenuItem(
                      context,
                      'Logout',
                      Icons.logout,
                      () {
                        // Handle logout
                        Navigator.pushReplacementNamed(context, '/login');
                        onClose();
                      },
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF000080),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : const Color(0xFF000080),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMenuItemWithImage(
    BuildContext context,
    String title,
    String iconAsset,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: ImageIcon(
        AssetImage(iconAsset),
        size: 24,
        color: isLogout ? Colors.red : const Color(0xFF000080),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : const Color(0xFF000080),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// Custom background painter for dashboard screen
class _DashboardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Create paint objects for different elements
    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF2C3E50), // Deep blue
          Color(0xFF4A5568), // Slate
          Color(0xFF1A365D), // Navy blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    final Paint shapePaint1 = Paint()
      ..color = const Color(0xFF34495E).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final Paint shapePaint2 = Paint()
      ..color = const Color(0xFF1A365D).withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final Paint shapePaint3 = Paint()
      ..color = const Color(0xFF0A2A5E).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // Draw background gradient
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), gradientPaint);
    
    // Draw geometric shapes for 3D effect
    
    // Large circle in the bottom right
    canvas.drawCircle(
      Offset(width * 0.9, height * 0.9),
      width * 0.3,
      shapePaint1,
    );
    
    // Medium circle in the top left
    canvas.drawCircle(
      Offset(width * 0.15, height * 0.2),
      width * 0.15,
      shapePaint2,
    );
    
    // Small circle in the middle right
    canvas.drawCircle(
      Offset(width * 0.8, height * 0.4),
      width * 0.1,
      shapePaint3,
    );
    
    // Draw a curved path in the background
    final Path path1 = Path()
      ..moveTo(0, height * 0.3)
      ..quadraticBezierTo(width * 0.4, height * 0.2, width * 0.8, height * 0.4)
      ..quadraticBezierTo(width * 1.0, height * 0.5, width, height * 0.65)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    
    canvas.drawPath(path1, shapePaint2);
    
    // Draw another curved path
    final Path path2 = Path()
      ..moveTo(0, height * 0.65)
      ..quadraticBezierTo(width * 0.3, height * 0.7, width * 0.5, height * 0.6)
      ..quadraticBezierTo(width * 0.7, height * 0.5, width, height * 0.3)
      ..lineTo(width, 0)
      ..lineTo(0, 0)
      ..close();
    
    // Create a new paint for path2
    final Paint pathPaint2 = Paint()
      ..color = const Color(0xFF1E3A5F).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, pathPaint2);
    
    // Add floating polygons
    final Path polygon1 = Path();
    polygon1.addPolygon([
      Offset(width * 0.2, height * 0.4),
      Offset(width * 0.3, height * 0.35),
      Offset(width * 0.25, height * 0.25),
      Offset(width * 0.15, height * 0.3),
    ], true);
    
    // Create a new paint for polygon1
    final Paint polygonPaint1 = Paint()
      ..color = const Color(0xFF2C5282).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygon1, polygonPaint1);
    
    final Path polygon2 = Path();
    polygon2.addPolygon([
      Offset(width * 0.6, height * 0.7),
      Offset(width * 0.75, height * 0.65),
      Offset(width * 0.7, height * 0.5),
      Offset(width * 0.55, height * 0.55),
    ], true);
    
    // Create a new paint for polygon2
    final Paint polygonPaint2 = Paint()
      ..color = const Color(0xFF2B6CB0).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygon2, polygonPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Main Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  
  String _selectedCategory = '';
  final bool _showFilterBadge = false;
  List<Listing> _listings = [];
  bool _loading = true;
  String? _error;
  final String _activeTab = 'home';
  bool _sidebarOpen = false;
  UserProfile? _userData;
  final Map<String, dynamic> _categoryFilters = {};

  // Animation controller for the background effects
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchListings();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      // Get user from provider first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.getCurrentUser();
      
      if (currentUser != null) {
        setState(() {
          _userData = UserProfile(
            id: currentUser.id.toString(),
            email: currentUser.email,
            firstName: currentUser.firstName,
            lastName: currentUser.lastName,
            fullName: '${currentUser.firstName} ${currentUser.lastName}'.trim(),
            avatarUrl: currentUser.avatarUrl ?? 'assets/images/mipripity.png',
          );
        });
        return;
      }
      
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      
      if (userDataJson != null) {
        final userMap = jsonDecode(userDataJson);
        setState(() {
          _userData = UserProfile.fromJson(userMap);
        });
      }
      
    } catch (e) {
      print('Error loading user data: $e');
      // Set default guest user
      setState(() {
        _userData = UserProfile(
          id: '0',
          email: '',
          firstName: 'Guest',
          lastName: 'User',
          fullName: 'Guest User',
          avatarUrl: 'assets/images/mipripity.png',
        );
      });
    }
  }

  Future<void> _fetchListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      List<Map<String, dynamic>> propertiesData = [];
      
      // Fetch properties from PostgreSQL database based on selected category or all properties
      if (_selectedCategory.isEmpty) {
        // Fetch all properties directly from the API
        propertiesData = await PropertyApi.getAllProperties();
      } else {
        // Fetch properties for selected category directly from the API
        propertiesData = await PropertyApi.getPropertiesByCategory(_selectedCategory);
      }
      
      // Apply filters if any
      if (_categoryFilters.isNotEmpty && _selectedCategory.isNotEmpty) {
        final filters = _categoryFilters[_selectedCategory] ?? {};
        
        if (filters.isNotEmpty) {
          // Apply price filters
          if (filters.containsKey('minPrice') || filters.containsKey('maxPrice')) {
            double? minPrice = filters.containsKey('minPrice') ? filters['minPrice'] as double : null;
            double? maxPrice = filters.containsKey('maxPrice') ? filters['maxPrice'] as double : null;
            
            propertiesData = propertiesData.where((property) {
              final price = double.tryParse(property['price']?.toString() ?? '0') ?? 0.0;
              bool passes = true;
              
              if (minPrice != null) {
                passes = passes && price >= minPrice;
              }
              
              if (maxPrice != null) {
                passes = passes && price <= maxPrice;
              }
              
              return passes;
            }).toList();
          }
          
          // Apply location/state filter
          if (filters.containsKey('state') && filters['state'] != null && filters['state'].isNotEmpty) {
            final stateFilter = filters['state'] as String;
            propertiesData = propertiesData.where((property) {
              final location = property['location']?.toString().toLowerCase() ?? '';
              return location.contains(stateFilter.toLowerCase());
            }).toList();
          }
          
          // Apply status filter
          if (filters.containsKey('status') && filters['status'] != null && filters['status'].isNotEmpty) {
            final statusFilter = filters['status'] as String;
            propertiesData = propertiesData.where((property) {
              return property['status'] == statusFilter;
            }).toList();
          }
          
          // Apply other category-specific filters
          if (_selectedCategory == 'residential' && filters.containsKey('bedrooms')) {
            final bedroomsFilter = filters['bedrooms'] as int?;
            if (bedroomsFilter != null) {
              propertiesData = propertiesData.where((property) {
                final bedrooms = property['bedrooms'] is int ? property['bedrooms'] : 
                                 int.tryParse(property['bedrooms']?.toString() ?? '0') ?? 0;
                return bedrooms >= bedroomsFilter;
              }).toList();
            }
          }
        }
      }
      
      // Convert to Listing objects
      final listings = propertiesData.map((data) {
        final category = data['category'] ?? _selectedCategory;
        return Listing.fromJson(data, category);
      }).toList();
      
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load properties from PostgreSQL database: $e';
        _loading = false;
      });
      debugPrint('Error fetching listings from PostgreSQL database: $e');
    }
  }

  void _handleCategorySelect(String category) {
    setState(() {
      _selectedCategory = category;
      _loading = true;
    });

    // Refetch listings with the new category filter
    _fetchListings();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  void _goToNotifications() {
    // Navigate to notifications
    Navigator.pushNamed(context, '/notifications');
  }

  void _goToProfile() {
    // Navigate to profile
    Navigator.pushNamed(context, '/profile');
  }

  void _showFilterForm(String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FilterForm(
            selectedCategory: category,
            initialFilters: _categoryFilters[category] ?? {},
            onFilterApplied: (filters) {
              setState(() {
                _categoryFilters[category] = filters;
                _loading = true;
              });
              _fetchListings();
              Navigator.pop(context);
            },
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated 3D Background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2C3E50), // Deep blue
                      Color(0xFF4A5568), // Slate
                      Color(0xFF1A365D), // Navy blue
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: _DashboardBackgroundPainter(),
                  size: Size.infinite,
                ),
              );
            },
          ),
          
          // Glassmorphism overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Main content
          Column(
            children: [
              // Fixed header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Replace the broken header section (around line 1200-1250) with:
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Welcome back, ${_userData?.firstName ?? 'User'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF000080),
                              ),
                            ),
                            Row(
                              children: [
                                // Notification Icon
                                Stack(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.notifications,
                                          size: 20,
                                          color: Color(0xFF000080),
                                        ),
                                        onPressed: _goToNotifications,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF39322),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '3',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Profile Image
                                GestureDetector(
                                  onTap: _goToProfile,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFF39322),
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          _userData?.avatarUrl ??
                                              'assets/images/mipripity.png',
                                        ),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                          // Handle image loading error
                                          debugPrint('Error loading profile image: $exception');
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Category Tabs
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Residential Button - Aligns with Home
                              SizedBox(
                                width: 60,
                                child: _buildCategoryButton(
                                  'residential',
                                  'Residential',
                                  'assets/images/residential.png',
                                  Icons.home,
                                ),
                              ),
                              
                              const SizedBox(width: 6), // Matching bottom nav spacing
                              
                              // Commercial Button - Aligns with Invest
                              SizedBox(
                                width: 60,
                                child: _buildCategoryButton(
                                  'commercial',
                                  'Commercial',
                                  'assets/images/commercial.png',
                                  Icons.business,
                                ),
                              ),
                              
                              const SizedBox(width: 6), // Matching bottom nav spacing
                              
                              // Sidebar Toggle Button - Aligns with Add button
                              SizedBox(
                                width: 60,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFF39322),
                                            Color(0xFF000080)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.menu,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        onPressed: _toggleSidebar,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Menu',
                                      style: TextStyle(
                                        fontSize: 9, // Reduced from 10 to 9
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF000080),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 6), // Matching bottom nav spacing
                              
                              // Land Button - Aligns with Bid
                              SizedBox(
                                width: 60,
                                child: _buildCategoryButton(
                                  'land',
                                  'Land',
                                  'assets/images/Land.png',
                                  Icons.landscape,
                                ),
                              ),
                              
                              const SizedBox(width: 6), // Matching bottom nav spacing
                              
                              // Material Button - Aligns with Explore
                              SizedBox(
                                width: 60,
                                child: _buildCategoryButton(
                                  'material',
                                  'Material',
                                  'assets/images/Material.png',
                                  Icons.inventory,
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

              // Scrollable content - Full width with no horizontal padding
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommended Properties Section
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCategory.isNotEmpty
                                    ? '${_selectedCategory.substring(0, 1).toUpperCase()}${_selectedCategory.substring(1)} Listings'
                                    : 'Recommended For You',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_loading)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF39322),
                                  ),
                                )
                              else if (_error != null)
                                Center(
                                  child: Column(
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
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _loading = true;
                                            _error = null;
                                          });
                                          _fetchListings();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: const Color(0xFFF39322),
                                        ),
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_listings.isEmpty)
                                Center(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No ${_selectedCategory.isNotEmpty ? _selectedCategory : ''} listings found',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedCategory = '';
                                                _loading = true;
                                              });
                                              _fetchListings();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: const Color(0xFFF39322),
                                            ),
                                            child: const Text('Show All'),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Navigate to add listing
                                              Navigator.pushNamed(context, '/add');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: const Color(0xFF000080),
                                            ),
                                            child: const Text('Add Listing'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: _listings
                                      .map((listing) => LayeredListingCard(
                                            listing: listing,
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Extra space at bottom
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SharedBottomNavigation(
              activeTab: "home",
              onTabChange: (tab) {
                SharedBottomNavigation.handleNavigation(context, tab);
              },
            ),
          ),

          // Sidebar
          DashboardSidebar(
            isOpen: _sidebarOpen,
            onClose: () => setState(() => _sidebarOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
    String category,
    String label,
    String iconPath,
    IconData fallbackIcon,
  ) {
    final isSelected = _selectedCategory == category;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showFilterForm(category),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF39322) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF39322)
                    : Colors.grey[100]!,
              ),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: 24,
                    color: isSelected ? Colors.white : const Color(0xFF000080),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9, // Reduced from 10 to 9
            fontWeight: FontWeight.w500,
            color: isSelected
                ? const Color(0xFFF39322)
                : const Color(0xFF000080),
          ),
        ),
      ],
    );
  }
}