import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'property_listings.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables for different property types
    await db.execute('''
      CREATE TABLE residential_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        location TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        bedrooms INTEGER,
        bathrooms INTEGER,
        area REAL,
        description TEXT,
        features TEXT,
        isFeatured INTEGER DEFAULT 0,
        status TEXT DEFAULT 'for_sale'
      )
    ''');

    await db.execute('''
      CREATE TABLE commercial_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        location TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        propertyType TEXT NOT NULL,
        area REAL,
        description TEXT,
        features TEXT,
        isFeatured INTEGER DEFAULT 0,
        status TEXT DEFAULT 'for_sale',
        floors INTEGER,
        parkingSpaces INTEGER,
        yearBuilt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE land_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        location TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        landType TEXT NOT NULL,
        area REAL,
        areaUnit TEXT,
        description TEXT,
        features TEXT,
        isFeatured INTEGER DEFAULT 0,
        status TEXT DEFAULT 'for_sale',
        titleDocument TEXT,
        surveyed INTEGER,
        zoning TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE material_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        location TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        materialType TEXT NOT NULL,
        quantity TEXT,
        description TEXT,
        features TEXT,
        isFeatured INTEGER DEFAULT 0,
        status TEXT DEFAULT 'available',
        condition TEXT,
        brand TEXT,
        warranty TEXT
      )
    ''');

    // Insert initial data
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Insert residential properties
    final residentialData = [
      {
        'title': 'Modern 3 Bedroom Apartment',
        'price': 25000000.0,
        'location': 'Lekki, Lagos',
        'imageUrl': 'assets/images/residential1.jpg',
        'category': 'apartment',
        'bedrooms': 3,
        'bathrooms': 2,
        'area': 120.5,
        'description': 'A beautifully designed modern apartment with contemporary finishes and stunning city views.',
        'features': 'Swimming Pool,Gym,24/7 Security,Parking Space,Generator',
        'isFeatured': 1,
        'status': 'for_sale'
      },
      {
        'title': 'Luxury Villa with Pool',
        'price': 75000000.0,
        'location': 'Ikoyi, Lagos',
        'imageUrl': 'assets/images/residential2.jpg',
        'category': 'villa',
        'bedrooms': 5,
        'bathrooms': 4,
        'area': 350.0,
        'description': 'Luxurious villa featuring private pool, garden, and high-end finishes throughout.',
        'features': 'Private Pool,Garden,Maid\'s Quarters,Garage,Security System',
        'isFeatured': 1,
        'status': 'for_sale'
      },
      {
        'title': 'Cozy 2 Bedroom Flat',
        'price': 15000000.0,
        'location': 'Yaba, Lagos',
        'imageUrl': 'assets/images/residential3.jpg',
        'category': 'flat',
        'bedrooms': 2,
        'bathrooms': 1,
        'area': 85.0,
        'description': 'Perfect starter home in a vibrant neighborhood with easy access to amenities.',
        'features': 'Fitted Kitchen,Wardrobe,Tile Flooring,Water Supply',
        'isFeatured': 1,
        'status': 'for_sale'
      },
      {
        'title': 'Executive 4 Bedroom Duplex',
        'price': 45000000.0,
        'location': 'Ajah, Lagos',
        'imageUrl': 'assets/images/residential4.jpg',
        'category': 'duplex',
        'bedrooms': 4,
        'bathrooms': 3,
        'area': 200.0,
        'description': 'Spacious duplex with modern amenities in a gated community.',
        'features': 'Gated Community,Parking,Generator,Water Treatment,CCTV',
        'isFeatured': 0,
        'status': 'for_sale'
      },
      {
        'title': 'Furnished 1 Bedroom Apartment',
        'price': 2500000.0,
        'location': 'Victoria Island, Lagos',
        'imageUrl': 'assets/images/residential5.jpg',
        'category': 'apartment',
        'bedrooms': 1,
        'bathrooms': 1,
        'area': 65.0,
        'description': 'Fully furnished apartment available for rent in prime location.',
        'features': 'Fully Furnished,WiFi,Cleaning Service,Security',
        'isFeatured': 0,
        'status': 'for_rent'
      },
      {
        'title': 'Family Home with Garden',
        'price': 35000000.0,
        'location': 'Magodo, Lagos',
        'imageUrl': 'assets/images/residential6.jpg',
        'category': 'house',
        'bedrooms': 4,
        'bathrooms': 3,
        'area': 180.0,
        'description': 'Beautiful family home with spacious garden and modern facilities.',
        'features': 'Garden,Garage,Study Room,Store Room,Security',
        'isFeatured': 0,
        'status': 'for_sale'
      }
    ];

    // Insert commercial properties
    final commercialData = [
      {
        'title': 'Premium Office Space',
        'price': 45000000.0,
        'location': 'Victoria Island, Lagos',
        'imageUrl': 'assets/images/commercial1.jpg',
        'propertyType': 'office',
        'area': 250.0,
        'description': 'Modern office space with stunning views and premium finishes in the heart of Victoria Island.',
        'features': '24/7 Security,Elevator,Air Conditioning,Generator,Reception Area',
        'isFeatured': 1,
        'status': 'for_sale',
        'floors': 3,
        'parkingSpaces': 20,
        'yearBuilt': '2020'
      },
      {
        'title': 'Retail Shop in Mall',
        'price': 35000000.0,
        'location': 'Ikeja, Lagos',
        'imageUrl': 'assets/images/commercial2.jpg',
        'propertyType': 'retail',
        'area': 150.0,
        'description': 'Prime retail space in busy shopping mall with high foot traffic.',
        'features': 'High Foot Traffic,Mall Security,Parking Available,Storage Space',
        'isFeatured': 1,
        'status': 'for_sale',
        'floors': 1,
        'parkingSpaces': 50,
        'yearBuilt': '2018'
      },
      {
        'title': 'Large Warehouse Facility',
        'price': 85000000.0,
        'location': 'Apapa, Lagos',
        'imageUrl': 'assets/images/commercial3.jpg',
        'propertyType': 'warehouse',
        'area': 1500.0,
        'description': 'Spacious warehouse with loading docks and easy access to major highways.',
        'features': 'Loading Docks,High Ceiling,Security Fence,Office Space,Truck Access',
        'isFeatured': 1,
        'status': 'for_sale',
        'floors': 1,
        'parkingSpaces': 30,
        'yearBuilt': '2019'
      }
    ];

    // Insert land properties
    final landData = [
      {
        'title': 'Prime Residential Plot',
        'price': 18000000.0,
        'location': 'Ajah, Lagos',
        'imageUrl': 'assets/images/land1.png',
        'landType': 'residential',
        'area': 500.0,
        'areaUnit': 'sqm',
        'description': 'Well-located residential plot in a developing area with good access roads and infrastructure.',
        'features': 'Good Access Road,Electricity Available,Water Source,Survey Plan',
        'isFeatured': 1,
        'status': 'for_sale',
        'titleDocument': 'Certificate of Occupancy',
        'surveyed': 1,
        'zoning': 'Residential'
      },
      {
        'title': 'Commercial Land',
        'price': 65000000.0,
        'location': 'Ikeja, Lagos',
        'imageUrl': 'assets/images/land2.jpg',
        'landType': 'commercial',
        'area': 1200.0,
        'areaUnit': 'sqm',
        'description': 'Strategic commercial land perfect for shopping centers, offices, or mixed-use development.',
        'features': 'Corner Piece,High Traffic Area,Approved Building Plan,Utilities Available',
        'isFeatured': 1,
        'status': 'for_sale',
        'titleDocument': 'Deed of Assignment',
        'surveyed': 1,
        'zoning': 'Commercial'
      },
      {
        'title': 'Agricultural Farmland',
        'price': 12000000.0,
        'location': 'Epe, Lagos',
        'imageUrl': 'assets/images/land3.jpg',
        'landType': 'agricultural',
        'area': 5.0,
        'areaUnit': 'acres',
        'description': 'Fertile agricultural land suitable for farming, livestock, or agribusiness investment.',
        'features': 'Fertile Soil,Water Source,Farm Access Road,Organic Certification Possible',
        'isFeatured': 1,
        'status': 'for_sale',
        'titleDocument': 'Survey Plan',
        'surveyed': 1,
        'zoning': 'Agricultural'
      }
    ];

    // Insert material properties
    final materialData = [
      {
        'title': 'Premium Cement',
        'price': 150000.0,
        'location': 'Nationwide Delivery',
        'imageUrl': 'assets/images/material1.jpg',
        'materialType': 'building',
        'quantity': '100 bags',
        'description': 'High-quality cement suitable for all construction needs with fast setting time.',
        'features': 'Fast Setting,Weather Resistant,High Strength,Bulk Discount Available',
        'isFeatured': 1,
        'status': 'available',
        'condition': 'new',
        'brand': 'Dangote',
        'warranty': '30 days'
      },
      {
        'title': 'Sand (30 tons)',
        'price': 85000.0,
        'location': 'Lagos Mainland',
        'imageUrl': 'assets/images/material2.jpg',
        'materialType': 'building',
        'quantity': '30 tons',
        'description': 'Clean, washed sand suitable for construction and landscaping projects.',
        'features': 'Washed,Screened,Free Delivery,Quality Tested',
        'isFeatured': 1,
        'status': 'available',
        'condition': 'new',
        'brand': null,
        'warranty': null
      },
      {
        'title': 'Roofing Sheets',
        'price': 250000.0,
        'location': 'Lagos State',
        'imageUrl': 'assets/images/material3.jpg',
        'materialType': 'building',
        'quantity': '50 sheets',
        'description': 'Durable aluminum roofing sheets with long-lasting finish and weather resistance.',
        'features': 'Corrosion Resistant,UV Protected,Easy Installation,15 Year Warranty',
        'isFeatured': 1,
        'status': 'available',
        'condition': 'new',
        'brand': 'Kingspan',
        'warranty': '15 years'
      }
    ];

    // Insert data into tables
    for (final property in residentialData) {
      await db.insert('residential_properties', property);
    }

    for (final property in commercialData) {
      await db.insert('commercial_properties', property);
    }

    for (final property in landData) {
      await db.insert('land_properties', property);
    }

    for (final property in materialData) {
      await db.insert('material_properties', property);
    }
  }

  // CRUD Operations for Residential Properties
  Future<List<Map<String, dynamic>>> getResidentialProperties() async {
    final db = await database;
    return await db.query('residential_properties');
  }

  Future<List<Map<String, dynamic>>> getResidentialPropertiesByFilter({
    String? status,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null && status != 'all') {
      whereClause += 'status = ?';
      whereArgs.add(status);
    }

    if (category != null && category != 'all') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (minPrice != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'price >= ?';
      whereArgs.add(minPrice);
    }

    if (maxPrice != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'price <= ?';
      whereArgs.add(maxPrice);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(title LIKE ? OR location LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    return await db.query(
      'residential_properties',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  // CRUD Operations for Commercial Properties
  Future<List<Map<String, dynamic>>> getCommercialProperties() async {
    final db = await database;
    return await db.query('commercial_properties');
  }

  Future<List<Map<String, dynamic>>> getCommercialPropertiesByFilter({
    String? status,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status != null && status != 'all') {
      whereClause += 'status = ?';
      whereArgs.add(status);
    }

    if (propertyType != null && propertyType != 'all') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'propertyType = ?';
      whereArgs.add(propertyType);
    }

    if (minPrice != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'price >= ?';
      whereArgs.add(minPrice);
    }

    if (maxPrice != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'price <= ?';
      whereArgs.add(maxPrice);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(title LIKE ? OR location LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    return await db.query(
      'commercial_properties',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  // CRUD Operations for Land Properties
  Future<List<Map<String, dynamic>>> getLandProperties() async {
    final db = await database;
    return await db.query('land_properties');
  }

  Future<List<Map<String, dynamic>>> getLandPropertiesByFilter({
    String? landType,
    String? areaFilter,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (landType != null && landType != 'all') {
      whereClause += 'landType = ?';
      whereArgs.add(landType);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(title LIKE ? OR location LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    // Handle area filter separately since it requires complex logic
    List<Map<String, dynamic>> results = await db.query(
      'land_properties',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    if (areaFilter != null && areaFilter != 'all') {
      results = results.where((property) {
        final double area = property['area'] as double;
        final String areaUnit = property['areaUnit'] as String;
        
        switch (areaFilter) {
          case 'small':
            if (areaUnit == 'acres') {
              return area <= 2;
            } else {
              return area <= 600;
            }
          case 'medium':
            if (areaUnit == 'acres') {
              return area > 2 && area <= 10;
            } else {
              return area > 600 && area <= 1500;
            }
          case 'large':
            if (areaUnit == 'acres') {
              return area > 10;
            } else {
              return area > 1500;
            }
          default:
            return true;
        }
      }).toList();
    }

    return results;
  }

  // CRUD Operations for Material Properties
  Future<List<Map<String, dynamic>>> getMaterialProperties() async {
    final db = await database;
    return await db.query('material_properties');
  }

  Future<List<Map<String, dynamic>>> getMaterialPropertiesByFilter({
    String? materialType,
    String? condition,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (materialType != null && materialType != 'all') {
      whereClause += 'materialType = ?';
      whereArgs.add(materialType);
    }

    if (condition != null && condition != 'all') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'condition = ?';
      whereArgs.add(condition);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(title LIKE ? OR location LIKE ? OR brand LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    return await db.query(
      'material_properties',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  // Helper method to check if database exists and has data
  Future<bool> isDatabaseInitialized() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM residential_properties')
      );
      return count != null && count > 0;
    } catch (e) {
      return false;
    }
  }

  // Reset database (for testing)
  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('residential_properties');
    await db.delete('commercial_properties');
    await db.delete('land_properties');
    await db.delete('material_properties');
    await _insertInitialData(db);
  }
}