import 'dart:async'; // Import for Timer
import 'dart:convert';
import 'dart:io'; // Import for InternetAddress
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Add HTTP package import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'filter_form.dart';
import 'api/property_api.dart';
import 'api/poll_property_api.dart'; // Import for Poll Property API
import 'database_helper.dart'; // Import for DatabaseHelper
// First, add imports for all the property screens at the top of the file
import 'residential_properties_screen.dart';
import 'commercial_properties_screen.dart';
import 'land_properties_screen.dart';
import 'material_properties_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'utils/currency_formatter.dart'; // Import for CurrencyFormatter

// Define our property model (keep for backward compatibility)
class PropertyListing {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final String? category;

  PropertyListing({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.category,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool locationEnabled = false;
  String selectedCategory = 'residential';
  String budget = '';
  bool isFilterVisible = false;
  Map<String, dynamic> activeFilters = {};
  
  // Property listings states
  List<PropertyListing> residentialProperties = [];
  List<PropertyListing> commercialProperties = [];
  List<PropertyListing> landProperties = [];
  List<PropertyListing> materialProperties = [];
  List<PollProperty> pollProperties = []; // Add poll properties list
  bool isLoading = true;
  bool isPollPropertiesLoading = true; // Separate loading state for poll properties
  String? error;
  
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // PageController for poll properties carousel
  late PageController _pollPropertiesController;
  int _currentPollPage = 0;
  Timer? _pollTimer; // Timer for auto-scrolling poll properties

  // Shared preferences key for tracking first-time user
  static const String _firstTimeUserKey = 'first_time_user';

  // Check if user is opening the app for the first time
  Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    // If the key doesn't exist yet, this is a first-time user
    return prefs.getBool(_firstTimeUserKey) ?? true;
  }

  // Mark user as no longer a first-time user
  Future<void> _setUserHasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeUserKey, false);
  }

  // Show welcome modal for first-time users
  void _showWelcomeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "👋 Welcome to Mipripity!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "You're free to explore listings right away, but creating an account unlocks powerful tools:\n\n"
                  "- Save your favorite properties\n"
                  "- Chat with listers\n"
                  "- Get alerts on hot new deals\n"
                  "- Get personalized recommendations\n\n"
                  "Create your free account in just 30 seconds and make the most of Mipripity!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/register');
                        _setUserHasSeenWelcome();
                        HapticFeedback.mediumImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39322),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _setUserHasSeenWelcome();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        "Maybe Later",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

@override
void initState() {
  super.initState();

  // Initialize animation controller
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),
  );
  
  // Initialize poll properties page controller
  _pollPropertiesController = PageController(
    initialPage: 0,
    viewportFraction: 1.0,
  );

  // Check if user is first-time visitor and show welcome modal
  isFirstTimeUser().then((isFirstTime) {
    if (isFirstTime) {
      // Slight delay to ensure the app is fully loaded before showing modal
      Future.delayed(const Duration(milliseconds: 500), () {
        _showWelcomeModal();
      });
    }
  });

  // Fetch properties on init
  fetchProperties();
  
  // Fetch poll properties
  fetchPollProperties();
  
  // Setup auto-scroll timer for poll properties carousel
  _setupPollPropertiesAutoScroll();
}

@override
void dispose() {
  _pollPropertiesController.dispose();
  _pollTimer?.cancel();
  super.dispose();
}

// Setup auto-scroll for poll properties carousel
void _setupPollPropertiesAutoScroll() {
  _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    if (pollProperties.isNotEmpty && mounted) {
      final nextPage = (_currentPollPage + 1) % pollProperties.length;
      _pollPropertiesController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

// Fetch poll properties from API
Future<void> fetchPollProperties() async {
  setState(() {
    isPollPropertiesLoading = true;
  });
  
  try {
    final properties = await PollPropertyApi.getPollProperties();
    
    if (mounted) {
      setState(() {
        pollProperties = properties;
        isPollPropertiesLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching poll properties: $e');
    if (mounted) {
      setState(() {
        isPollPropertiesLoading = false;
      });
    }
  }
}

// Handle vote for a poll property suggestion
Future<void> _handlePollVote(String pollId, String suggestion) async {
  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final userDataJson = prefs.getString('user_data');
  
  if (userDataJson == null) {
    // User is not logged in, show login prompt
    _showLoginRequiredDialog();
    return;
  }
  
  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording your vote...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    final success = await PollPropertyApi.voteForSuggestion(
      pollPropertyId: pollId,
      suggestion: suggestion,
    );
    
    if (success && mounted) {
      // Update the local state to reflect the vote
      setState(() {
        final pollIndex = pollProperties.indexWhere((p) => p.id == pollId);
        if (pollIndex >= 0) {
          final suggestionIndex = pollProperties[pollIndex].suggestions
              .indexWhere((s) => s.suggestion == suggestion);
          if (suggestionIndex >= 0) {
            pollProperties[pollIndex].suggestions[suggestionIndex].votes++;
          }
        }
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Add haptic feedback for better user experience
      HapticFeedback.mediumImpact();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to record your vote. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('Error voting for poll suggestion: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Show login required dialog
void _showLoginRequiredDialog() {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: Color(0xFF000080),
              ),
              const SizedBox(height: 16),
              const Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "You need to be logged in to vote on poll properties. Create an account or login to access this feature.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/login');
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/register');
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39322),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper method to fetch properties by category with improved error handling and API fallback
Future<List<PropertyListing>> _fetchCategoryProperties(String category) async {
  try {
    // Check network connectivity first
    bool isConnected = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('Network connectivity check failed: $e');
    }

    // Try to get data using normal flow (database with API fallback)
    List<Map<String, dynamic>> properties = [];
    
    try {
      properties = await PropertyApi.getPropertiesByCategory(category);
    } catch (dbError) {
      print('Database error for $category: $dbError');
      
      // If we have network, create a direct HTTP request as fallback instead of using private API methods
      if (isConnected) {
        try {
          // Force API fetch directly via HTTP
          final apiUrl = 'https://mipripity-api-1.onrender.com/properties/$category';
          final http.Response response = await http.get(Uri.parse(apiUrl));
          
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            properties = data.cast<Map<String, dynamic>>();
            print('Successfully fetched $category properties directly from API after database error');
          } else {
            print('API fallback failed with status code: ${response.statusCode}');
            throw Exception('API request failed with status ${response.statusCode}');
          }
        } catch (apiError) {
          print('API fallback also failed for $category: $apiError');
          rethrow; // Re-throw to be caught by outer try-catch
        }
      } else {
        print('No network connection available for API fallback');
        rethrow; // Re-throw if no network available
      }
    }

    // If we got empty results but have network, try API directly
    if (properties.isEmpty && isConnected) {
      try {
        // Direct API fetch for empty results
        final apiUrl = 'https://mipripity-api-1.onrender.com/properties/$category';
        final http.Response response = await http.get(Uri.parse(apiUrl));
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          properties = data.cast<Map<String, dynamic>>();
          print('Used direct API fetch for $category properties after empty database results');
        } else {
          print('API fetch failed with status code: ${response.statusCode}');
        }
      } catch (apiError) {
        print('API fetch failed after empty database results: $apiError');
      }
    }

    List<PropertyListing> propertyList = [];

    for (final property in properties) {
      try {
        String imageUrl = _getDefaultImageForCategory(category);
        
        if (property['images'] != null) {
          var images = property['images'];
          
          if (images is String) {
            try {
              List<dynamic> imageList = jsonDecode(images);
              if (imageList.isNotEmpty) {
                String firstImage = imageList[0].toString();
                if (firstImage.startsWith('http')) {
                  imageUrl = firstImage;
                }
              }
            } catch (e) {
              if (images.toString().startsWith('http')) {
                imageUrl = images.toString();
              }
            }
          } else if (images is List && images.isNotEmpty) {
            String firstImage = images[0].toString();
            if (firstImage.startsWith('http')) {
              imageUrl = firstImage;
            }
          }
        }

        // Ensure the URL is properly formatted
        if (imageUrl.startsWith('http')) {
          imageUrl = Uri.encodeFull(imageUrl.trim());
        }

        propertyList.add(PropertyListing(
          id: property['id'].toString(),
          title: property['title'] ?? 'Untitled Property',
          price: _parsePrice(property['price']),
          location: property['location'] ?? 'Unknown',
          imageUrl: imageUrl,
          bedrooms: property['bedrooms'],
          bathrooms: property['bathrooms'],
          area: property['area'] is String ? double.tryParse(property['area']) : property['area'],
          category: category,
        ));
      } catch (e) {
        print('Error creating PropertyListing from property: $e');
      }
    }

    return propertyList;
  } catch (e) {
    print('Error fetching $category properties: $e');
    return [];
  }
}

Future<void> fetchProperties() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    // Check if we need to initialize the database
    final dbHelper = DatabaseHelper();
    final isInitialized = await dbHelper.isDatabaseInitialized();
    
    if (!isInitialized) {
      print('Database not initialized, initializing now...');
      try {
        await dbHelper.resetDatabase();
        print('Database reset and initialized with default data');
      } catch (dbInitError) {
        print('Error initializing database: $dbInitError');
      }
    }
    
    // Fetch properties from backend API by category
    final residentialData = await _fetchCategoryProperties('residential');
    final commercialData = await _fetchCategoryProperties('commercial');
    final landData = await _fetchCategoryProperties('land');
    final materialData = await _fetchCategoryProperties('material');

    setState(() {
      residentialProperties = residentialData;
      commercialProperties = commercialData;
      landProperties = landData;
      materialProperties = materialData;
      isLoading = false;
    });

    // Start animation after data is loaded
    _animationController.forward();
  } catch (e) {
    print('Error in fetchProperties: $e');
    setState(() {
      error = 'Failed to load properties. Please check your internet connection.';
      isLoading = false;
    });
  }
}

  // Get default image based on property category
  String _getDefaultImageForCategory(String category) {
    switch (category) {
      case 'residential':
        return 'assets/images/residential1.jpg';
      case 'commercial':
        return 'assets/images/commercial1.jpg';
      case 'land':
        return 'assets/images/land1.png';
      case 'material':
        return 'assets/images/material1.jpg';
      default:
        return 'assets/images/residential1.jpg';
    }
  }

  // Helper method to parse price from various formats
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      // Remove any currency symbols and commas
      final cleanPrice = price.replaceAll(RegExp(r'[\u20A6,\s]'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  // Method to handle category selection
  void handleCategorySelect(String category) {
    // Add haptic feedback
    HapticFeedback.selectionClick();
    
    setState(() {
      selectedCategory = category;
      isFilterVisible = true; // Show filter form when category is selected
    });
  }

  // Method to handle filter application
  void handleFilterApplied(Map<String, dynamic> filters) {
    setState(() {
      activeFilters = filters;
      isFilterVisible = false; // Hide filter form after applying filters
    });
    
    // In a real app, you would filter your properties list here
    print('Filters applied for $selectedCategory: $filters');
    // Example:
    // setState(() {
    //   filteredProperties = applyFilters(properties, filters);
    // });
  }

  // Method to close filter form
  void closeFilterForm() {
    setState(() {
      isFilterVisible = false;
    });
  }

  // Format price to local currency (Naira)
String formatPrice(double price) {
  return '₦${price.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  )}';
}

// Get RichText with CustomFont for Naira symbol
Widget getNairaRichText(double price, {Color textColor = Colors.white, double fontSize = 12.0, FontWeight fontWeight = FontWeight.bold}) {
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

  // Build property cards
  Widget buildPropertyCards(List<PropertyListing> properties, String category) {
    if (isLoading) {
      return Row(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              width: 240,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFFF39322).withOpacity(0.5),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 100,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading properties. Please try again.',
              style: TextStyle(color: Colors.red[500]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: fetchProperties,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (properties.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.grey[400], size: 48),
            const SizedBox(height: 16),
            const Text(
              'No featured properties available.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Row(
      children: properties.asMap().entries.map((entry) {
        final int idx = entry.key;
        final property = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // Staggered animation for cards
              final delay = idx * 0.2;
              final startValue = delay;
              final endValue = delay + 0.8;
              
              final animationProgress = (_animationController.value - startValue) / (endValue - startValue);
              final calculatedValue = animationProgress.clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(0, 20 * (1 - calculatedValue)),
                child: Opacity(
                  opacity: calculatedValue,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                // Navigate to property details based on category
                switch (category) {
                  case 'residential':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResidentialPropertiesScreen()),
                    );
                    break;
                  case 'commercial':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CommercialPropertiesScreen()),
                    );
                    break;
                  case 'land':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LandPropertiesScreen()),
                    );
                    break;
                  case 'material':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MaterialPropertiesScreen()),
                    );
                    break;
                }
                
                // Add haptic feedback for better engagement
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 240,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Hero(
                        tag: 'property-${property.id}',
                        child: Container(
                          height: 140,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: property.imageUrl.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: property.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 140,
                                          fadeInDuration: const Duration(milliseconds: 200),
                                          fadeOutDuration: const Duration(milliseconds: 200),
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[100],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF39322)),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            print('Error loading image: $error for URL: $url');
                                            return Image.asset(
                                              _getDefaultImageForCategory(property.category ?? 'residential'),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 140,
                                            );
                                          },
                                          cacheManager: DefaultCacheManager(),
                                          maxHeightDiskCache: 1500,
                                          memCacheHeight: 1500,
                                          httpHeaders: const {
                                            'Accept': 'image/*',
                                          },
                                        )
                                      : Image.asset(
                                          _getDefaultImageForCategory(property.category ?? 'residential'),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 140,
                                        ),
                                ),
                        ),
                      ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF000080).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: getNairaRichText(
                              property.price,
                              textColor: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Add a favorite button
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000080),
                              fontSize: 14,
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
                          // Property details (bedrooms, bathrooms, area)
                          if (property.bedrooms != null || property.bathrooms != null || property.area != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (property.bedrooms != null)
                                  _buildPropertyFeature(
                                    Icons.bed_outlined,
                                    '${property.bedrooms}',
                                  ),
                                if (property.bathrooms != null)
                                  _buildPropertyFeature(
                                    Icons.bathtub_outlined,
                                    '${property.bathrooms}',
                                  ),
                                if (property.area != null)
                                  _buildPropertyFeature(
                                    Icons.square_foot_outlined,
                                    '${property.area}m²',
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPropertyFeature(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFFF39322),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF000080),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Main Content Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with animated gradient
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF000080), Color(0xFF0000B3)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Find Your Dream Property',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Discover the perfect place to call home',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Search Box with Location Toggle
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(50),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search,
                                        color: Color(0xFFF39322),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            hintText: 'What is your Budget?',
                                            hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              budget = value;
                                            });
                                          },
                                        ),
                                      ),
                                      Container(
                                        height: 24,
                                        width: 1,
                                        color: Colors.grey[300],
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'Location',
                                            style: TextStyle(
                                              color: Color(0xFF000080),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: locationEnabled,
                                            onChanged: (value) {
                                              setState(() {
                                                locationEnabled = value;
                                                // Add haptic feedback
                                                HapticFeedback.selectionClick();
                                              });
                                            },
                                            activeColor: const Color(0xFFF39322),
                                            activeTrackColor: const Color(0xFFF39322).withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Category Tabs with improved UI
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Residential Button
                                buildCategoryButton(
                                  'residential',
                                  'Residential',
                                  'assets/icons/residential.png',
                                ),
                                
                                // Commercial Button
                                buildCategoryButton(
                                  'commercial',
                                  'Commercial',
                                  'assets/icons/commercial.png',
                                ),
                                
                                // Land Button
                                buildCategoryButton(
                                  'land',
                                  'Land',
                                  'assets/icons/land.png',
                                ),
                                
                                // Material Button
                                buildCategoryButton(
                                  'material',
                                  'Material',
                                  'assets/icons/material.png',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Active filters indicator (if any)
                          if (activeFilters.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF39322).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF39322).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: Color(0xFFF39322),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Filters applied: ${activeFilters.length} filters',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFF39322),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        activeFilters = {};
                                      });
                                    },
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF000080),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Poll Properties Section - Always show, with loading state if needed
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Poll Properties',
                                        style: TextStyle(
                                          color: Color(0xFF000080),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (!isPollPropertiesLoading && pollProperties.isNotEmpty)
                                        Row(
                                          children: [
                                            for (int i = 0; i < pollProperties.length; i++)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _currentPollPage == i
                                                      ? const Color(0xFFF39322)
                                                      : Colors.grey[300],
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (isPollPropertiesLoading) 
                                  // Loading placeholder
                                  SizedBox(
                                    height: 290,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF39322)),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Loading poll properties...',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (pollProperties.isEmpty)
                                  // Empty state placeholder
                                  SizedBox(
                                    height: 290,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.poll_outlined,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No poll properties available',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 290, // Height of poll property cards
                                    child: PageView.builder(
                                      controller: _pollPropertiesController,
                                      itemCount: pollProperties.length,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentPollPage = index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final property = pollProperties[index];
                                        return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                spreadRadius: 0,
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Property Image
                                              SizedBox(
                                                height: 180,
                                                width: double.infinity,
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                  child: property.imageUrl.startsWith('http') 
                                                      ? CachedNetworkImage(
                                                          imageUrl: property.imageUrl,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Container(
                                                            color: Colors.grey[200],
                                                            child: const Center(
                                                              child: CircularProgressIndicator(
                                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                                  Color(0xFFF39322),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          errorWidget: (context, url, error) => Image.asset(
                                                            'assets/images/residential1.jpg',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                      : Image.asset(
                                                          property.imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                                            'assets/images/residential1.jpg',
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              // Property Details
                                              Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      property.title,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF000080),
                                                        fontSize: 16,
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
                                                    const SizedBox(height: 12),
                                                    // Suggestions
                                                    SizedBox(
                                                      height: 40,
                                                      child: ListView.builder(
                                                        scrollDirection: Axis.horizontal,
                                                        itemCount: property.suggestions.length,
                                                        itemBuilder: (context, i) {
                                                          final suggestion = property.suggestions[i];
                                                          return GestureDetector(
                                                            onTap: () {
                                                              _handlePollVote(property.id, suggestion.suggestion);
                                                            },
                                                            child: Container(
                                                              margin: const EdgeInsets.only(right: 8),
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 6,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF000080).withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(20),
                                                                border: Border.all(
                                                                  color: const Color(0xFF000080).withOpacity(0.3),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    suggestion.suggestion,
                                                                    style: const TextStyle(
                                                                      color: Color(0xFF000080),
                                                                      fontWeight: FontWeight.w500,
                                                                      fontSize: 12,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 6),
                                                                  Container(
                                                                    padding: const EdgeInsets.all(4),
                                                                    decoration: const BoxDecoration(
                                                                      color: Color(0xFFF39322),
                                                                      shape: BoxShape.circle,
                                                                    ),
                                                                    child: Text(
                                                                      '${suggestion.votes}',
                                                                      style: const TextStyle(
                                                                        color: Colors.white,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 10,
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
                                              ),
                                            ],
                                          ),
                                        ),
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          
                          // Featured Residential Properties
                          buildPropertySection(
                            'Featured Residential Properties',
                            residentialProperties,
                            'residential',
                          ),
                          
                          // Featured Commercial Properties
                          buildPropertySection(
                            'Featured Commercial Properties',
                            commercialProperties,
                            'commercial',
                          ),
                          
                          // Featured Land Properties
                          buildPropertySection(
                            'Featured Landed Properties',
                            landProperties,
                            'land',
                          ),
                          
                          // Featured Material Properties
                          buildPropertySection(
                            'Featured Materials',
                            materialProperties,
                            'material',
                          ),
                          
                          // Action Buttons with improved styling
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to login
                                    Navigator.of(context).pushNamed('/login');
                                    // Add haptic feedback
                                    HapticFeedback.mediumImpact();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: const Color(0xFF000080),
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFF000080)),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/register');
                                    HapticFeedback.mediumImpact();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    backgroundColor: const Color(0xFFF39322),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Add a footer
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSocialButton(
                                      'assets/icons/facebook.png',
                                      'https://www.facebook.com/profile.php?id=61577108757783',
                                    ),
                                    _buildSocialButton(
                                      'assets/icons/instagram.png',
                                      'https://www.instagram.com/mipripity2025',
                                    ),
                                    _buildSocialButton(
                                      'assets/icons/linkedin.png',
                                      'https://www.linkedin.com/in/mipripity-mipripity-a69873372',
                                    ),
                                    _buildSocialButton(
                                      'assets/icons/whatsapp.png',
                                      'https://wa.link/1dl9yw',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '© 2024 Property Finder. All rights reserved.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Filter form overlay
            if (isFilterVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: closeFilterForm, // Close when tapping outside
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Prevent closing when tapping on the form
                        child: FilterForm(
                          selectedCategory: selectedCategory,
                          onFilterApplied: handleFilterApplied,
                          onClose: closeFilterForm,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(String imagePath, String url) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Handle error - could show a snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch $url')),
            );
          }
        }
        // Add haptic feedback for better user experience
        HapticFeedback.mediumImpact();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          imagePath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }

  // Helper method to build category buttons with improved UI
  Widget buildCategoryButton(String category, String label, String iconPath) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () => handleCategorySelect(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF39322)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFFF39322).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: isSelected ? 8 : 4,
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
                  width: 36,
                  height: 36,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFF39322)
                    : const Color(0xFF000080),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build property sections with improved UI
  Widget buildPropertySection(
    String title,
    List<PropertyListing> properties,
    String category,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to category page based on category
                switch (category) {
                  case 'residential':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResidentialPropertiesScreen()),
                    );
                    break;
                  case 'commercial':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CommercialPropertiesScreen()),
                    );
                    break;
                  case 'land':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LandPropertiesScreen()),
                    );
                    break;
                  case 'material':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MaterialPropertiesScreen()),
                    );
                    break;
                }
                
                // Add haptic feedback
                HapticFeedback.selectionClick();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF39322),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: buildPropertyCards(properties, category),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
