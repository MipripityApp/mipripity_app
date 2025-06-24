import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/currency_formatter.dart';

// Format price to Nigerian Naira with comma separators
String formatFullPrice(num amount) {
  return CurrencyFormatter.formatNaira(amount, useAbbreviations: false);
}

// Format price to Nigerian Naira with abbreviations
String formatPrice(num amount) {
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
    useAbbreviations: false,
  );
}

class PropertyDetails extends StatefulWidget {
  final String propertyId;

  const PropertyDetails({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetails> createState() => _PropertyDetailsState();
}

class _PropertyDetailsState extends State<PropertyDetails> {
  bool isFavorite = false;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();

  Map<String, dynamic>? propertyData;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> similarProperties = [];

  @override
  void initState() {
    super.initState();
    _fetchPropertyData();
  }

  Future<void> _fetchPropertyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/properties/${widget.propertyId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          propertyData = data;
          _isLoading = false;
        });
        _fetchSimilarProperties(data['category']);
      } else {
        setState(() {
          _error = 'Property not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching property: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSimilarProperties(String? category) async {
    if (category == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/properties?category=$category'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          similarProperties = data
              .where((p) => p['property_id'].toString() != widget.propertyId)
              .take(2)
              .map<Map<String, dynamic>>((p) => p as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (_) {}
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    if (isFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${propertyData?['title']} added to favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void handleSimilarPropertyClick(String propertyId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetails(propertyId: propertyId),
      ),
    );
  }

  // Helper to parse features from string or list
  List<String> _parseFeatures(dynamic features) {
    if (features == null) return [];
    if (features is List) {
      return features.map((e) => e.toString()).toList();
    }
    if (features is String) {
      try {
        final decoded = jsonDecode(features);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return features.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Property Details'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000080),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF39322),
          ),
        ),
      );
    }

    if (propertyData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Property Details'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000080),
          elevation: 0,
        ),
        body: Center(
          child: Text(_error ?? 'Property not found'),
        ),
      );
    }

    final List<String> images = (propertyData?['images'] is List)
        ? List<String>.from(propertyData!['images'])
        : ['assets/images/residential1.jpg'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final img = images[index];
                      return img.startsWith('http')
                          ? Image.network(img, fit: BoxFit.cover)
                          : Image.asset(img, fit: BoxFit.cover);
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentImageIndex == index
                                ? const Color(0xFFF39322)
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : const Color(0xFF000080),
                  ),
                  onPressed: toggleFavorite,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF000080)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing this property...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propertyData?['title'] ?? 'Untitled Property',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    propertyData?['address'] ??
                                        propertyData?['location'] ??
                                        'Unknown Location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          getNairaRichText(
                            propertyData != null && propertyData!['price'] is num 
                                ? propertyData!['price'] as num
                                : ((propertyData != null && propertyData!['price'] != null)
                                    ? num.tryParse(propertyData!['price'].toString()) ?? 0
                                    : 0),
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            textColor: const Color(0xFFF39322),
                          ),
                          if (propertyData?['category'] != 'land')
                            Text(
                              'Negotiable',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (propertyData?['category'] != 'land')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureItem(
                            Icons.king_bed_outlined,
                            '${propertyData?['bedrooms'] ?? 0} Beds',
                          ),
                          _buildFeatureItem(
                            Icons.bathtub_outlined,
                            '${propertyData?['bathrooms'] ?? 0} Baths',
                          ),
                          _buildFeatureItem(
                            Icons.square_foot,
                            propertyData?['area'] ?? 'N/A',
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureItem(
                            Icons.square_foot,
                            propertyData?['area'] ??
                                propertyData?['land_size']?.toString() ??
                                'N/A',
                          ),
                          _buildFeatureItem(
                            Icons.description_outlined,
                            propertyData?['land_title'] ?? 'C of O',
                          ),
                          _buildFeatureItem(
                            Icons.location_city,
                            propertyData?['category'] ?? 'Residential',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    propertyData?['description'] ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _parseFeatures(propertyData?['features']).map((feature) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Property Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      children: [
                        _buildPropertyDetailRow('Property ID',
                            propertyData?['property_id'] ?? 'N/A'),
                        const Divider(height: 24),
                        _buildPropertyDetailRow('Property Type',
                            propertyData?['category'] ?? 'N/A'),
                        const Divider(height: 24),
                        _buildPropertyDetailRow(
                            'Location', propertyData?['location'] ?? 'N/A'),
                        if (propertyData?.containsKey('year_built') ?? false) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Year Built',
                              propertyData?['year_built'] ?? 'N/A'),
                        ],
                        if (propertyData?.containsKey('quantity') ?? false) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Quantity',
                              propertyData?['quantity']?.toString() ?? 'N/A'),
                        ],
                        if (propertyData?.containsKey('condition') ?? false) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Condition',
                              propertyData?['condition'] ?? 'N/A'),
                        ],
                        const Divider(height: 24),
                        _buildPropertyDetailRow(
                            'Status',
                            (propertyData?['is_verified'] == true)
                                ? 'Verified'
                                : 'Unverified'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Listed By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF39322),
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: (propertyData?['lister_dp'] != null &&
                                      propertyData!['lister_dp']
                                          .toString()
                                          .startsWith('http'))
                                  ? NetworkImage(propertyData!['lister_dp'])
                                  : const AssetImage(
                                          'assets/images/mipripity.png')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                propertyData?['lister_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                propertyData?['lister_email'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Similar Properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarProperties.length,
                      itemBuilder: (context, index) {
                        final property = similarProperties[index];
                        final simImages = (property['images'] is List)
                            ? List<String>.from(property['images'])
                            : ['assets/images/residential1.jpg'];
                        return GestureDetector(
                          onTap: () => handleSimilarPropertyClick(
                              property['property_id'].toString()),
                          child: Container(
                            width: 200,
                            margin: EdgeInsets.only(
                              right: index != similarProperties.length - 1
                                  ? 16
                                  : 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: simImages[0].startsWith('http')
                                          ? Image.network(
                                              simImages[0],
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              simImages[0],
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF000080),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          property['category'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF000080),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            property['location'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      getNairaRichText(
                                        property['price'] is num
                                            ? property['price'] as num
                                            : (property['price'] != null
                                                ? num.tryParse(property['price'].toString()) ?? 0
                                                : 0),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        textColor: const Color(0xFFF39322),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule Visit feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF000080),
                  side: const BorderSide(color: Color(0xFF000080)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Schedule Visit'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact Agent feature coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Contact Agent'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF39322).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF39322),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}