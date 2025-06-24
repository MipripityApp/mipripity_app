import 'package:flutter/material.dart';
import 'dart:math';

class AgentProfileScreen extends StatefulWidget {
  final String agentId;

  const AgentProfileScreen({
    Key? key,
    required this.agentId,
  }) : super(key: key);

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;
  
  // Sample agent data - in a real app, this would be fetched based on agentId
  late Map<String, dynamic> agentData;
  List<Map<String, dynamic>> agentListings = [];
  List<Map<String, dynamic>> agentReviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAgentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAgentData() {
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          // Sample agent data based on agentId
          agentData = {
            'id': widget.agentId,
            'name': 'John Okafor',
            'title': 'Senior Real Estate Agent',
            'company': 'Premium Properties Ltd',
            'rating': 4.8,
            'totalReviews': 127,
            'totalListings': 24,
            'activeListing': 18,
            'soldProperties': 156,
            'experience': '5 years',
            'joinDate': 'January 2019',
            'image': 'https://randomuser.me/api/portraits/men/32.jpg',
            'coverImage': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa',
            'phone': '+234 801 234 5678',
            'email': 'john.okafor@premiumproperties.com',
            'whatsapp': '+234 801 234 5678',
            'location': 'Lagos, Nigeria',
            'bio': 'Experienced real estate professional with over 5 years in the Lagos property market. Specializing in residential and commercial properties in prime locations. Committed to helping clients find their perfect property investment.',
            'specializations': [
              'Residential Properties',
              'Commercial Spaces',
              'Land Development',
              'Property Investment',
            ],
            'languages': ['English', 'Yoruba', 'Igbo'],
            'certifications': [
              'Licensed Real Estate Agent',
              'Property Valuation Certificate',
              'Real Estate Investment Advisor',
            ],
            'socialMedia': {
              'linkedin': 'john-okafor-properties',
              'instagram': '@johnokafor_properties',
              'facebook': 'John Okafor Properties',
            },
            'workingHours': {
              'monday': '9:00 AM - 6:00 PM',
              'tuesday': '9:00 AM - 6:00 PM',
              'wednesday': '9:00 AM - 6:00 PM',
              'thursday': '9:00 AM - 6:00 PM',
              'friday': '9:00 AM - 6:00 PM',
              'saturday': '10:00 AM - 4:00 PM',
              'sunday': 'Closed',
            },
            'responseTime': 'Usually responds within 2 hours',
            'isVerified': true,
            'isOnline': true,
          };

          // Sample listings
          agentListings = [
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
              'status': 'Available',
              'featured': true,
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
              'status': 'Available',
              'featured': false,
            },
            {
              'id': 'p3',
              'title': 'Commercial Office Space',
              'type': 'Commercial',
              'price': '₦80,000,000',
              'location': 'Victoria Island',
              'area': '200 sqm',
              'image': 'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6',
              'status': 'Sold',
              'featured': false,
            },
            {
              'id': 'p4',
              'title': 'Prime Land for Development',
              'type': 'Land',
              'price': '₦25,000,000',
              'location': 'Ajah',
              'area': '500 sqm',
              'image': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef',
              'status': 'Available',
              'featured': true,
            },
          ];

          // Sample reviews
          agentReviews = [
            {
              'id': 'r1',
              'clientName': 'Sarah Johnson',
              'clientImage': 'https://randomuser.me/api/portraits/women/44.jpg',
              'rating': 5,
              'date': '2 weeks ago',
              'review': 'John helped me find the perfect apartment in Lekki. His professionalism and knowledge of the market made the process smooth and stress-free. Highly recommended!',
              'propertyType': 'Apartment Purchase',
            },
            {
              'id': 'r2',
              'clientName': 'Michael Chen',
              'clientImage': 'https://randomuser.me/api/portraits/men/22.jpg',
              'rating': 5,
              'date': '1 month ago',
              'review': 'Excellent service! John was very responsive and showed me several great options. He negotiated a great deal for my commercial space.',
              'propertyType': 'Commercial Lease',
            },
            {
              'id': 'r3',
              'clientName': 'Adaora Okonkwo',
              'clientImage': 'https://randomuser.me/api/portraits/women/68.jpg',
              'rating': 4,
              'date': '2 months ago',
              'review': 'Professional and knowledgeable agent. John provided valuable insights about the property market and helped me make an informed decision.',
              'propertyType': 'Land Purchase',
            },
            {
              'id': 'r4',
              'clientName': 'David Williams',
              'clientImage': 'https://randomuser.me/api/portraits/men/55.jpg',
              'rating': 5,
              'date': '3 months ago',
              'review': 'Outstanding service from start to finish. John went above and beyond to ensure I found exactly what I was looking for. Will definitely work with him again.',
              'propertyType': 'Villa Purchase',
            },
          ];

          _loading = false;
        });
      }
    });
  }

  void _toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFollowing 
            ? 'You are now following ${agentData['name']}'
            : 'You unfollowed ${agentData['name']}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleContactAgent(String method) {
    String message = '';
    switch (method) {
      case 'call':
        message = 'Calling ${agentData['name']}...';
        break;
      case 'message':
        message = 'Opening chat with ${agentData['name']}...';
        break;
      case 'email':
        message = 'Composing email to ${agentData['name']}...';
        break;
      case 'whatsapp':
        message = 'Opening WhatsApp chat with ${agentData['name']}...';
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePropertyClick(String propertyId) {
    Navigator.pushNamed(context, '/property-details/$propertyId');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF39322),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
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
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF000080)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing agent profile...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Cover Image
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(agentData['coverImage']),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Profile Info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Profile Picture
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(agentData['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (agentData['isOnline'])
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              if (agentData['isVerified'])
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF39322),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          // Name and Title
                          Text(
                            agentData['name'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000080),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            agentData['title'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            agentData['company'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFF39322),
                              fontWeight: FontWeight.w500,
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

          // Stats and Actions
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        agentData['rating'].toString(),
                        'Rating',
                        Icons.star,
                        const Color(0xFFF39322),
                      ),
                      _buildStatItem(
                        agentData['totalListings'].toString(),
                        'Listings',
                        Icons.home,
                        const Color(0xFF000080),
                      ),
                      _buildStatItem(
                        agentData['soldProperties'].toString(),
                        'Sold',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        agentData['experience'],
                        'Experience',
                        Icons.work,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleContactAgent('message'),
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('Message'),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(
                            isFollowing ? Icons.person_remove : Icons.person_add,
                            size: 18,
                          ),
                          label: Text(isFollowing ? 'Unfollow' : 'Follow'),
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
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF000080),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFF39322),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Listings'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildListingsTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            _buildQuickActionButton(
              Icons.phone,
              'Call',
              () => _handleContactAgent('call'),
            ),
            const SizedBox(width: 10),
            _buildQuickActionButton(
              Icons.email,
              'Email',
              () => _handleContactAgent('email'),
            ),
            const SizedBox(width: 10),
            _buildQuickActionButton(
              Icons.chat,
              'WhatsApp',
              () => _handleContactAgent('whatsapp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000080),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF000080).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFF000080),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF000080),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          _buildSectionCard(
            'About',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentData['bio'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      agentData['location'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Joined ${agentData['joinDate']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      agentData['responseTime'],
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

          const SizedBox(height: 20),

          // Specializations
          _buildSectionCard(
            'Specializations',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                agentData['specializations'].length,
                (index) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39322).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF39322).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    agentData['specializations'][index],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF39322),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Languages
          _buildSectionCard(
            'Languages',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                agentData['languages'].length,
                (index) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    agentData['languages'][index],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF000080),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Certifications
          _buildSectionCard(
            'Certifications',
            Column(
              children: List.generate(
                agentData['certifications'].length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          agentData['certifications'][index],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Working Hours
          _buildSectionCard(
            'Working Hours',
            Column(
              children: agentData['workingHours'].entries.map<Widget>((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 100), // Space for bottom sheet
        ],
      ),
    );
  }

  Widget _buildListingsTab() {
    final availableListings = agentListings.where((listing) => listing['status'] == 'Available').toList();
    final soldListings = agentListings.where((listing) => listing['status'] == 'Sold').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs
          Row(
            children: [
              _buildFilterChip('All (${agentListings.length})', true),
              const SizedBox(width: 10),
              _buildFilterChip('Available (${availableListings.length})', false),
              const SizedBox(width: 10),
              _buildFilterChip('Sold (${soldListings.length})', false),
            ],
          ),
          
          const SizedBox(height: 20),

          // Listings Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            itemCount: agentListings.length,
            itemBuilder: (context, index) {
              final listing = agentListings[index];
              return _buildListingCard(listing);
            },
          ),

          const SizedBox(height: 100), // Space for bottom sheet
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviews Summary
          Container(
            padding: const EdgeInsets.all(20),
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
                Column(
                  children: [
                    Text(
                      agentData['rating'].toString(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < agentData['rating'].floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFF39322),
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${agentData['totalReviews']} reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final stars = 5 - index;
                      final percentage = (Random().nextDouble() * 0.8 + 0.1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              '$stars',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFF39322),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF39322),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Individual Reviews
          Column(
            children: List.generate(
              agentReviews.length,
              (index) => _buildReviewCard(agentReviews[index]),
            ),
          ),

          const SizedBox(height: 100), // Space for bottom sheet
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 15),
          content,
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF000080) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF000080) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () => _handlePropertyClick(listing['id']),
      child: Container(
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
                    listing['image'],
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
                      color: listing['status'] == 'Available'
                          ? Colors.green
                          : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (listing['featured'])
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39322),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
                      ),
                      maxLines: 2,
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
                        Expanded(
                          child: Text(
                            listing['location'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      listing['price'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF39322),
                      ),
                    ),
                    if (listing.containsKey('bedrooms'))
                      Row(
                        children: [
                          _buildSmallFeature(Icons.bed, '${listing['bedrooms']}'),
                          const SizedBox(width: 8),
                          _buildSmallFeature(Icons.bathtub, '${listing['bathrooms']}'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(review['clientImage']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['clientName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFF39322),
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['review'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF000080).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              review['propertyType'],
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF000080),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}