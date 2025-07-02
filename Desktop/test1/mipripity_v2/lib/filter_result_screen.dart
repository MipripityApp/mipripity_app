import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'filtered_property_details_screen.dart';

class FilterResultScreen extends StatefulWidget {
  final Map<String, dynamic> filters;
  final String category;

  const FilterResultScreen({
    Key? key,
    required this.filters,
    required this.category,
  }) : super(key: key);

  @override
  State<FilterResultScreen> createState() => _FilterResultScreenState();
}

class _FilterResultScreenState extends State<FilterResultScreen> {
  String selectedView = 'list'; // 'list' or 'grid'
  String sortBy = 'newest'; // 'newest', 'price_low', 'price_high', 'popular'
  bool showFilters = false;
  
  // Sample filtered properties based on category
  late List<Map<String, dynamic>> filteredProperties;
  late List<Map<String, dynamic>> allProperties;

  @override
  void initState() {
    super.initState();
    _initializeProperties();
    _applyFilters();
  }

  void _initializeProperties() {
    // Initialize properties based on category
    switch (widget.category.toLowerCase()) {
      case 'residential':
        allProperties = _getResidentialProperties();
        break;
      case 'commercial':
        allProperties = _getCommercialProperties();
        break;
      case 'land':
        allProperties = _getLandProperties();
        break;
      case 'material':
        allProperties = _getMaterialProperties();
        break;
      default:
        allProperties = _getAllProperties();
    }
  }

  void _applyFilters() {
    filteredProperties = List.from(allProperties);
    
    // Apply filters based on the filter map
    if (widget.filters.isNotEmpty) {
      filteredProperties = filteredProperties.where((property) {
        // Apply price filter
        if (widget.filters.containsKey('minPrice') && widget.filters.containsKey('maxPrice')) {
          final minPrice = widget.filters['minPrice'] as double;
          final maxPrice = widget.filters['maxPrice'] as double;
          final propertyPrice = _extractPrice(property['price']);
          if (propertyPrice < minPrice || propertyPrice > maxPrice) {
            return false;
          }
        }
        
        // Apply state filter
        if (widget.filters.containsKey('state') && 
            widget.filters['state'] != null && 
            widget.filters['state'].isNotEmpty) {
          if (!property['location'].toLowerCase().contains(
              widget.filters['state'].toLowerCase())) {
            return false;
          }
        }
        
        // Apply LGA filter
        if (widget.filters.containsKey('lgas') && 
            widget.filters['lgas'] != null && 
            (widget.filters['lgas'] as List).isNotEmpty) {
          bool matchesAnyLga = false;
          for (final lga in widget.filters['lgas'] as List) {
            if (property['location'].toLowerCase().contains(lga.toLowerCase())) {
              matchesAnyLga = true;
              break;
            }
          }
          if (!matchesAnyLga) {
            return false;
          }
        }
        
        // Apply property type filter
        if (widget.filters.containsKey('type') && 
            widget.filters['type'] != null && 
            widget.filters['type'].isNotEmpty) {
          if (property['type'].toLowerCase() != 
              widget.filters['type'].toLowerCase()) {
            return false;
          }
        }
        
        // Apply function filter (Buy, Rent, Lease)
        if (widget.filters.containsKey('function') && 
            widget.filters['function'] != null && 
            widget.filters['function'].isNotEmpty) {
          if (property['function'] != null && 
              property['function'].toLowerCase() != 
              widget.filters['function'].toLowerCase()) {
            return false;
          }
        }
        
        // Apply quantity filter (for land and material)
        if (widget.filters.containsKey('quantity') && 
            widget.filters['quantity'] != null && 
            widget.filters['quantity'].isNotEmpty) {
          if (property['quantity'] == null || 
              property['quantity'] != widget.filters['quantity']) {
            return false;
          }
        }
        
        // Apply category filter
        if (widget.filters.containsKey('category') && 
            widget.filters['category'] != null && 
            widget.filters['category'].isNotEmpty) {
          if (property['category'] != widget.filters['category']) {
            return false;
          }
        }
        
        return true;
      }).toList();
    }
    
    _applySorting();
  }

  void _applySorting() {
    switch (sortBy) {
      case 'price_low':
        filteredProperties.sort((a, b) => 
            _extractPrice(a['price']).compareTo(_extractPrice(b['price'])));
        break;
      case 'price_high':
        filteredProperties.sort((a, b) => 
            _extractPrice(b['price']).compareTo(_extractPrice(a['price'])));
        break;
      case 'popular':
        filteredProperties.sort((a, b) => 
            (b['views'] ?? 0).compareTo(a['views'] ?? 0));
        break;
      case 'newest':
      default:
        // Keep original order (newest first)
        break;
    }
  }

  double _extractPrice(String priceString) {
    // Extract numeric value from price string like "₦45,000,000"
    final numericString = priceString.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(numericString) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.category.substring(0, 1).toUpperCase()}${widget.category.substring(1)} Properties',
              style: const TextStyle(
                color: Color(0xFF000080),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${filteredProperties.length} properties found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              selectedView == 'list' ? Icons.grid_view : Icons.list,
              color: const Color(0xFF000080),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                selectedView = selectedView == 'list' ? 'grid' : 'list';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF000080)),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSortBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Summary
          if (widget.filters.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Filters:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildFilterChips(),
                  ),
                ],
              ),
            ),
          
          // Properties List/Grid
          Expanded(
            child: filteredProperties.isEmpty
                ? _buildEmptyState()
                : selectedView == 'list'
                    ? _buildListView()
                    : _buildGridView(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    List<Widget> chips = [];
    
    widget.filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        String chipText = '';
        
        switch (key) {
          case 'minPrice':
          case 'maxPrice':
            // Skip individual price values, they'll be combined
            if (key == 'minPrice' && widget.filters.containsKey('maxPrice')) {
              final min = widget.filters['minPrice'] as double;
              final max = widget.filters['maxPrice'] as double;
              chipText = '₦${_formatPrice(min)} - ₦${_formatPrice(max)}';
              chips.add(_buildFilterChip(chipText));
            }
            break;
          case 'state':
            chipText = 'State: $value';
            chips.add(_buildFilterChip(chipText));
            break;
          case 'lgas':
            if ((value as List).isNotEmpty) {
              chipText = 'LGAs: ${(value).length} selected';
              chips.add(_buildFilterChip(chipText));
            }
            break;
          case 'type':
            chipText = 'Type: $value';
            chips.add(_buildFilterChip(chipText));
            break;
          case 'function':
            chipText = 'Function: $value';
            chips.add(_buildFilterChip(chipText));
            break;
          case 'quantity':
            chipText = 'Quantity: $value';
            chips.add(_buildFilterChip(chipText));
            break;
          case 'category':
            // Skip category, it's already in the title
            break;
          default:
            if (key != 'minPrice' && key != 'maxPrice') {
              chipText = '$key: $value';
              chips.add(_buildFilterChip(chipText));
            }
        }
      }
    });
    
    return chips;
  }

  Widget _buildFilterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF000080).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF000080).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF000080),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No properties found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Modify Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProperties.length,
      itemBuilder: (context, index) {
        final property = filteredProperties[index];
        return _buildPropertyListCard(property);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredProperties.length,
      itemBuilder: (context, index) {
        final property = filteredProperties[index];
        return _buildPropertyGridCard(property);
      },
    );
  }

  Widget _buildPropertyListCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilteredPropertyDetailsScreen(
              propertyId: property['id'],
            ),
          ),
        );
      },
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
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                if (property['isVerified'] == true)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property['location'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      if (property.containsKey('bedrooms'))
                        Row(
                          children: [
                            _buildFeatureChip(Icons.bed, '${property['bedrooms']}'),
                            const SizedBox(width: 8),
                            _buildFeatureChip(Icons.bathtub, '${property['bathrooms']}'),
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
  }

  Widget _buildPropertyGridCard(Map<String, dynamic> property) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilteredPropertyDetailsScreen(
              propertyId: property['id'],
            ),
          ),
        );
      },
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
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      property['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000080),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        property['type'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (property['isVerified'] == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            property['location'],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            property['price'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF39322),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (property.containsKey('bedrooms'))
                          Row(
                            children: [
                              _buildSmallFeatureChip(Icons.bed, '${property['bedrooms']}'),
                              const SizedBox(width: 4),
                              _buildSmallFeatureChip(Icons.bathtub, '${property['bathrooms']}'),
                            ],
                          ),
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

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
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

  Widget _buildSmallFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey[700]),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('Newest First', 'newest'),
            _buildSortOption('Price: Low to High', 'price_low'),
            _buildSortOption('Price: High to Low', 'price_high'),
            _buildSortOption('Most Popular', 'popular'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: sortBy == value
          ? const Icon(Icons.check, color: Color(0xFF000080))
          : null,
      onTap: () {
        setState(() {
          sortBy = value;
          _applySorting();
        });
        Navigator.pop(context);
      },
    );
  }

  // Sample data methods
  List<Map<String, dynamic>> _getResidentialProperties() {
    return [
      {
        'id': 'r1',
        'title': '3 Bedroom Apartment',
        'type': 'Apartment',
        'price': '₦45,000,000',
        'location': 'Lekki Phase 1, Lagos',
        'bedrooms': 3,
        'bathrooms': 2,
        'area': '120 sqm',
        'image': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914',
        'isVerified': true,
        'views': 150,
        'category': 'residential',
        'function': 'Buy',
      },
      {
        'id': 'r2',
        'title': '4 Bedroom Duplex',
        'type': 'Duplex',
        'price': '₦75,000,000',
        'location': 'Ikeja GRA, Lagos',
        'bedrooms': 4,
        'bathrooms': 3,
        'area': '200 sqm',
        'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
        'isVerified': true,
        'views': 200,
        'category': 'residential',
        'function': 'Rent',
      },
      {
        'id': 'r3',
        'title': 'Luxury 5 Bedroom Villa',
        'type': 'Villa',
        'price': '₦120,000,000',
        'location': 'Banana Island, Lagos',
        'bedrooms': 5,
        'bathrooms': 6,
        'area': '350 sqm',
        'image': 'https://images.unsplash.com/photo-1613977257363-707ba9348227',
        'isVerified': true,
        'views': 300,
        'category': 'residential',
        'function': 'Buy',
      },
      {
        'id': 'r4',
        'title': '2 Bedroom Apartment',
        'type': '2 Bedroom Flat',
        'price': '₦35,000,000',
        'location': 'Victoria Island, Lagos',
        'bedrooms': 2,
        'bathrooms': 2,
        'area': '90 sqm',
        'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750',
        'isVerified': true,
        'views': 180,
        'category': 'residential',
        'function': 'Lease',
      },
      {
        'id': 'r5',
        'title': 'Studio Apartment',
        'type': 'Studio Apartment',
        'price': '₦25,000,000',
        'location': 'Yaba, Lagos',
        'bedrooms': 1,
        'bathrooms': 1,
        'area': '45 sqm',
        'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
        'isVerified': false,
        'views': 120,
        'category': 'residential',
        'function': 'Rent',
      },
    ];
  }

  List<Map<String, dynamic>> _getCommercialProperties() {
    return [
      {
        'id': 'c1',
        'title': 'Office Space',
        'type': 'Office',
        'price': '���80,000,000',
        'location': 'Victoria Island, Lagos',
        'area': '250 sqm',
        'image': 'https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6',
        'isVerified': true,
        'views': 120,
        'category': 'commercial',
        'function': 'Rent',
      },
      {
        'id': 'c2',
        'title': 'Retail Store',
        'type': 'Store',
        'price': '₦60,000,000',
        'location': 'Ikeja, Lagos',
        'area': '150 sqm',
        'image': 'https://images.unsplash.com/photo-1604014237800-1c9102c219da',
        'isVerified': true,
        'views': 90,
        'category': 'commercial',
        'function': 'Buy',
      },
      {
        'id': 'c3',
        'title': 'Warehouse Space',
        'type': 'Warehouse',
        'price': '₦120,000,000',
        'location': 'Apapa, Lagos',
        'area': '1000 sqm',
        'image': 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d',
        'isVerified': true,
        'views': 70,
        'category': 'commercial',
        'function': 'Lease',
      },
      {
        'id': 'c4',
        'title': 'Factory Building',
        'type': 'Factory',
        'price': '₦200,000,000',
        'location': 'Agbara, Lagos',
        'area': '2000 sqm',
        'image': 'https://images.unsplash.com/photo-1565793298595-6a879b1d9492',
        'isVerified': false,
        'views': 50,
        'category': 'commercial',
        'function': 'Buy',
      },
    ];
  }

  List<Map<String, dynamic>> _getLandProperties() {
    return [
      {
        'id': 'l1',
        'title': 'Prime Land',
        'type': 'Plot',
        'price': '₦25,000,000',
        'location': 'Lekki Phase 2, Lagos',
        'area': '500 sqm',
        'image': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef',
        'isVerified': true,
        'views': 80,
        'category': 'land',
        'function': 'Buy',
        'quantity': '1',
      },
      {
        'id': 'l2',
        'title': 'Agricultural Land',
        'type': 'Hectare',
        'price': '₦50,000,000',
        'location': 'Epe, Lagos',
        'area': '10000 sqm',
        'image': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
        'isVerified': true,
        'views': 60,
        'category': 'land',
        'function': 'Lease',
        'quantity': 'Above 10',
      },
      {
        'id': 'l3',
        'title': 'Residential Land',
        'type': 'Plot',
        'price': '₦30,000,000',
        'location': 'Ajah, Lagos',
        'area': '600 sqm',
        'image': 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
        'isVerified': false,
        'views': 70,
        'category': 'land',
        'function': 'Buy',
        'quantity': '1',
      },
      {
        'id': 'l4',
        'title': 'Commercial Land',
        'type': 'Acre',
        'price': '₦100,000,000',
        'location': 'Ikeja, Lagos',
        'area': '4000 sqm',
        'image': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef',
        'isVerified': true,
        'views': 90,
        'category': 'land',
        'function': 'Buy',
        'quantity': '5',
      },
    ];
  }

  List<Map<String, dynamic>> _getMaterialProperties() {
    return [
      {
        'id': 'm1',
        'title': 'Premium Cement',
        'type': 'Cement',
        'price': '₦2,500,000',
        'location': 'Ikeja, Lagos',
        'image': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd',
        'isVerified': true,
        'views': 60,
        'category': 'material',
        'quantity': '51-100 Bags',
      },
      {
        'id': 'm2',
        'title': 'Luxury Furniture Set',
        'type': 'Sofa',
        'price': '₦1,800,000',
        'location': 'Victoria Island, Lagos',
        'image': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc',
        'isVerified': true,
        'views': 80,
        'category': 'material',
        'quantity': '2-3 Sets',
      },
      {
        'id': 'm3',
        'title': 'Premium Tiles',
        'type': 'Tiles',
        'price': '₦900,000',
        'location': 'Lekki, Lagos',
        'image': 'https://images.unsplash.com/photo-1502005229762-cf1b2da7c5d6',
        'isVerified': false,
        'views': 40,
        'category': 'material',
        'quantity': '11-50 Cartons',
      },
      {
        'id': 'm4',
        'title': 'Air Conditioners',
        'type': 'A.C',
        'price': '₦750,000',
        'location': 'Surulere, Lagos',
        'image': 'https://images.unsplash.com/photo-1585770536735-27993a080586',
        'isVerified': true,
        'views': 70,
        'category': 'material',
        'quantity': '2-5',
      },
    ];
  }

  List<Map<String, dynamic>> _getAllProperties() {
    return [
      ..._getResidentialProperties(),
      ..._getCommercialProperties(),
      ..._getLandProperties(),
      ..._getMaterialProperties(),
    ];
  }
}
