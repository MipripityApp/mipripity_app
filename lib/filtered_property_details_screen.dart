import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilteredPropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const FilteredPropertyDetailsScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<FilteredPropertyDetailsScreen> createState() => _FilteredPropertyDetailsScreenState();
}

class _FilteredPropertyDetailsScreenState extends State<FilteredPropertyDetailsScreen> {
  int currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Sample property data - simplified for logged out users
  late Map<String, dynamic> propertyData;

  // Sample property images
  final List<String> propertyImages = [
    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
    'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6',
    'https://images.unsplash.com/photo-1613977257363-707ba9348227',
  ];

  // Sample similar properties
  final List<Map<String, dynamic>> similarProperties = [
    {
      'id': 'p2',
      'title': 'Luxury Villa with Pool',
      'type': 'Villa',
      'price': '₦120,000,000',
      'location': 'Lekki Phase 1',
      'bedrooms': 5,
      'bathrooms': 6,
      'area': '350 sqm',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
    },
    {
      'id': 'p3',
      'title': 'Commercial Space',
      'type': 'Commercial',
      'price': '₦80,000,000',
      'location': 'Lekki Phase 1',
      'area': '200 sqm',
      'image': 'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializePropertyData();
  }

  void _initializePropertyData() {
    // Initialize property data based on ID - simplified version
    if (widget.propertyId.startsWith('p') || widget.propertyId.startsWith('r')) {
      // Regular property
      propertyData = {
        'id': widget.propertyId,
        'title': '3 Bedroom Apartment',
        'type': 'Apartment',
        'price': '₦45,000,000',
        'location': 'Lekki Phase 1',
        'address': '123 Ocean View Road, Lekki Phase 1, Lagos',
        'bedrooms': 3,
        'bathrooms': 2,
        'area': '120 sqm',
        'description': 'This beautiful 3-bedroom apartment offers stunning ocean views and modern amenities. Located in the heart of Lekki Phase 1, it features a spacious living area, modern kitchen, and balcony overlooking the Atlantic Ocean.',
        'features': [
          'Swimming Pool',
          'Gym',
          'Security',
          '24/7 Electricity',
          'Parking Space',
          'Air Conditioning',
        ],
        'isVerified': true,
        'yearBuilt': '2020',
        'propertyID': 'LK-${widget.propertyId}',
        'category': 'residential',
      };
    } else if (widget.propertyId.startsWith('l')) {
      // Land property
      propertyData = {
        'id': widget.propertyId,
        'title': 'Prime Land in Lekki Phase 1',
        'type': 'Land',
        'price': '₦25,000,000',
        'location': 'Lekki Phase 1',
        'address': 'Plot 45, Ocean View Estate, Lekki Phase 1, Lagos',
        'area': '500 sqm',
        'description': 'Prime land for sale in the prestigious Lekki Phase 1 area. This plot is located in a secure estate with excellent infrastructure including paved roads, drainage systems, and street lighting.',
        'features': [
          'C of O Document',
          'Dry Land',
          'Gated Estate',
          'Good Road Network',
          'Electricity',
        ],
        'isVerified': true,
        'propertyID': 'LL-${widget.propertyId}',
        'category': 'land',
      };
    } else if (widget.propertyId.startsWith('c')) {
      // Commercial property
      propertyData = {
        'id': widget.propertyId,
        'title': 'Office Space in Victoria Island',
        'type': 'Commercial',
        'price': '₦75,000,000',
        'location': 'Victoria Island',
        'address': '45 Adeola Odeku Street, Victoria Island, Lagos',
        'area': '250 sqm',
        'description': 'Prime office space in the heart of Victoria Island business district. This modern office features open floor plans, meeting rooms, and reception area.',
        'features': [
          'Reception Area',
          'Meeting Rooms',
          'High-speed Internet',
          '24/7 Security',
          'Backup Power',
          'Parking Space',
        ],
        'isVerified': true,
        'yearBuilt': '2018',
        'propertyID': 'VC-${widget.propertyId}',
        'category': 'commercial',
      };
    } else if (widget.propertyId.startsWith('m')) {
      // Material property
      propertyData = {
        'id': widget.propertyId,
        'title': 'Premium Building Materials',
        'type': 'Material',
        'price': '₦2,500,000',
        'location': 'Ikeja',
        'address': '78 Construction Avenue, Ikeja, Lagos',
        'area': 'N/A',
        'description': 'High-quality building materials including cement, tiles, and roofing materials. All materials are brand new and from top manufacturers.',
        'features': [
          'Brand New',
          'Top Quality',
          'Bulk Discounts',
          'Delivery Available',
          'Warranty Included',
        ],
        'isVerified': true,
        'propertyID': 'MT-${widget.propertyId}',
        'category': 'material',
        'quantity': '500 units',
        'condition': 'New',
      };
    } else {
      // Default property data
      propertyData = {
        'id': widget.propertyId,
        'title': 'Property in Lagos',
        'type': 'Property',
        'price': '₦30,000,000',
        'location': 'Lagos',
        'address': 'Lagos, Nigeria',
        'area': '200 sqm',
        'description': 'A beautiful property in Lagos with modern amenities.',
        'features': [
          'Security',
          '24/7 Electricity',
          'Parking Space',
        ],
        'isVerified': false,
        'propertyID': 'PR-${widget.propertyId}',
        'category': 'residential',
      };
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void handleSimilarPropertyClick(String propertyId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredPropertyDetailsScreen(propertyId: propertyId),
      ),
    );
  }

  void _showLoginPrompt(String action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildLoginPromptSheet(action),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Slider
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image Slider
                  PageView.builder(
                    controller: _pageController,
                    itemCount: propertyImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        propertyImages[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  // Image Indicator
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        propertyImages.length,
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
                  // Image Counter
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
                        '${currentImageIndex + 1}/${propertyImages.length}',
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
                  icon: const Icon(Icons.share, color: Color(0xFF000080)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propertyData['title'],
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
                                    propertyData['address'],
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
                          Text(
                            propertyData['price'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF39322),
                            ),
                          ),
                          if (propertyData['type'] != 'Land')
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

                  // Property Features
                  if (propertyData['type'] != 'Land')
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
                          if (propertyData.containsKey('bedrooms'))
                            _buildFeatureItem(
                              Icons.king_bed_outlined,
                              '${propertyData['bedrooms']} Beds',
                            ),
                          if (propertyData.containsKey('bathrooms'))
                            _buildFeatureItem(
                              Icons.bathtub_outlined,
                              '${propertyData['bathrooms']} Baths',
                            ),
                          _buildFeatureItem(
                            Icons.square_foot,
                            propertyData['area'],
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
                            propertyData['area'],
                          ),
                          _buildFeatureItem(
                            Icons.description_outlined,
                            'C of O',
                          ),
                          _buildFeatureItem(
                            Icons.location_city,
                            'Residential',
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Description
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
                    propertyData['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Features
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
                    children: List.generate(
                      propertyData['features'].length,
                      (index) => Container(
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
                          propertyData['features'][index],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Basic Property Details
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
                        _buildPropertyDetailRow('Property ID', propertyData['propertyID']),
                        const Divider(height: 24),
                        _buildPropertyDetailRow('Property Type', propertyData['type']),
                        const Divider(height: 24),
                        _buildPropertyDetailRow('Location', propertyData['location']),
                        if (propertyData.containsKey('yearBuilt')) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Year Built', propertyData['yearBuilt']),
                        ],
                        if (propertyData.containsKey('quantity')) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Quantity', propertyData['quantity']),
                        ],
                        if (propertyData.containsKey('condition')) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Condition', propertyData['condition']),
                        ],
                        const Divider(height: 24),
                        _buildPropertyDetailRow('Status', propertyData['isVerified'] ? 'Verified' : 'Unverified'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Similar Properties
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
                        return GestureDetector(
                          onTap: () => handleSimilarPropertyClick(property['id']),
                          child: Container(
                            width: 200,
                            margin: EdgeInsets.only(
                              right: index != similarProperties.length - 1 ? 16 : 0,
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
                                      child: Image.network(
                                        property['image'],
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
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          property['type'],
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property['title'],
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
                                            property['location'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            property['price'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFF39322),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (property.containsKey('bedrooms'))
                                                _buildSmallFeatureChip(
                                                  Icons.bed,
                                                  '${property['bedrooms']}',
                                                ),
                                              if (property.containsKey('bathrooms'))
                                                _buildSmallFeatureChip(
                                                  Icons.bathtub,
                                                  '${property['bathrooms']}',
                                                ),
                                            ],
                                          ),
                                        ],
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
                  const SizedBox(height: 100), // Space for bottom buttons
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
                onPressed: () => _showLoginPrompt('schedule visit'),
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
                onPressed: () => _showLoginPrompt('contact agent'),
                style: ElevatedButton.styleFrom(
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

  Widget _buildSmallFeatureChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 10,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPromptSheet(String action) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF000080).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 40,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Login Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please login or create an account to $action and access more features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to login screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to login...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to signup screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Redirecting to signup...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF000080),
                side: const BorderSide(color: Color(0xFF000080)),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
