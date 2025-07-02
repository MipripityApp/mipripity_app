import 'package:flutter/material.dart';
import 'dart:convert';
import 'api/property_api.dart';
import 'utils/currency_formatter.dart';
import 'utils/property_prospect_util.dart';

class PropertyListing {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final String location;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final String description;
  final List<dynamic> features;
  final String status;
  final bool isFeatured;

  PropertyListing({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.location,
    this.bedrooms,
    this.bathrooms,
    this.area,
    required this.description,
    required this.features,
    required this.status,
    required this.isFeatured,
  });

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    // Parse features - they might be stored as a JSON string in the database
    List<dynamic> parsedFeatures = [];
    if (json['features'] != null) {
      if (json['features'] is String) {
        try {
          // Try to parse the string as JSON
          final dynamic featuresData = jsonDecode(json['features']);
          if (featuresData is List) {
            parsedFeatures = featuresData;
          } else if (featuresData is String) {
            // Handle case where the features might be a comma-separated string
            parsedFeatures = featuresData.split(',').map((s) => s.trim()).toList();
          }
        } catch (e) {
          // If it's not valid JSON, treat it as a comma-separated string
          parsedFeatures = json['features'].split(',').map((s) => s.trim()).toList();
        }
      } else if (json['features'] is List) {
        parsedFeatures = json['features'];
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

    return PropertyListing(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      imageUrl: imageUrl,
      price: json['price'] is double 
          ? json['price'] 
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      location: json['location'] ?? '',
      bedrooms: json['bedrooms'] is int 
          ? json['bedrooms'] 
          : int.tryParse(json['bedrooms']?.toString() ?? ''),
      bathrooms: json['bathrooms'] is int 
          ? json['bathrooms'] 
          : int.tryParse(json['bathrooms']?.toString() ?? ''),
      area: json['area'] is double 
          ? json['area'] 
          : double.tryParse(json['area']?.toString() ?? ''),
      description: json['description'] ?? '',
      features: parsedFeatures,
      status: json['status'] ?? json['category'] ?? 'for_sale',
      isFeatured: json['isFeatured'] == 1 || json['is_featured'] == true || json['category'] == 'premium',
    );
  }
}

class ResidentialPropertiesScreen extends StatefulWidget {
  const ResidentialPropertiesScreen({super.key});

  @override
  State<ResidentialPropertiesScreen> createState() => _ResidentialPropertiesScreenState();
}

class _ResidentialPropertiesScreenState extends State<ResidentialPropertiesScreen> {
  List<PropertyListing> properties = [];
  List<PropertyListing> filteredProperties = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'all'; // all, for_sale, for_rent
  String selectedPriceRange = 'all'; // all, 0-20m, 20-50m, 50m+
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchResidentialProperties();
  }

  Future<void> fetchResidentialProperties() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Get residential properties using the PropertyApi
      final propertiesData = await PropertyApi.getPropertiesByCategory('residential');
      
      // Convert to PropertyListing objects
      final List<PropertyListing> loadedProperties = propertiesData
          .map((json) => PropertyListing.fromJson(json))
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
      print('Error fetching residential properties: $e');
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
      // Determine price range
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

      // Determine status filter
      final String? status = selectedFilter != 'all' ? selectedFilter : null;
      
      // Use the API's filtering method
      final propertiesData = await PropertyApi.getResidentialPropertiesWithFilter(
        status: status,
        minPrice: minPrice,
        maxPrice: maxPrice,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );
      
      final List<PropertyListing> filtered = propertiesData
          .map((json) => PropertyListing.fromJson(json))
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

    List<PropertyListing> filtered = properties.where((property) {
      bool matchesStatus = selectedFilter == 'all' ||
          (selectedFilter == 'for_sale' && property.status == 'for_sale') ||
          (selectedFilter == 'for_rent' && property.status == 'for_rent');
      bool matchesPrice = true;
      if (minPrice != null && property.price < minPrice) matchesPrice = false;
      if (maxPrice != null && property.price > maxPrice) matchesPrice = false;
      bool matchesSearch = searchQuery.isEmpty ||
          property.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          property.location.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesStatus && matchesPrice && matchesSearch;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Residential Properties',
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
                hintText: 'Search properties...',
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
                        _buildPriceFilterChip('All Prices', 'all', selectedPriceRange),
                        const SizedBox(width: 8),
                        _buildPriceFilterChip('₦0-20M', '0-20m', selectedPriceRange),
                        const SizedBox(width: 8),
                        _buildPriceFilterChip('₦20-50M', '20-50m', selectedPriceRange),
                        const SizedBox(width: 8),
                        _buildPriceFilterChip('₦50M+', '50m+', selectedPriceRange),
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

  Widget _buildPriceFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    
    // Handle the price formatting for chips with naira values
    Widget chipLabel;
    if (label.startsWith('₦')) {
      // Extract the price part and convert to double for formatting
      String priceText = label.substring(1); // Remove the ₦ symbol
      
      if (priceText == '0-20M') {
        chipLabel = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getNairaRichText(
              0,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              textColor: isSelected ? Colors.white : Colors.grey[700]!,
            ),
            Text(
              '-',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            getNairaRichText(
              20000000,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              textColor: isSelected ? Colors.white : Colors.grey[700]!,
            ),
          ],
        );
      } else if (priceText == '20-50M') {
        chipLabel = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getNairaRichText(
              20000000,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              textColor: isSelected ? Colors.white : Colors.grey[700]!,
            ),
            Text(
              '-',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            getNairaRichText(
              50000000,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              textColor: isSelected ? Colors.white : Colors.grey[700]!,
            ),
          ],
        );
      } else if (priceText == '50M+') {
        chipLabel = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getNairaRichText(
              50000000,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              textColor: isSelected ? Colors.white : Colors.grey[700]!,
            ),
            Text(
              '+',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      } else {
        // Fallback to regular text
        chipLabel = Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      }
    } else {
      // For non-price labels like "All Prices"
      chipLabel = Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPriceRange = value;
        });
        filterProperties();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF39322) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: chipLabel,
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
            Text(
              error!,
              style: TextStyle(color: Colors.red[400], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchResidentialProperties,
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
            Icon(Icons.home_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No properties found',
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

  Widget _buildPropertyCard(PropertyListing property) {
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
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(property.imageUrl),
                        fit: BoxFit.cover,
                      ),
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
                        property.price.round().toDouble(),
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
                      if (property.bedrooms != null)
                        _buildPropertyFeature(
                          Icons.bed_outlined,
                          '${property.bedrooms}',
                        ),
                      if (property.bathrooms != null) ...[
                        const SizedBox(width: 16),
                        _buildPropertyFeature(
                          Icons.bathtub_outlined,
                          '${property.bathrooms}',
                        ),
                      ],
                      if (property.area != null) ...[
                        const SizedBox(width: 16),
                        _buildPropertyFeature(
                          Icons.square_foot_outlined,
                          '${property.area}m²',
                        ),
                      ],
                    ],
                  ),
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
                          feature.toString(),
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
  Widget _buildProspectSuggestions(PropertyListing property) {
    // Get random suggestions for this property
    final suggestions = PropertyProspectUtil.getRandomSuggestionsForType(
      PropertyType.residential,
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
              'Property Prospects',
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
                        color: const Color(0xFF000080).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF000080).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        suggestion.title,
                        style: const TextStyle(
                          color: Color(0xFF000080),
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

  Widget _buildPropertyFeature(IconData icon, String text) {
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
                'Filter Properties',
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
              // Add more filter options here
              ElevatedButton(
                onPressed: () {
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