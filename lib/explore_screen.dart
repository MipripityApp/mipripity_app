import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'api/property_api.dart';
import 'api/poll_property_api.dart';
import 'shared/bottom_navigation.dart';
import 'utils/currency_formatter.dart';
import 'poll_property_screen.dart';

// Listing model with immutable properties to avoid state issues
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

  const Listing({
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
}

// Area/location model
class Area {
  final String id;
  final String name;
  final String image;
  final int count;
  final String description;
  
  const Area({
    required this.id,
    required this.name,
    required this.image,
    required this.count,
    required this.description,
  });
}

// Skill worker model
class SkillWorker {
  final String id;
  final String name;
  final String profession;
  final double rating;
  final String experience;
  final String image;
  
  const SkillWorker({
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.experience,
    required this.image,
  });
}

// Format price to Nigerian Naira
String formatPrice(num amount) {
  return CurrencyFormatter.formatNaira(amount, useAbbreviations: true);
}

// Format price to Nigerian Naira without abbreviations
String formatFullPrice(num amount) {
  return CurrencyFormatter.formatNaira(amount, useAbbreviations: false);
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

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with AutomaticKeepAliveClientMixin {
  // Keep the page state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  // Loading and error state variables
  bool _isLoading = true;
  bool _isPollPropertiesLoading = true;
  String? _error;
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  
  // Data lists with proper initialization
  List<Area> popularAreas = [];
  List<Area> moreAreas = [];
  List<Listing> landListings = [];
  List<Listing> materialListings = [];
  List<SkillWorker> skillWorkersListings = [];
  List<PollProperty> pollProperties = [];
  
  // Refresh controller
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchPollProperties();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Fetch poll properties
  Future<void> _fetchPollProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isPollPropertiesLoading = true;
    });
    
    try {
      final properties = await PollPropertyApi.getPollProperties();
      
      if (mounted) {
        setState(() {
          pollProperties = properties;
          _isPollPropertiesLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching poll properties: $e');
      if (mounted) {
        setState(() {
          _isPollPropertiesLoading = false;
        });
      }
    }
  }
  
  // Method to fetch all data from database with improved error handling and fallbacks
  Future<void> _fetchData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fetch properties to extract location data with error handling
      List<Map<String, dynamic>> allProperties = [];
      try {
        allProperties = await PropertyApi.getAllProperties();
      } catch (e) {
        print('Error fetching all properties: $e');
        // Continue with empty list if this fails, other sections can still load
      }
      
      // Process location data from properties
      if (allProperties.isNotEmpty) {
        try {
          _processLocationData(allProperties);
        } catch (e) {
          print('Error processing location data: $e');
          // Set empty areas with default values if processing fails
          popularAreas = [];
          moreAreas = [];
        }
      }
      
      // Fetch land listings with dedicated error handling
      try {
        final landData = await PropertyApi.getPropertiesByCategory('land');
        landListings = landData.map((data) => Listing.fromJson(data, 'land')).toList();
      } catch (e) {
        print('Error fetching land properties: $e');
        landListings = []; // Set empty list on error
      }
      
      // Fetch material listings with dedicated error handling
      try {
        final materialData = await PropertyApi.getPropertiesByCategory('material');
        materialListings = materialData.map((data) => Listing.fromJson(data, 'material')).toList();
      } catch (e) {
        print('Error fetching material properties: $e');
        materialListings = []; // Set empty list on error
      }
      
      // For skilled workers, we'll use hardcoded data as there seems to be no API for this
      _loadSkillWorkers();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
      print('Error in _fetchData: $e');
    }
  }
  
  // Helper method to process location data from properties
  void _processLocationData(List<Map<String, dynamic>> properties) {
    // Extract unique locations and count properties per location
    final Map<String, Map<String, dynamic>> locationCounts = {};
    
    for (final property in properties) {
      final location = property['location'] ?? '';
      final List<String> locationParts = location.split(',');
      final String city = locationParts.isNotEmpty ? locationParts[0].trim() : '';
      
      if (city.isNotEmpty) {
        if (!locationCounts.containsKey(city)) {
          // Get image from property or use default
          String imageUrl = 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914';
          
          if (property['images'] != null) {
            if (property['images'] is List && property['images'].isNotEmpty) {
              final firstImage = property['images'][0];
              if (firstImage is String && firstImage.startsWith('http')) {
                imageUrl = firstImage;
              }
            } else if (property['images'] is String) {
              try {
                final List<dynamic> images = jsonDecode(property['images']);
                if (images.isNotEmpty && images[0] is String && images[0].startsWith('http')) {
                  imageUrl = images[0];
                }
              } catch (e) {
                // If parsing fails, check if the string itself is a URL
                final String imageStr = property['images'].toString();
                if (imageStr.startsWith('http')) {
                  imageUrl = imageStr;
                }
              }
            }
          }
          
          locationCounts[city] = {
            'count': 1,
            'image': imageUrl,
          };
        } else {
          locationCounts[city]!['count'] = locationCounts[city]!['count'] + 1;
        }
      }
    }
    
    // Convert to Area objects
    final List<Area> areas = locationCounts.entries.map((entry) {
      return Area(
        id: entry.key.hashCode.toString(),
        name: entry.key,
        image: entry.value['image'],
        count: entry.value['count'],
        description: 'Properties in ${entry.key}',
      );
    }).toList();
    
    // Sort by count
    areas.sort((a, b) => b.count.compareTo(a.count));
    
    // Split into popular and more areas
    setState(() {
      popularAreas = areas.take(4).toList();
      moreAreas = areas.length > 4 ? areas.skip(4).take(6).toList() : [];
    });
  }
  
  // Helper method to load skill workers (mock data for now)
  void _loadSkillWorkers() {
    // This could be replaced with a database call in the future
    final skillWorkers = [
      const SkillWorker(
        id: 'sw1',
        name: 'John Okafor',
        profession: 'Master Plumber',
        rating: 4.8,
        experience: '10 years',
        image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQGb5Sy4wr_fNuw5m5UKxEOIxLsdG4yEwlwEQ&s',
      ),
      const SkillWorker(
        id: 'sw2',
        name: 'Amina Ibrahim',
        profession: 'Electrician',
        rating: 4.7,
        experience: '8 years',
        image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwW2BbRZXaAKPt019qQASneiNaTFLpHJ8Ebg&s',
      ),
      const SkillWorker(
        id: 'sw3',
        name: 'David Adeyemi',
        profession: 'Carpenter',
        rating: 4.9,
        experience: '15 years',
        image: 'https://www.liveabout.com/thmb/OBdAQfqD-FL1YzYRCIMuXqTcu8Y=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/GettyImages-508481761-5760b7105f9b58f22e360f07.jpg',
      ),
    ];
    
    setState(() {
      skillWorkersListings = skillWorkers;
    });
  }

  // Navigation handlers with unique keys for each screen
  void handleLocationClick(String locationId) {
    Navigator.pushNamed(context, '/explore/$locationId');
  }

  void handlePropertyClick(String propertyId) {
    Navigator.pushNamed(context, '/property-details/$propertyId');
  }

  void handleMaterialClick(String materialId) {
    Navigator.pushNamed(context, '/material/$materialId');
  }

  void handleWorkerClick(String workerId) {
    Navigator.pushNamed(context, '/skill-workers/$workerId');
  }
  
  void handlePollPropertyClick(String pollPropertyId) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PollPropertyScreen(
          pollPropertyId: pollPropertyId,
        ),
      ),
    );
  }

  void handleNearbyClick() {
    Navigator.pushNamed(context, '/explore/nearby');
  }

  void handleTrendingClick() {
    Navigator.pushNamed(context, '/explore/trending');
  }

  void handleMapViewClick() {
    Navigator.pushNamed(context, '/map-view');
  }

  void handleViewAllLand() {
    Navigator.pushNamed(context, '/land/all');
  }

  void handleViewAllMaterials() {
    Navigator.pushNamed(context, '/material/all');
  }

  void handleViewAllSkillWorkers() {
    Navigator.pushNamed(context, '/skill-workers/all');
  }

  void handleSearch(String query) {
    if (query.isEmpty) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Navigate to search results
    Navigator.pushNamed(
      context, 
      '/search-results',
      arguments: {'query': query},
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _fetchData,
        color: const Color(0xFF000080),
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        child: Stack(
          children: [
            // Main Content
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                _buildAppBar(),
                
                // Main content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Quick Access Buttons
                      _buildQuickAccessButtons(),
                      const SizedBox(height: 24),

                      // Poll Properties
                      _isPollPropertiesLoading
                          ? _buildPollPropertiesShimmer()
                          : _buildPollProperties(),
                      const SizedBox(height: 32),
                      
                      // Popular Areas
                      _isLoading
                          ? _buildPopularAreasShimmer()
                          : _buildPopularAreas(),
                      const SizedBox(height: 32),

                      // Land Listings
                      _isLoading
                          ? _buildLandListingsShimmer()
                          : _buildLandListings(),
                      const SizedBox(height: 32),

                      // Building Materials
                      _isLoading
                          ? _buildMaterialListingsShimmer()
                          : _buildMaterialListings(),
                      const SizedBox(height: 32),

                      // Skilled Workers
                      _isLoading
                          ? _buildSkillWorkersShimmer()
                          : _buildSkillWorkers(),
                      const SizedBox(height: 32),

                      // More Areas
                      _isLoading
                          ? _buildMoreAreasShimmer()
                          : _buildMoreAreas(),
                      
                      // Extra space at bottom
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),

            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavigation(
                key: const ValueKey('explore_bottom_nav'),
                activeTab: "explore",
                onTabChange: (tab) {
                  SharedBottomNavigation.handleNavigation(context, tab);
                },
              ),
            ),
            
            // Error overlay if needed
            if (_error != null && !_isLoading) _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }

  // Custom App Bar with search functionality
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      expandedHeight: 150.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and notification/profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      Text(
                        'Discover properties by location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification Icon with badge
                      Stack(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                color: Color(0xFF000080),
                                size: 20,
                              ),
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
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Profile Image
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Hero(
                          tag: 'profile_image',
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://randomuser.me/api/portraits/men/32.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search locations or properties',
                          hintStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: handleSearch,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/filters'),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39322).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: Color(0xFFF39322),
                          size: 18,
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
    );
  }

  // Quick Access Buttons with horizontal scroll
  Widget _buildQuickAccessButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Nearby Button
          _buildQuickAccessButton(
            icon: Icons.navigation_outlined,
            label: 'Nearby',
            onTap: handleNearbyClick,
          ),
          const SizedBox(width: 12),

          // Trending Button
          _buildQuickAccessButton(
            icon: Icons.trending_up,
            label: 'Trending',
            onTap: handleTrendingClick,
          ),
          const SizedBox(width: 12),

          // Map View Button
          _buildQuickAccessButton(
            icon: Icons.place_outlined,
            label: 'Map View',
            onTap: handleMapViewClick,
          ),
          const SizedBox(width: 12),
          
          // New Feature: Price Alert
          _buildQuickAccessButton(
            icon: Icons.notifications_active_outlined,
            label: 'Price Alerts',
            onTap: () => Navigator.pushNamed(context, '/price-alerts'),
          ),
          const SizedBox(width: 12),
          
          // New Feature: Saved Properties
          _buildQuickAccessButton(
            icon: Icons.bookmark_border,
            label: 'Saved',
            onTap: () => Navigator.pushNamed(context, '/saved-properties'),
          ),
        ],
      ),
    );
  }
  
  // Individual quick access button
  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFF39322).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFF39322),
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000080),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Poll Properties Section
  Widget _buildPollProperties() {
    if (pollProperties.isEmpty) {
      return const SizedBox(); // Don't show section if empty
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Poll Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
            GestureDetector(
              onTap: () {
                // View all poll properties (could navigate to a dedicated screen)
                if (pollProperties.isNotEmpty) {
                  handlePollPropertyClick(pollProperties.first.id);
                }
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFF39322),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pollProperties.length,
            itemBuilder: (context, index) {
              final property = pollProperties[index];
              return _buildPollPropertyCard(property, index);
            },
          ),
        ),
      ],
    );
  }
  
  // Poll Property Card
  Widget _buildPollPropertyCard(PollProperty property, int index) {
    // Calculate total votes for display
    final int totalVotes = property.suggestions.fold(
      0, (sum, suggestion) => sum + suggestion.votes);
    
    return GestureDetector(
      onTap: () => handlePollPropertyClick(property.id),
      child: Container(
        width: 280,
        margin: EdgeInsets.only(right: index != pollProperties.length - 1 ? 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: property.imageUrl.startsWith('http')
                      ? Image.network(
                          property.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          property.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Poll',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39322),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalVotes votes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Property Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
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
                  const SizedBox(height: 8),
                  const Text(
                    'Top suggestions:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: property.suggestions.length.clamp(0, 3), // Show max 3 suggestions
                      itemBuilder: (context, i) {
                        final suggestion = property.suggestions[i];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF000080).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                suggestion.suggestion,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF39322),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${suggestion.votes}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Poll Properties Shimmer
  Widget _buildPollPropertiesShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 280,
                  margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Popular Areas Grid
  Widget _buildPopularAreas() {
    if (popularAreas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.location_city,
        message: 'No popular areas found',
        actionLabel: 'Retry',
        onAction: _fetchData,
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Areas in Lagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: popularAreas.length,
          itemBuilder: (context, index) {
            final area = popularAreas[index];
            return _buildAreaCard(area);
          },
        ),
      ],
    );
  }
  
  // Area card with animation
  Widget _buildAreaCard(Area area) {
    return Hero(
      tag: 'area_${area.id}',
      child: GestureDetector(
        onTap: () => handleLocationClick(area.id),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
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
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      area.image,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 160,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF000080),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                          Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  area.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${area.count} properties',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  area.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Land Listings Horizontal Scroll
  Widget _buildLandListings() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Land for Sale',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
            GestureDetector(
              onTap: handleViewAllLand,
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFF39322),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        landListings.isEmpty
            ? _buildEmptyState(
                icon: Icons.landscape,
                message: 'No land listings available',
                actionLabel: 'Refresh',
                onAction: _fetchData,
              )
            : SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: landListings.length,
                  itemBuilder: (context, index) {
                    final land = landListings[index];
                    return _buildLandCard(land, index);
                  },
                ),
              ),
      ],
    );
  }
  
  // Land card with animation
  Widget _buildLandCard(Listing land, int index) {
    return Hero(
      tag: 'land_${land.id}',
      child: GestureDetector(
        onTap: () => handlePropertyClick(land.id),
        child: Container(
          width: 200,
          margin: EdgeInsets.only(
            right: index != landListings.length - 1 ? 16 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
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
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      land.listingImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Land',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
                      land.title,
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
                        Icon(
                          Icons.place_outlined,
                          color: Colors.grey[500],
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            land.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                            getNairaRichText(
                              land.price,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              textColor: const Color(0xFFF39322),
                            ),
                        Text(
                          '${land.landSize != null ? land.landSize.toString() : "N/A"} sqm',
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
        ),
      ),
    );
  }

  // Building Materials Horizontal Scroll
  Widget _buildMaterialListings() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Building Materials',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
            GestureDetector(
              onTap: handleViewAllMaterials,
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFF39322),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        materialListings.isEmpty
            ? _buildEmptyState(
                icon: Icons.construction,
                message: 'No material listings available',
                actionLabel: 'Refresh',
                onAction: _fetchData,
              )
            : SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: materialListings.length,
                  itemBuilder: (context, index) {
                    final material = materialListings[index];
                    return _buildMaterialCard(material, index);
                  },
                ),
              ),
      ],
    );
  }
  
  // Material card with animation
  Widget _buildMaterialCard(Listing material, int index) {
    return Hero(
      tag: 'material_${material.id}',
      child: GestureDetector(
        onTap: () => handleMaterialClick(material.id),
        child: Container(
          width: 180,
          margin: EdgeInsets.only(
            right: index != materialListings.length - 1 ? 16 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Image.network(
                  material.listingImage,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      material.condition ?? 'Brand New',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        getNairaRichText(
                          material.price,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xFFF39322),
                        ),
                        Text(
                          material.quantity ?? 'per unit',
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
        ),
      ),
    );
  }

  // Skilled Workers Horizontal Scroll
  Widget _buildSkillWorkers() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Skilled Workers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
            GestureDetector(
              onTap: handleViewAllSkillWorkers,
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFF39322),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        skillWorkersListings.isEmpty
            ? _buildEmptyState(
                icon: Icons.engineering,
                message: 'No skilled workers available',
                actionLabel: 'Refresh',
                onAction: _fetchData,
              )
            : SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: skillWorkersListings.length,
                  itemBuilder: (context, index) {
                    final worker = skillWorkersListings[index];
                    return _buildWorkerCard(worker, index);
                  },
                ),
              ),
      ],
    );
  }
  
  // Worker card with animation
  Widget _buildWorkerCard(SkillWorker worker, int index) {
    return Hero(
      tag: 'worker_${worker.id}',
      child: GestureDetector(
        onTap: () => handleWorkerClick(worker.id),
        child: Container(
          width: 160,
          margin: EdgeInsets.only(
            right: index != skillWorkersListings.length - 1 ? 16 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF39322),
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(worker.image),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                worker.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000080),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                worker.profession,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFF39322),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    worker.rating.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                worker.experience,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
      ),
    );
  }

  // More Areas Grid
  Widget _buildMoreAreas() {
    if (moreAreas.isEmpty) {
      return const SizedBox(); // Don't show section if empty
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Areas in Lagos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: moreAreas.length,
          itemBuilder: (context, index) {
            final area = moreAreas[index];
            return _buildSmallAreaCard(area);
          },
        ),
      ],
    );
  }
  
  // Small area card
  Widget _buildSmallAreaCard(Area area) {
    return Hero(
      tag: 'more_area_${area.id}',
      child: GestureDetector(
        onTap: () => handleLocationClick(area.id),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
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
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.network(
                      area.image,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                            area.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${area.count} properties',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
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
  }

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  // Error overlay
  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _fetchData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer loading effects
  Widget _buildPopularAreasShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 200,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLandListingsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 200,
                  margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialListingsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 180,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 180,
                  margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkillWorkersShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 160,
                  margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoreAreasShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}