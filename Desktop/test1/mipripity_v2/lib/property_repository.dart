import 'database_helper.dart';

// Residential Property Model
class PropertyListing {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final String category;
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status;

  PropertyListing({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.bedrooms,
    this.bathrooms,
    this.area,
    required this.category,
    required this.description,
    required this.features,
    this.isFeatured = false,
    this.status = 'for_sale',
  });

  factory PropertyListing.fromMap(Map<String, dynamic> map) {
    return PropertyListing(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      price: map['price'] ?? 0.0,
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      bedrooms: map['bedrooms'],
      bathrooms: map['bathrooms'],
      area: map['area'],
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      features: map['features'] != null 
          ? (map['features'] as String).split(',') 
          : [],
      isFeatured: map['isFeatured'] == 1,
      status: map['status'] ?? 'for_sale',
    );
  }

  bool? get isFavorite => null;
}

// Commercial Property Model
class CommercialProperty {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final String propertyType;
  final double area;
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status;
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

  factory CommercialProperty.fromMap(Map<String, dynamic> map) {
    return CommercialProperty(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      price: map['price'] ?? 0.0,
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      propertyType: map['propertyType'] ?? '',
      area: map['area'] ?? 0.0,
      description: map['description'] ?? '',
      features: map['features'] != null 
          ? (map['features'] as String).split(',') 
          : [],
      isFeatured: map['isFeatured'] == 1,
      status: map['status'] ?? 'for_sale',
      floors: map['floors'],
      parkingSpaces: map['parkingSpaces'],
      yearBuilt: map['yearBuilt'],
    );
  }
}

// Land Property Model
class LandProperty {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final String landType;
  final double area;
  final String areaUnit;
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status;
  final String? titleDocument;
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

  factory LandProperty.fromMap(Map<String, dynamic> map) {
    return LandProperty(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      price: map['price'] ?? 0.0,
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      landType: map['landType'] ?? '',
      area: map['area'] ?? 0.0,
      areaUnit: map['areaUnit'] ?? 'sqm',
      description: map['description'] ?? '',
      features: map['features'] != null 
          ? (map['features'] as String).split(',') 
          : [],
      isFeatured: map['isFeatured'] == 1,
      status: map['status'] ?? 'for_sale',
      titleDocument: map['titleDocument'],
      surveyed: map['surveyed'] == 1,
      zoning: map['zoning'],
    );
  }
}

// Material Property Model
class MaterialProperty {
  final String id;
  final String title;
  final double price;
  final String location;
  final String imageUrl;
  final String materialType;
  final String? quantity;
  final String description;
  final List<String> features;
  final bool isFeatured;
  final String status;
  final String? condition;
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

  factory MaterialProperty.fromMap(Map<String, dynamic> map) {
    return MaterialProperty(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      price: map['price'] ?? 0.0,
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      materialType: map['materialType'] ?? '',
      quantity: map['quantity'],
      description: map['description'] ?? '',
      features: map['features'] != null 
          ? (map['features'] as String).split(',') 
          : [],
      isFeatured: map['isFeatured'] == 1,
      status: map['status'] ?? 'available',
      condition: map['condition'],
      brand: map['brand'],
      warranty: map['warranty'],
    );
  }
}

class PropertyRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Residential Properties
  Future<List<PropertyListing>> getResidentialProperties() async {
    try {
      final properties = await _databaseHelper.getResidentialProperties();
      return properties.map((map) => PropertyListing.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching residential properties: $e');
      return [];
    }
  }

  Future<List<PropertyListing>> getFilteredResidentialProperties({
    String? status,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    try {
      final properties = await _databaseHelper.getResidentialPropertiesByFilter(
        status: status,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        searchQuery: searchQuery,
      );
      return properties.map((map) => PropertyListing.fromMap(map)).toList();
    } catch (e) {
      print('Error filtering residential properties: $e');
      return [];
    }
  }

  // Commercial Properties
  Future<List<CommercialProperty>> getCommercialProperties() async {
    try {
      final properties = await _databaseHelper.getCommercialProperties();
      return properties.map((map) => CommercialProperty.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching commercial properties: $e');
      return [];
    }
  }

  Future<List<CommercialProperty>> getFilteredCommercialProperties({
    String? status,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    try {
      final properties = await _databaseHelper.getCommercialPropertiesByFilter(
        status: status,
        propertyType: propertyType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        searchQuery: searchQuery,
      );
      return properties.map((map) => CommercialProperty.fromMap(map)).toList();
    } catch (e) {
      print('Error filtering commercial properties: $e');
      return [];
    }
  }

  // Land Properties
  Future<List<LandProperty>> getLandProperties() async {
    try {
      final properties = await _databaseHelper.getLandProperties();
      return properties.map((map) => LandProperty.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching land properties: $e');
      return [];
    }
  }

  Future<List<LandProperty>> getFilteredLandProperties({
    String? landType,
    String? areaFilter,
    String? searchQuery,
  }) async {
    try {
      final properties = await _databaseHelper.getLandPropertiesByFilter(
        landType: landType,
        areaFilter: areaFilter,
        searchQuery: searchQuery,
      );
      return properties.map((map) => LandProperty.fromMap(map)).toList();
    } catch (e) {
      print('Error filtering land properties: $e');
      return [];
    }
  }

  // Material Properties
  Future<List<MaterialProperty>> getMaterialProperties() async {
    try {
      final properties = await _databaseHelper.getMaterialProperties();
      return properties.map((map) => MaterialProperty.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching material properties: $e');
      return [];
    }
  }

  Future<List<MaterialProperty>> getFilteredMaterialProperties({
    String? materialType,
    String? condition,
    String? searchQuery,
  }) async {
    try {
      final properties = await _databaseHelper.getMaterialPropertiesByFilter(
        materialType: materialType,
        condition: condition,
        searchQuery: searchQuery,
      );
      return properties.map((map) => MaterialProperty.fromMap(map)).toList();
    } catch (e) {
      print('Error filtering material properties: $e');
      return [];
    }
  }

  // Check if database is initialized
  Future<bool> isDatabaseReady() async {
    return await _databaseHelper.isDatabaseInitialized();
  }

  // Reset database (for testing)
  Future<void> resetDatabase() async {
    await _databaseHelper.resetDatabase();
  }
}