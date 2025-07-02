import 'package:flutter/material.dart';
import 'dart:convert';
import 'api/property_api.dart';
import 'utils/currency_formatter.dart';
import 'utils/property_prospect_util.dart';

class LandProperty {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final String landType; // residential, commercial, agricultural, industrial
  final double area; // in square meters or acres
  final String areaUnit; // 'sqm' or 'acres'
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status; // 'for_sale', 'sold'
  final String? titleDocument; // Certificate of Occupancy, Deed of Assignment, etc.
  final bool? surveyed;
  final String? zoning;

  LandProperty({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.landType,
    required this.area,
    required this.areaUnit,
    required this.description,
    required this.features,
    this.isFeatured = false,
    this.status = 'for_sale',
    this.titleDocument,
    this.surveyed,
    this.zoning,
  });

  factory LandProperty.fromJson(Map<String, dynamic> json) {
    // Parse features - they might be stored as a JSON string in the database
    List<String> parsedFeatures = [];
    if (json['features'] != null) {
      if (json['features'] is String) {
        try {
          // Try to parse the string as JSON
          final dynamic featuresData = jsonDecode(json['features']);
          if (featuresData is List) {
            parsedFeatures = List<String>.from(featuresData.map((f) => f.toString()));
          } else if (featuresData is String) {
            // Handle case where the features might be a comma-separated string
            parsedFeatures = featuresData.split(',').map((s) => s.trim()).toList();
          }
        } catch (e) {
          // If it's not valid JSON, treat it as a comma-separated string
          parsedFeatures = json['features'].split(',').map((s) => s.trim()).toList();
        }
      } else if (json['features'] is List) {
        parsedFeatures = List<String>.from(json['features'].map((f) => f.toString()));
      }
    }

    // Handle image URL - might be stored differently in the database
    String imageUrl = 'https://via.placeholder.com/400x200.png?text=No+Image';
    if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      imageUrl = json['imageUrl'];
    } else if (json['images'] != null) {
      if (json['images'] is String) {
        try {
          final dynamic imagesData = jsonDecode(json['images']);
          if (imagesData is List && imagesData.isNotEmpty) {
            imageUrl = imagesData[0].toString();
          } else if (imagesData is String && imagesData.isNotEmpty) {
            imageUrl = imagesData;
          }
        } catch (e) {
          // If not valid JSON, use as is if it starts with http
          if (json['images'].toString().startsWith('http')) {
            imageUrl = json['images'];
          }
        }
      } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
        imageUrl = json['images'][0].toString();
      }
    }

    return LandProperty(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      price: json['price'] is double 
          ? json['price'] 
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      location: json['location'] ?? '',
      imageUrl: imageUrl,
      landType: json['type'] ?? json['landType'] ?? 'residential',
      area: json['area'] is double
          ? json['area']
          : double.tryParse(json['area']?.toString() ?? '0') ?? 0,
      areaUnit: json['area_unit'] ?? json['areaUnit'] ?? 'sqm',
      description: json['description'] ?? '',
      features: parsedFeatures,
      isFeatured: json['isFeatured'] == 1 || json['is_featured'] == true || json['category'] == 'premium',
      status: json['status'] ?? 'for_sale',
      titleDocument: json['title_document'] ?? json['titleDocument'],
      surveyed: json['surveyed'] == true || json['surveyed'] == 1,
      zoning: json['zoning'],
    );
  }
}

class LandPropertiesScreen extends StatefulWidget {
  const LandPropertiesScreen({super.key});

  @override
  State<LandPropertiesScreen> createState() => _LandPropertiesScreenState();
}

class _LandPropertiesScreenState extends State<LandPropertiesScreen> {
  List<LandProperty> properties = [];
  List<LandProperty> filteredProperties = [];
  bool isLoading = true;
  String? error;
  String selectedTypeFilter = 'all'; // all, residential, commercial, agricultural, industrial
  String selectedAreaFilter = 'all'; // all, small, medium, large
  String selectedPriceRange = 'all'; // all, 0-20m, 20-50m, 50m+
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLandProperties();
  }

  Future<void> fetchLandProperties() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Get land properties using the PropertyApi
      final propertiesData = await PropertyApi.getPropertiesByCategory('land');
      
      // Convert to LandProperty objects
      final List<LandProperty> loadedProperties = propertiesData
          .map((json) => LandProperty.fromJson(json))
          .toList();

      setState(() {
        properties = loadedProperties;
        filteredProperties = loadedProperties;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading properties: $e';
        isLoading = false;
      });
      print('Error fetching land properties: $e');
    }
  }

  void filterProperties() {
    setState(() {
      isLoading = true;
    });

    // Try to use API-based filtering first
    _filterPropertiesUsingApi();
  }

  // Method to filter properties using the API
  Future<void> _filterPropertiesUsingApi() async {
    try {
      // Determine price range for local filtering
      double? minPrice;
      double? maxPrice;

      if (selectedPriceRange != 'all') {
        switch (selectedPriceRange) {
          case '0-20m':
            maxPrice = 20000000;
            break;
          case '20-50m':
            minPrice = 20000000;
            maxPrice = 50000000;
            break;
          case '50m+':
            minPrice = 50000000;
            break;
        }
      }

      // Determine land type filter
      final String? landType = selectedTypeFilter != 'all' ? selectedTypeFilter : null;
      
      // Use the API's filtering method (without price parameters, as they're not supported)
      final propertiesData = await PropertyApi.getLandPropertiesWithFilter(
        landType: landType,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      // Convert to LandProperty objects
      final List<LandProperty> allFiltered = propertiesData
          .map((json) => LandProperty.fromJson(json))
          .toList();
      
      // Apply price filtering locally since it's not supported by the API
      List<LandProperty> priceFiltered = allFiltered;
      if (minPrice != null || maxPrice != null) {
        priceFiltered = allFiltered.where((property) {
          bool matchesPrice = true;
          if (minPrice != null && property.price < minPrice) matchesPrice = false;
          if (maxPrice != null && property.price > maxPrice) matchesPrice = false;
          return matchesPrice;
        }).toList();
      }
      
      setState(() {
        filteredProperties = priceFiltered;
        isLoading = false;
      });
    } catch (e) {
      print('Error filtering properties using API: $e');
      
      // Fallback to local filtering if API filtering fails
      _filterPropertiesLocally();
    }
  }

  // Fallback method for local filtering
  void _filterPropertiesLocally() {
    double? minPrice;
    double? maxPrice;

    // Parse price range
    if (selectedPriceRange != 'all') {
      switch (selectedPriceRange) {
        case '0-20m':
          maxPrice = 20000000;
          break;
        case '20-50m':
          minPrice = 20000000;
          maxPrice = 50000000;
          break;
        case '50m+':
          minPrice = 50000000;
          break;
      }
    }

    List<LandProperty> filtered = properties.where((property) {
      bool matchesType = selectedTypeFilter == 'all' ||
          property.landType == selectedTypeFilter;
      bool matchesPrice = true;
      if (minPrice != null && property.price < minPrice) matchesPrice = false;
      if (maxPrice != null && property.price > maxPrice) matchesPrice = false;
      bool matchesSearch = searchQuery.isEmpty ||
          property.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          property.location.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesType && matchesPrice && matchesSearch;
    }).toList();

    setState(() {
      filteredProperties = filtered;
      isLoading = false;
    });
  }

  // Format price to Nigerian Naira
  String formatPrice(double price) {
    return CurrencyFormatter.formatNaira(price.round().toDouble(), useAbbreviations: true, decimalPlaces: 0);
  }

  // Format price to Nigerian Naira without abbreviations
  String formatFullPrice(double price) {
    return CurrencyFormatter.formatNaira(price.round().toDouble(), useAbbreviations: false, decimalPlaces: 0);
  }

  // Get RichText with proper Naira symbol using CustomFont
  Widget getNairaRichText(
    double price, {
    Color textColor = Colors.black,
    double fontSize = 12.0,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return CurrencyFormatter.formatNairaRichText(
      price.round().toDouble(),
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

  String getLandTypeIcon(String type) {
    switch (type) {
      case 'residential':
        return '🏠';
      case 'commercial':
        return '🏢';
      case 'agricultural':
        return '🌾';
      case 'industrial':
        return '🏭';
      default:
        return '🏞️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Land Properties',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF000080)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search land properties...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF000080)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF000080)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                searchQuery = value;
                filterProperties();
              },
            ),
          ),
          
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTypeFilterChip('All Types', 'all', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Residential', 'residential', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Commercial', 'commercial', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Agricultural', 'agricultural', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Industrial', 'industrial', selectedTypeFilter),
                        const SizedBox(width: 16),
                        _buildAreaFilterChip('All Sizes', 'all', selectedAreaFilter),
                        const SizedBox(width: 8),
                        _buildAreaFilterChip('Small', 'small', selectedAreaFilter),
                        const SizedBox(width: 8),
                        _buildAreaFilterChip('Medium', 'medium', selectedAreaFilter),
                        const SizedBox(width: 8),
                        _buildAreaFilterChip('Large', 'large', selectedAreaFilter),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Properties List
          Expanded(
            child: _buildPropertiesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTypeFilter = value;
        });
        filterProperties();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAreaFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAreaFilter = value;
        });
        filterProperties();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF39322) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchLandProperties,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No properties found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchLandProperties,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredProperties.length,
        itemBuilder: (context, index) {
          final property = filteredProperties[index];
          return _buildPropertyCard(property);
        },
      ),
    );
  }

  Widget _buildPropertyCard(LandProperty property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPropertyDetails(property),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      property.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.landscape,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Featured Badge
                if (property.isFeatured)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39322),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Land Type Icon
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      getLandTypeIcon(property.landType),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
            
            // Prospect Suggestion Bubbles
            _buildProspectSuggestions(property),
            
            // Property Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                      getNairaRichText(
                        property.price,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        textColor: const Color(0xFFF39322),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Area and Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${property.area} ${property.areaUnit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000080).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.landType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    property.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Features
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: property.features.take(3).map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyDetails(LandProperty property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Image
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[300],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              property.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.landscape,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title and Type
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                            ),
                            Text(
                              getLandTypeIcon(property.landType),
                              style: const TextStyle(fontSize: 30),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Price
                        getNairaRichText(
                          property.price,
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          textColor: const Color(0xFFF39322),
                        ),
                        const SizedBox(height: 16),
                        
                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                property.location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Property Info
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard('Area', '${property.area} ${property.areaUnit}'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard('Type', property.landType.toUpperCase()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard('Status', property.status.toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard('Surveyed', property.surveyed == true ? 'YES' : 'NO'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          property.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Features
                        const Text(
                          'Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: property.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Legal Info
                        if (property.titleDocument != null || property.zoning != null) ...[
                          const Text(
                            'Legal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (property.titleDocument != null)
                            _buildLegalInfoRow('Title Document', property.titleDocument!),
                          if (property.zoning != null)
                            _buildLegalInfoRow('Zoning', property.zoning!),
                          const SizedBox(height: 24),
                        ],
                        
                        // Contact Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle call action
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000080),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build the suggestion bubbles row
  Widget _buildProspectSuggestions(LandProperty property) {
    // Get random suggestions for this property
    final suggestions = PropertyProspectUtil.getRandomSuggestionsForType(
      PropertyType.land,
      property.price,
    );
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          bottom: BorderSide(color: Colors.green[100]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Development Prospects',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      PropertyProspectUtil.showProspectDetails(
                        context, 
                        suggestion,
                        property.price,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.green[300]!,
                        ),
                      ),
                      child: Text(
                        suggestion.title,
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Properties',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Land Type Filter
                  const Text(
                    'Land Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterOption('All Types', 'all', selectedTypeFilter, true),
                      _buildFilterOption('Residential', 'residential', selectedTypeFilter, true),
                      _buildFilterOption('Commercial', 'commercial', selectedTypeFilter, true),
                      _buildFilterOption('Agricultural', 'agricultural', selectedTypeFilter, true),
                      _buildFilterOption('Industrial', 'industrial', selectedTypeFilter, true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Area Size Filter
                  const Text(
                    'Area Size',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterOption('All Sizes', 'all', selectedAreaFilter, false),
                      _buildFilterOption('Small (≤600 sqm or ≤2 acres)', 'small', selectedAreaFilter, false),
                      _buildFilterOption('Medium (600-1500 sqm or 2-10 acres)', 'medium', selectedAreaFilter, false),
                      _buildFilterOption('Large (>1500 sqm or >10 acres)', 'large', selectedAreaFilter, false),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              selectedTypeFilter = 'all';
                              selectedAreaFilter = 'all';
                              searchQuery = '';
                            });
                            filterProperties();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF000080)),
                          ),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(color: Color(0xFF000080)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            filterProperties();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000080),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply Filters'),
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
  }

  Widget _buildFilterOption(String label, String value, String selectedValue, bool isTypeFilter) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isTypeFilter) {
            selectedTypeFilter = value;
          } else {
            selectedAreaFilter = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isTypeFilter ? const Color(0xFF000080) : const Color(0xFFF39322))
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? (isTypeFilter ? const Color(0xFF000080) : const Color(0xFFF39322))
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}