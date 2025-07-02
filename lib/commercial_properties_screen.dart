import 'package:flutter/material.dart';
import 'dart:convert';
import 'api/property_api.dart';
import 'utils/currency_formatter.dart';
import 'utils/property_prospect_util.dart';

class CommercialProperty {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final String propertyType; // office, retail, warehouse, industrial
  final double area; // in square meters
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status; // 'for_sale', 'for_rent', 'sold'
  final int? floors;
  final int? parkingSpaces;
  final String? yearBuilt;

  CommercialProperty({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.propertyType,
    required this.area,
    required this.description,
    required this.features,
    this.isFeatured = false,
    this.status = 'for_sale',
    this.floors,
    this.parkingSpaces,
    this.yearBuilt,
  });

  factory CommercialProperty.fromJson(Map<String, dynamic> json) {
    // Map backend type to UI type
    String backendType = (json['type'] ?? '').toString().toLowerCase();
    String mappedType;
    switch (backendType) {
      case 'office':
      case 'retail':
      case 'warehouse':
      case 'industrial':
        mappedType = backendType;
        break;
      case 'commercial':
        // Default to 'office' or 'commercial' for now
        mappedType = 'office';
        break;
      default:
        mappedType = 'office';
    }

    // Parse features - they might be stored as a JSON string in the database
    List<String> parsedFeatures = [];
    if (json['features'] != null) {
      if (json['features'] is String) {
        try {
          // Try to parse the string as JSON
          final dynamic featuresData = jsonDecode(json['features']);
          if (featuresData is List) {
            parsedFeatures = featuresData.map((f) => f.toString()).toList();
          } else if (featuresData is String) {
            // Handle case where the features might be a comma-separated string
            parsedFeatures = featuresData.split(',').map((s) => s.trim()).toList();
          }
        } catch (e) {
          // If it's not valid JSON, treat it as a comma-separated string
          parsedFeatures = json['features'].split(',').map((s) => s.trim()).toList();
        }
      } else if (json['features'] is List) {
        parsedFeatures = List<String>.from(json['features']);
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

    return CommercialProperty(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      price: json['price'] is double 
          ? json['price'] 
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      location: json['location'] ?? '',
      imageUrl: imageUrl,
      propertyType: mappedType,
      area: json['area'] is double 
          ? json['area'] 
          : double.tryParse(json['area']?.toString() ?? '0') ?? 0,
      description: json['description'] ?? '',
      features: parsedFeatures,
      isFeatured: json['isFeatured'] == 1 || json['is_featured'] == true || json['category'] == 'premium',
      status: json['status']?.toString() ?? 'for_sale',
      floors: json['floors'] is int
          ? json['floors']
          : int.tryParse(json['floors']?.toString() ?? ''),
      parkingSpaces: json['parkingSpaces'] is int
          ? json['parkingSpaces']
          : int.tryParse(json['parkingSpaces']?.toString() ?? ''),
      yearBuilt: json['yearBuilt']?.toString() ?? json['year_built']?.toString(),
    );
  }
}

class CommercialPropertiesScreen extends StatefulWidget {
  const CommercialPropertiesScreen({super.key});

  @override
  State<CommercialPropertiesScreen> createState() => _CommercialPropertiesScreenState();
}

class _CommercialPropertiesScreenState extends State<CommercialPropertiesScreen> {
  List<CommercialProperty> properties = [];
  List<CommercialProperty> filteredProperties = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'all'; // all, for_sale, for_rent
  String selectedTypeFilter = 'all'; // all, office, retail, warehouse, industrial
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchCommercialProperties();
  }

Future<void> fetchCommercialProperties() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    // Get commercial properties using the PropertyApi
    final propertiesData = await PropertyApi.getPropertiesByCategory('commercial');
    
    // Convert to CommercialProperty objects
    final List<CommercialProperty> loadedProperties = propertiesData
        .map((json) => CommercialProperty.fromJson(json))
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
    print('Error fetching commercial properties: $e');
  }
}

  void filterProperties() {
    setState(() {
      isLoading = true;
    });

    // Use optimized filtering method from PropertyApi if possible
    _filterPropertiesUsingApi();
  }

  // Method to filter properties using the API
  Future<void> _filterPropertiesUsingApi() async {
    try {
      // If we have simple filtering that the API supports
      final String? status = selectedFilter != 'all' ? selectedFilter : null;
      final String? propertyType = selectedTypeFilter != 'all' ? selectedTypeFilter : null;
      
      // Use the API's filtering method
      final propertiesData = await PropertyApi.getCommercialPropertiesWithFilter(
        status: status,
        propertyType: propertyType,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      final List<CommercialProperty> filtered = propertiesData
          .map((json) => CommercialProperty.fromJson(json))
          .toList();
      
      setState(() {
        filteredProperties = filtered;
        isLoading = false;
      });
    } catch (e) {
      print('Error filtering properties using API: $e');
      
      // Fallback to local filtering if API filtering fails
      _filterPropertiesLocally();
    }
  }

  // Fallback method to filter properties locally
  void _filterPropertiesLocally() {
    List<CommercialProperty> filtered = properties;

    // Filter by status
    if (selectedFilter != 'all') {
      filtered = filtered.where((property) => property.status == selectedFilter).toList();
    }

    // Filter by property type
    if (selectedTypeFilter != 'all') {
      filtered = filtered.where((property) => property.propertyType == selectedTypeFilter).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((property) =>
        property.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
        property.location.toLowerCase().contains(searchQuery.toLowerCase()) ||
        property.propertyType.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

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

  String getPropertyTypeIcon(String type) {
    switch (type) {
      case 'office':
        return '🏢';
      case 'retail':
        return '🏪';
      case 'warehouse':
        return '🏭';
      case 'industrial':
        return '🏗️';
      default:
        return '🏢';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Commercial Properties',
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
                hintText: 'Search commercial properties...',
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
                        _buildFilterChip('All', 'all', selectedFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('For Sale', 'for_sale', selectedFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('For Rent', 'for_rent', selectedFilter),
                        const SizedBox(width: 16),
                        _buildTypeFilterChip('All Types', 'all', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Office', 'office', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Retail', 'retail', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Warehouse', 'warehouse', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Industrial', 'industrial', selectedTypeFilter),
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

  Widget _buildFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
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
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: fetchCommercialProperties,
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
            Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No commercial properties found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredProperties.length,
      itemBuilder: (context, index) {
        final property = filteredProperties[index];
        return _buildPropertyCard(property);
      },
    );
  }

  Widget _buildPropertyCard(CommercialProperty property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed('/property-details/${property.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(
                      property.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
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
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: property.status == 'for_rent' 
                        ? Colors.green 
                        : const Color(0xFF000080),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.status == 'for_rent' ? 'FOR RENT' : 'FOR SALE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getPropertyTypeIcon(property.propertyType),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          property.propertyType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Prospect Suggestion Bubbles
            _buildProspectSuggestions(property),
            
            // Property Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 12),
                  
                  // Property Features
                  Row(
                    children: [
                      _buildFeatureItem(Icons.square_foot, '${property.area.toInt()} m²'),
                      if (property.floors != null) ...[
                        const SizedBox(width: 16),
                        _buildFeatureItem(Icons.layers, '${property.floors} Floors'),
                      ],
                      if (property.parkingSpaces != null) ...[
                        const SizedBox(width: 16),
                        _buildFeatureItem(Icons.local_parking, '${property.parkingSpaces} Parking'),
                      ],
                    ],
                  ),
                  if (property.yearBuilt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFeatureItem(Icons.calendar_today, 'Built ${property.yearBuilt}'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    property.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Key Features
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: property.features.take(3).map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF000080),
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

  // Build the suggestion bubbles row
  Widget _buildProspectSuggestions(CommercialProperty property) {
    // Get random suggestions for this property
    final suggestions = PropertyProspectUtil.getRandomSuggestionsForType(
      PropertyType.commercial,
      property.price,
    );
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Business Prospects',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
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
                        color: const Color(0xFFF39322).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFF39322).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        suggestion.title,
                        style: const TextStyle(
                          color: Color(0xFFF39322),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF000080)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF000080),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Commercial Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Property Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  'office',
                  'retail',
                  'warehouse',
                  'industrial',
                ].map((type) {
                  return FilterChip(
                    label: Text(type.toUpperCase()),
                    selected: selectedTypeFilter == type,
                    onSelected: (selected) {
                      setState(() {
                        selectedTypeFilter = selected ? type : 'all';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  filterProperties();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }
}