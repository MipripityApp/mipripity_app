import 'package:flutter/material.dart';

class LocationDetails extends StatefulWidget {
  final String locationId;

  const LocationDetails({
    Key? key,
    required this.locationId,
  }) : super(key: key);

  @override
  State<LocationDetails> createState() => _LocationDetailsState();
}

class _LocationDetailsState extends State<LocationDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFavorite = false;

  // Sample location data - in a real app, this would be fetched based on locationId
  late Map<String, dynamic> locationData;

  // Sample properties in this location
  final List<Map<String, dynamic>> properties = [
    {
      'id': 'p1',
      'title': '3 Bedroom Apartment',
      'type': 'Apartment',
      'price': '₦45,000,000',
      'location': 'Lekki Phase 1',
      'bedrooms': 3,
      'bathrooms': 2,
      'area': '120 sqm',
      'image': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914',
      'isVerified': true,
    },
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
      'isVerified': true,
    },
    {
      'id': 'p3',
      'title': 'Commercial Space',
      'type': 'Commercial',
      'price': '₦80,000,000',
      'location': 'Lekki Phase 1',
      'area': '200 sqm',
      'image': 'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6',
      'isVerified': false,
    },
  ];

  // Sample land listings in this location
  final List<Map<String, dynamic>> landListings = [
    {
      'id': 'l1',
      'title': 'Prime Land',
      'price': '₦25,000,000',
      'size': '500 sqm',
      'location': 'Lekki Phase 1',
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQx2LN581kRMMNSsuF3vdugokrTs1W_sn6vtg&s',
      'isVerified': true,
    },
    {
      'id': 'l2',
      'title': 'Waterfront Land',
      'price': '₦40,000,000',
      'size': '600 sqm',
      'location': 'Lekki Phase 1',
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWFmGKO8JTbeYu9fZt50EsnDvysjnF3PG9vw&s',
      'isVerified': true,
    },
  ];

  // Sample agents in this location
  final List<Map<String, dynamic>> agents = [
    {
      'id': 'a1',
      'name': 'John Okafor',
      'rating': 4.8,
      'properties': 24,
      'image': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'id': 'a2',
      'name': 'Amina Ibrahim',
      'rating': 4.7,
      'properties': 18,
      'image': 'https://randomuser.me/api/portraits/women/44.jpg',
    },
    {
      'id': 'a3',
      'name': 'David Adeyemi',
      'rating': 4.9,
      'properties': 32,
      'image': 'https://randomuser.me/api/portraits/men/22.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize location data based on ID
    // In a real app, this would be fetched from an API or database
    if (widget.locationId == '1') {
      locationData = {
        'id': '1',
        'name': 'Lekki',
        'image': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914',
        'count': 42,
        'description': 'Upscale residential area with beaches and modern developments',
        'averagePrice': '₦35,000,000',
        'priceRange': '₦15,000,000 - ₦120,000,000',
        'popularity': 'High',
        'growthRate': '12% annually',
      };
    } else if (widget.locationId == '2') {
      locationData = {
        'id': '2',
        'name': 'Ikeja',
        'image': 'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6',
        'count': 28,
        'description': 'Commercial hub and capital of Lagos State',
        'averagePrice': '₦28,000,000',
        'priceRange': '₦12,000,000 - ₦85,000,000',
        'popularity': 'Medium',
        'growthRate': '8% annually',
      };
    } else {
      // Default data for other IDs
      locationData = {
        'id': widget.locationId,
        'name': 'Lagos Area',
        'image': 'https://images.unsplash.com/photo-1613977257363-707ba9348227',
        'count': 30,
        'description': 'A vibrant area in Lagos with various property options',
        'averagePrice': '₦30,000,000',
        'priceRange': '₦10,000,000 - ₦100,000,000',
        'popularity': 'Medium',
        'growthRate': '10% annually',
      };
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    
    if (isFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${locationData['name']} added to favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void handlePropertyClick(String propertyId) {
    Navigator.pushNamed(context, '/property-details/$propertyId');
  }

  void handleLandClick(String landId) {
    Navigator.pushNamed(context, '/property-details/$landId');
  }

  void handleAgentClick(String agentId) {
    Navigator.pushNamed(context, '/agent-profile/$agentId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    locationData['image'],
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationData['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.home,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${locationData['count']} properties',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                    // Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing this location...'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Info Card
                Container(
                  margin: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${locationData['name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        locationData['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      // Market Stats
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  locationData['averagePrice'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF39322),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price Range',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  locationData['priceRange'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Popularity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  locationData['popularity'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Growth Rate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  locationData['growthRate'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
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

                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF000080),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFFF39322),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Properties'),
                      Tab(text: 'Land'),
                      Tab(text: 'Agents'),
                    ],
                  ),
                ),

                // Tab Content
                SizedBox(
                  height: 1000, // Fixed height for tab content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Properties Tab
                      _buildPropertiesTab(),
                      
                      // Land Tab
                      _buildLandTab(),
                      
                      // Agents Tab
                      _buildAgentsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to map view
          Navigator.pushNamed(context, '/map-view', arguments: {'locationId': widget.locationId});
        },
        backgroundColor: const Color.fromARGB(255, 249, 249, 251),
        icon: const Icon(Icons.map),
        label: const Text('Map View'),
      ),
    );
  }

  Widget _buildPropertiesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${properties.length} Properties',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Color(0xFF000080),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return GestureDetector(
                  onTap: () => handlePropertyClick(property['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (property['isVerified'])
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    property['location'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    property['price'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF39322),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (property.containsKey('bedrooms'))
                                        _buildFeatureChip(
                                          Icons.bed,
                                          '${property['bedrooms']}',
                                        ),
                                      if (property.containsKey('bathrooms'))
                                        _buildFeatureChip(
                                          Icons.bathtub,
                                          '${property['bathrooms']}',
                                        ),
                                      _buildFeatureChip(
                                        Icons.square_foot,
                                        property['area'],
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
        ],
      ),
    );
  }

  Widget _buildLandTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${landListings.length} Land Listings',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Color(0xFF000080),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: landListings.length,
              itemBuilder: (context, index) {
                final land = landListings[index];
                return GestureDetector(
                  onTap: () => handleLandClick(land['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                                land['image'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF000080),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Land',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (land['isVerified'])
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                land['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    land['location'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    land['price'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF39322),
                                    ),
                                  ),
                                  _buildFeatureChip(
                                    Icons.square_foot,
                                    land['size'],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Schedule visit
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Scheduling site visit...'),
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
                                      ),
                                      child: const Text('Schedule Visit'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Contact agent
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Contacting agent...'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF000080),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Contact Agent'),
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildAgentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${agents.length} Agents in ${locationData['name']}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: agents.length,
              itemBuilder: (context, index) {
                final agent = agents[index];
                return GestureDetector(
                  onTap: () => handleAgentClick(agent['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                              image: NetworkImage(agent['image']),
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
                                agent['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFFF39322),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    agent['rating'].toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.home,
                                    color: Colors.grey[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${agent['properties']} properties',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Contact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}