import 'package:flutter/material.dart';
import 'dart:convert';
import 'api/property_api.dart';
import 'utils/currency_formatter.dart';

class MaterialProperty {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final String materialType; // furniture, building materials, fixtures, etc.
  final String? quantity;
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status; // 'available', 'sold'
  final String? condition; // 'new', 'used', 'refurbished'
  final String? brand;
  final String? warranty;

  MaterialProperty({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.materialType,
    this.quantity,
    required this.description,
    required this.features,
    this.isFeatured = false,
    this.status = 'available',
    this.condition,
    this.brand,
    this.warranty,
  });

  factory MaterialProperty.fromJson(Map<String, dynamic> json) {
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

    return MaterialProperty(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      price: json['price'] is double 
          ? json['price'] 
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      location: json['location'] ?? '',
      imageUrl: imageUrl,
      materialType: json['type'] ?? json['materialType'] ?? 'building',
      quantity: json['quantity']?.toString(),
      description: json['description'] ?? '',
      features: parsedFeatures,
      isFeatured: json['isFeatured'] == 1 || json['is_featured'] == true || json['category'] == 'premium',
      status: json['status'] ?? 'available',
      condition: json['condition'],
      brand: json['brand'],
      warranty: json['warranty'],
    );
  }
}

class MaterialPropertiesScreen extends StatefulWidget {
  const MaterialPropertiesScreen({super.key});

  @override
  State<MaterialPropertiesScreen> createState() => _MaterialPropertiesScreenState();
}

class _MaterialPropertiesScreenState extends State<MaterialPropertiesScreen> {
  List<MaterialProperty> materials = [];
  List<MaterialProperty> filteredMaterials = [];
  bool isLoading = true;
  String? error;
  String selectedTypeFilter = 'all'; // all, furniture, building, fixtures, etc.
  String selectedConditionFilter = 'all'; // all, new, used, refurbished
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchMaterialProperties();
  }

Future<void> fetchMaterialProperties() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    // Get material properties using the PropertyApi
    final propertiesData = await PropertyApi.getPropertiesByCategory('material');
    
    // Convert to MaterialProperty objects
    final List<MaterialProperty> loadedMaterials = propertiesData
        .map((json) => MaterialProperty.fromJson(json))
        .toList();

    setState(() {
      materials = loadedMaterials;
      filteredMaterials = loadedMaterials;
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      error = 'Error loading materials: $e';
      isLoading = false;
    });
    print('Error fetching material properties: $e');
  }
}

void filterMaterials() {
  setState(() {
    isLoading = true;
  });
  
  // Try to use API-based filtering first
  _filterMaterialsUsingApi();
}

// Method to filter materials using the API
Future<void> _filterMaterialsUsingApi() async {
  try {
    // Determine material type filter
    final String? materialType = selectedTypeFilter != 'all' ? selectedTypeFilter : null;
    
    // Determine condition filter
    final String? condition = selectedConditionFilter != 'all' ? selectedConditionFilter : null;
    
    // Use the API's filtering method
    final propertiesData = await PropertyApi.getMaterialPropertiesWithFilter(
      materialType: materialType,
      condition: condition,
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
    );
    
    final List<MaterialProperty> filtered = propertiesData
        .map((json) => MaterialProperty.fromJson(json))
        .toList();
    
    setState(() {
      filteredMaterials = filtered;
      isLoading = false;
    });
  } catch (e) {
    print('Error filtering materials using API: $e');
    
    // Fallback to local filtering if API filtering fails
    _filterMaterialsLocally();
  }
}

// Fallback method for local filtering
void _filterMaterialsLocally() {
  List<MaterialProperty> filtered = materials;

  // Filter by material type
  if (selectedTypeFilter != 'all') {
    filtered = filtered.where((material) => material.materialType == selectedTypeFilter).toList();
  }

  // Filter by condition
  if (selectedConditionFilter != 'all') {
    filtered = filtered.where((material) => material.condition == selectedConditionFilter).toList();
  }

  // Filter by search query
  if (searchQuery.isNotEmpty) {
    filtered = filtered.where((material) =>
      material.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
      material.location.toLowerCase().contains(searchQuery.toLowerCase()) ||
      material.materialType.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (material.brand != null && material.brand!.toLowerCase().contains(searchQuery.toLowerCase()))
    ).toList();
  }

  setState(() {
    filteredMaterials = filtered;
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

  String getMaterialTypeIcon(String type) {
    switch (type) {
      case 'building':
        return '🧱';
      case 'furniture':
        return '🪑';
      case 'fixtures':
        return '🚿';
      case 'appliances':
        return '🔌';
      default:
        return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Building Materials',
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
                hintText: 'Search materials...',
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
                filterMaterials();
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
                        _buildTypeFilterChip('Building', 'building', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Furniture', 'furniture', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Fixtures', 'fixtures', selectedTypeFilter),
                        const SizedBox(width: 8),
                        _buildTypeFilterChip('Appliances', 'appliances', selectedTypeFilter),
                        const SizedBox(width: 16),
                        _buildConditionFilterChip('All Conditions', 'all', selectedConditionFilter),
                        const SizedBox(width: 8),
                        _buildConditionFilterChip('New', 'new', selectedConditionFilter),
                        const SizedBox(width: 8),
                        _buildConditionFilterChip('Used', 'used', selectedConditionFilter),
                        const SizedBox(width: 8),
                        _buildConditionFilterChip('Refurbished', 'refurbished', selectedConditionFilter),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Materials List
          Expanded(
            child: _buildMaterialsList(),
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
        filterMaterials();
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

  Widget _buildConditionFilterChip(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedConditionFilter = value;
        });
        filterMaterials();
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

  Widget _buildMaterialsList() {
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
              'Error loading materials',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Colors.red[400], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchMaterialProperties,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No materials found',
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
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index];
        return _buildMaterialCard(material);
      },
    );
  }

  Widget _buildMaterialCard(MaterialProperty material) {
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
          _showMaterialDetails(material);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Image
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
                        image: NetworkImage(material.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                if (material.isFeatured)
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
                      color: material.status == 'available' 
                        ? const Color(0xFF000080)
                        : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      material.status.toUpperCase(),
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
                          getMaterialTypeIcon(material.materialType),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          material.materialType.toUpperCase(),
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
            
            // Material Details
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
                          material.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                      getNairaRichText(
                        material.price,
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
                          material.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Material Features
                  Row(
                    children: [
                      if (material.quantity != null)
                        _buildFeatureItem(Icons.inventory_2, material.quantity!),
                      if (material.condition != null) ...[
                        const SizedBox(width: 16),
                        _buildFeatureItem(Icons.info_outline, material.condition!.toUpperCase()),
                      ],
                      if (material.brand != null) ...[
                        const SizedBox(width: 16),
                        _buildFeatureItem(Icons.business, material.brand!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    material.description,
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
                    children: material.features.take(3).map((feature) {
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

  void _showMaterialDetails(MaterialProperty material) {
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
                        // Material Image
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
                              material.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
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
                                material.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                            ),
                            Text(
                              getMaterialTypeIcon(material.materialType),
                              style: const TextStyle(fontSize: 30),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Price
                        getNairaRichText(
                          material.price,
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
                                material.location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Material Info
                        Row(
                          children: [
                            if (material.quantity != null)
                              Expanded(
                                child: _buildInfoCard('Quantity', material.quantity!),
                              ),
                            if (material.condition != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard('Condition', material.condition!.toUpperCase()),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            if (material.brand != null)
                              Expanded(
                                child: _buildInfoCard('Brand', material.brand!),
                              ),
                            if (material.warranty != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard('Warranty', material.warranty!),
                              ),
                            ],
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
                          material.description,
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
                          children: material.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Contact Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle call action
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('Call Seller'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000080),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Handle message action
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF39322),
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
                    'Filter Materials',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Material Type Filter
                  const Text(
                    'Material Type',
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
                      _buildFilterOption('Building', 'building', selectedTypeFilter, true),
                      _buildFilterOption('Furniture', 'furniture', selectedTypeFilter, true),
                      _buildFilterOption('Fixtures', 'fixtures', selectedTypeFilter, true),
                      _buildFilterOption('Appliances', 'appliances', selectedTypeFilter, true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Condition Filter
                  const Text(
                    'Condition',
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
                      _buildFilterOption('All Conditions', 'all', selectedConditionFilter, false),
                      _buildFilterOption('New', 'new', selectedConditionFilter, false),
                      _buildFilterOption('Used', 'used', selectedConditionFilter, false),
                      _buildFilterOption('Refurbished', 'refurbished', selectedConditionFilter, false),
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
                              selectedConditionFilter = 'all';
                              searchQuery = '';
                            });
                            filterMaterials();
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
                            filterMaterials();
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
            selectedConditionFilter = value;
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