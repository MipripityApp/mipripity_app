import 'package:flutter/material.dart';

class MaterialDetails extends StatefulWidget {
  final String materialId;

  const MaterialDetails({
    Key? key,
    required this.materialId,
  }) : super(key: key);

  @override
  State<MaterialDetails> createState() => _MaterialDetailsState();
}

class _MaterialDetailsState extends State<MaterialDetails> {
  bool isFavorite = false;
  int quantity = 1;

  // Sample material data - in a real app, this would be fetched based on materialId
  late Map<String, dynamic> materialData;

  // Sample seller data
  final Map<String, dynamic> sellerData = {
    'id': 's1',
    'name': 'Dangote Building Materials',
    'rating': 4.9,
    'sales': 1240,
    'location': 'Ikeja, Lagos',
    'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpQFTmSdzR1A8ziLD3wmIgBgyQ9idMcaHuMNtV764qL3OCD5dag13iHDYWBW7uEgn4chs&usqp=CAU',
  };

  // Sample similar materials
  final List<Map<String, dynamic>> similarMaterials = [
    {
      'id': 'm2',
      'title': 'Iron Rods (16mm)',
      'brand': 'Standard',
      'price': '₦7,200',
      'unit': 'per rod',
      'image': 'https://www.housingtvafrica.com/wp-content/uploads/2024/03/image-243.webp',
    },
    {
      'id': 'm3',
      'title': 'Granite Stone',
      'brand': 'Quality',
      'price': '₦45,000',
      'unit': 'per ton',
      'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Fly_Ash_Bricks.jpg/1200px-Fly_Ash_Bricks.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize material data based on ID
    // In a real app, this would be fetched from an API or database
    if (widget.materialId == 'm1') {
      materialData = {
        'id': 'm1',
        'title': 'Premium Cement',
        'brand': 'Dangote',
        'price': '₦4,500',
        'unit': 'per bag',
        'minOrder': 10,
        'available': 500,
        'description': 'High-quality cement suitable for all construction purposes. This premium cement ensures strong and durable construction with excellent binding properties. Ideal for foundations, columns, beams, and general construction work.',
        'specifications': [
          'Type: Portland Cement',
          'Weight: 50kg per bag',
          'Strength: 42.5N',
          'Setting Time: 45 minutes',
          'Packaging: Moisture-resistant bag',
        ],
        'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpQFTmSdzR1A8ziLD3wmIgBgyQ9idMcaHuMNtV764qL3OCD5dag13iHDYWBW7uEgn4chs&usqp=CAU',
        'rating': 4.8,
        'reviews': 156,
        'deliveryFee': '₦2,000',
        'deliveryTime': '1-2 days',
      };
    } else if (widget.materialId == 'm2') {
      materialData = {
        'id': 'm2',
        'title': 'Iron Rods (16mm)',
        'brand': 'Standard',
        'price': '₦7,200',
        'unit': 'per rod',
        'minOrder': 5,
        'available': 200,
        'description': 'High-quality 16mm iron rods for reinforced concrete structures. These durable iron rods provide excellent tensile strength and are essential for construction projects requiring strong structural support.',
        'specifications': [
          'Diameter: 16mm',
          'Length: 12 meters',
          'Grade: 60',
          'Yield Strength: 420 MPa',
          'Surface: Ribbed',
        ],
        'image': 'https://www.housingtvafrica.com/wp-content/uploads/2024/03/image-243.webp',
        'rating': 4.7,
        'reviews': 98,
        'deliveryFee': '₦3,500',
        'deliveryTime': '2-3 days',
      };
    } else {
      // Default material data
      materialData = {
        'id': widget.materialId,
        'title': 'Building Material',
        'brand': 'Generic',
        'price': '₦5,000',
        'unit': 'per unit',
        'minOrder': 1,
        'available': 100,
        'description': 'Quality building material for construction projects.',
        'specifications': [
          'Standard quality',
          'Durable material',
        ],
        'image': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Fly_Ash_Bricks.jpg/1200px-Fly_Ash_Bricks.jpg',
        'rating': 4.5,
        'reviews': 50,
        'deliveryFee': '₦2,500',
        'deliveryTime': '2-4 days',
      };
    }
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    
    if (isFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${materialData['title']} added to favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void handleAddToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity ${materialData['title']} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void handleBuyNow() {
    Navigator.pushNamed(context, '/checkout', arguments: {
      'materialId': widget.materialId,
      'quantity': quantity,
    });
  }

  void handleSellerClick(String sellerId) {
    Navigator.pushNamed(context, '/seller-profile/$sellerId');
  }

  void handleSimilarMaterialClick(String materialId) {
    Navigator.pushReplacementNamed(context, '/material/$materialId');
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = int.parse(materialData['price'].replaceAll('₦', '').replaceAll(',', '')) * quantity;
    final formattedTotalPrice = '₦${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Center(
                  child: Image.network(
                    materialData['image'],
                    fit: BoxFit.contain,
                    height: 200,
                  ),
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
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
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : const Color(0xFF000080),
                  ),
                  onPressed: toggleFavorite,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF000080)),
                  onPressed: () {
                    // Share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing this material...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF39322).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              materialData['brand'],
                              style: const TextStyle(
                                color: Color(0xFFF39322),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF39322),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${materialData['rating']} (${materialData['reviews']})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        materialData['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            materialData['price'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF39322),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            materialData['unit'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Quantity:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: decreaseQuantity,
                                  color: const Color(0xFF000080),
                                  iconSize: 18,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    quantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: increaseQuantity,
                                  color: const Color(0xFF000080),
                                  iconSize: 18,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${materialData['available']} available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Min. order: ${materialData['minOrder']} units',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Seller Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seller Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => handleSellerClick(sellerData['id']),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(sellerData['image']),
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
                                    sellerData['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFFF39322),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${sellerData['rating']} • ${sellerData['sales']} sales',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
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
                                      Text(
                                        sellerData['location'],
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000080),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Visit Store',
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Delivery Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF39322).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    color: Color(0xFFF39322),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Fee',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      materialData['deliveryFee'],
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
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF39322).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Color(0xFFF39322),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      materialData['deliveryTime'],
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        materialData['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Specifications
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Specifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        materialData['specifications'].length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF39322),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  materialData['specifications'][index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Similar Materials
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Similar Materials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similarMaterials.length,
                          itemBuilder: (context, index) {
                            final material = similarMaterials[index];
                            return GestureDetector(
                              onTap: () => handleSimilarMaterialClick(material['id']),
                              child: Container(
                                width: 180,
                                margin: EdgeInsets.only(
                                  right: index != similarMaterials.length - 1 ? 16 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
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
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        material['image'],
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            material['brand'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFF39322),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            material['title'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF000080),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                material['price'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                material['unit'],
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for bottom buttons
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  formattedTotalPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF39322),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: handleAddToCart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: handleBuyNow,
                      style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                      side: const BorderSide(color: Color(0xFF000080)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}