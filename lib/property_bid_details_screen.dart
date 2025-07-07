import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api/bids_api.dart';
import 'utils/currency_formatter.dart';
import 'screens/schedule_visit_screen.dart';
import 'screens/contact_agent_screen.dart';
import 'agent_profile_screen.dart';

class PropertyBidDetailsScreen extends StatefulWidget {
  final Bid bid;

  const PropertyBidDetailsScreen({
    Key? key,
    required this.bid,
  }) : super(key: key);

  @override
  State<PropertyBidDetailsScreen> createState() => _PropertyBidDetailsScreenState();
}

class _PropertyBidDetailsScreenState extends State<PropertyBidDetailsScreen> {
  bool isFavorite = false;
  int currentImageIndex = 0;
  final PageController _pageController = PageController();

  Map<String, dynamic>? propertyData;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> similarProperties = [];
  bool _showEditBidPopup = false;
  bool _showCancelBidPopup = false;
  bool _refreshNeeded = false;

  @override
  void initState() {
    super.initState();
    _fetchPropertyData();
  }

  // Format date to relative time
  String getTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year(s) ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month(s) ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day(s) ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour(s) ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute(s) ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error parsing date: $e');
      return 'Recently';
    }
  }

  // Get color based on bid status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF39322);
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      case 'withdrawn':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  // Get display text based on bid status
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }

  Future<void> _fetchPropertyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/properties/${widget.bid.listingId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          propertyData = data;
          _isLoading = false;
        });
        _fetchSimilarProperties(data['category']);
      } else {
        setState(() {
          // Use bid data as fallback if property details fetch fails
          propertyData = {
            'title': widget.bid.listingTitle,
            'category': widget.bid.listingCategory,
            'location': widget.bid.listingLocation,
            'price': widget.bid.listingPrice,
            'images': [widget.bid.listingImage],
            'description': 'Detailed property information could not be loaded at this time. Please try again later.'
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        // Use bid data as fallback
        propertyData = {
          'title': widget.bid.listingTitle,
          'category': widget.bid.listingCategory,
          'location': widget.bid.listingLocation,
          'price': widget.bid.listingPrice,
          'images': [widget.bid.listingImage],
          'description': 'Detailed property information could not be loaded at this time. Please try again later.'
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSimilarProperties(String? category) async {
    if (category == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/properties?category=$category'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          similarProperties = data
              .where((p) => p['property_id'].toString() != widget.bid.listingId)
              .take(2)
              .map<Map<String, dynamic>>((p) => p as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (_) {}
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    if (isFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${propertyData?['title']} added to favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void handleSimilarPropertyClick(String propertyId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyBidDetailsScreen(
          bid: Bid(
            id: widget.bid.id,
            listingId: propertyId,
            listingTitle: similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['title'] ?? 'Unknown Property',
            listingImage: (similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['images'] as List<dynamic>).isNotEmpty 
                ? (similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['images'] as List<dynamic>)[0].toString()
                : 'assets/images/residential1.jpg',
            listingCategory: similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['category'] ?? 'residential',
            listingLocation: similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['location'] ?? 'Unknown Location',
            listingPrice: similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['price'] is num 
                ? (similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['price'] as num).toDouble()
                : double.tryParse(similarProperties.firstWhere((p) => p['property_id'].toString() == propertyId)['price']?.toString() ?? '0') ?? 0.0,
            bidAmount: widget.bid.bidAmount,
            status: widget.bid.status,
            createdAt: widget.bid.createdAt,
            responseMessage: widget.bid.responseMessage,
            responseDate: widget.bid.responseDate,
            userId: widget.bid.userId,
          ),
        ),
      ),
    );
  }

  void _handleEditBid() {
    setState(() {
      _showEditBidPopup = true;
    });
  }

  void _handleCancelBid() {
    setState(() {
      _showCancelBidPopup = true;
    });
  }

  void _updateBid(double newAmount) {
    setState(() {
      _isLoading = true;
    });

    // Refresh after successful update
    BidsApi.getUserBids(forceRefresh: true).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _refreshNeeded = true; // Set flag to refresh parent screen
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _cancelBid() {
    setState(() {
      _isLoading = true;
    });

    // Refresh after successful cancellation
    BidsApi.getUserBids(forceRefresh: true).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _refreshNeeded = true; // Set flag to refresh parent screen
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // Helper to parse features from string or list
  List<String> _parseFeatures(dynamic features) {
    if (features == null) return [];
    if (features is List) {
      return features.map((e) => e.toString()).toList();
    }
    if (features is String) {
      try {
        final decoded = jsonDecode(features);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return features.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  @override
  void dispose() {
    if (_refreshNeeded) {
      // Return a result to refresh the parent screen
      Navigator.pop(context, true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Property Details'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000080),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF39322),
          ),
        ),
      );
    }

    if (propertyData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Property Details'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000080),
          elevation: 0,
        ),
        body: Center(
          child: Text(_error ?? 'Property not found'),
        ),
      );
    }

    final List<String> images = (propertyData?['images'] is List)
        ? List<String>.from(propertyData!['images'])
        : [widget.bid.listingImage];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final img = images[index];
                      return img.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: img,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF39322)),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return Image.asset(
                                  'assets/images/${widget.bid.listingCategory.toLowerCase()}1.jpg',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(img, fit: BoxFit.cover);
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentImageIndex == index
                                ? const Color(0xFFF39322)
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
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
                onPressed: () => Navigator.pop(context, _refreshNeeded),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sharing this property...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bid Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.bid.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(widget.bid.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.bid.status),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.gavel,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bid Status: ${_getStatusText(widget.bid.status)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.bid.status),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Submitted ${getTimeAgo(widget.bid.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Property Title and Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propertyData?['title'] ?? widget.bid.listingTitle,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    propertyData?['address'] ??
                                        propertyData?['location'] ??
                                        widget.bid.listingLocation,
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
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CurrencyFormatter.formatNairaRichText(
                            propertyData != null && propertyData!['price'] is num 
                                ? propertyData!['price'] as num
                                : ((propertyData != null && propertyData!['price'] != null)
                                    ? num.tryParse(propertyData!['price'].toString()) ?? widget.bid.listingPrice
                                    : widget.bid.listingPrice),
                            textStyle: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF39322),
                            ),
                          ),
                          if (widget.bid.listingCategory != 'land')
                            Text(
                              'Negotiable',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Bid Amount and Comparison
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        const Text(
                          'Your Bid Details',
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Asking Price',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CurrencyFormatter.formatNairaRichText(
                                    widget.bid.listingPrice,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000080),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.compare_arrows,
                                color: Color(0xFFF39322),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Your Bid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CurrencyFormatter.formatNairaRichText(
                                    widget.bid.bidAmount,
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.bid.bidAmount < widget.bid.listingPrice
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bid Percentage: ${((widget.bid.bidAmount / widget.bid.listingPrice) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: widget.bid.bidAmount < widget.bid.listingPrice
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            if (widget.bid.status == 'pending')
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _handleEditBid,
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Color(0xFFF39322),
                                    ),
                                    label: const Text(
                                      'Edit',
                                      style: TextStyle(color: Color(0xFFF39322)),
                                    ),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _handleCancelBid,
                                    icon: const Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        
                        // Response Message (if any)
                        if (widget.bid.responseMessage != null && widget.bid.responseMessage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.comment,
                                        size: 16,
                                        color: Color(0xFF000080),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Seller Response:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF000080),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (widget.bid.responseDate != null)
                                        Text(
                                          getTimeAgo(widget.bid.responseDate!),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.bid.responseMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Property Features (if available)
                  if (widget.bid.listingCategory != 'land')
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureItem(
                            Icons.king_bed_outlined,
                            '${propertyData?['bedrooms'] ?? 0} Beds',
                          ),
                          _buildFeatureItem(
                            Icons.bathtub_outlined,
                            '${propertyData?['bathrooms'] ?? 0} Baths',
                          ),
                          _buildFeatureItem(
                            Icons.square_foot,
                            propertyData?['area'] ?? 'N/A',
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureItem(
                            Icons.square_foot,
                            propertyData?['area'] ??
                                propertyData?['land_size']?.toString() ??
                                'N/A',
                          ),
                          _buildFeatureItem(
                            Icons.description_outlined,
                            propertyData?['land_title'] ?? 'C of O',
                          ),
                          _buildFeatureItem(
                            Icons.location_city,
                            propertyData?['category'] ?? widget.bid.listingCategory,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    propertyData?['description'] ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Features
                  if (_parseFeatures(propertyData?['features']).isNotEmpty) ...[
                    const Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _parseFeatures(propertyData?['features']).map((feature) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Property Details
                  const Text(
                    'Property Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      children: [
                        _buildPropertyDetailRow('Property ID',
                            propertyData?['property_id'] ?? widget.bid.listingId),
                        const Divider(height: 24),
                        _buildPropertyDetailRow('Property Type',
                            propertyData?['category'] ?? widget.bid.listingCategory),
                        const Divider(height: 24),
                        _buildPropertyDetailRow(
                            'Location', propertyData?['location'] ?? widget.bid.listingLocation),
                        if (propertyData?.containsKey('year_built') ?? false) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Year Built',
                              propertyData?['year_built'] ?? 'N/A'),
                        ],
                        if (propertyData?.containsKey('quantity') ?? false) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Quantity',
                              propertyData?['quantity']?.toString() ?? 'N/A'),
                        ],
                        if (propertyData?.containsKey('condition') ?? false) ...[
                          const Divider(height: 24),
                          _buildPropertyDetailRow('Condition',
                              propertyData?['condition'] ?? 'N/A'),
                        ],
                        const Divider(height: 24),
                        _buildPropertyDetailRow(
                            'Status',
                            (propertyData?['is_verified'] == true)
                                ? 'Verified'
                                : 'Unverified'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Agent/Listed By
                  if (propertyData?.containsKey('lister_name') ?? false) ...[
                    const Text(
                      'Listed By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF39322),
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: (propertyData?['lister_dp'] != null &&
                                            propertyData!['lister_dp']
                                                .toString()
                                                .startsWith('http'))
                                        ? NetworkImage(propertyData!['lister_dp'])
                                        : const AssetImage(
                                                'assets/images/mipripity.png')
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      propertyData?['lister_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000080),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      propertyData?['lister_email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AgentProfileScreen(
                                      email: propertyData?['lister_email']?.toString() ?? '',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person, size: 18),
                              label: const Text('View Profile'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF000080),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Similar Properties
                  if (similarProperties.isNotEmpty) ...[
                    const Text(
                      'Similar Properties',
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
                        itemCount: similarProperties.length,
                        itemBuilder: (context, index) {
                          final property = similarProperties[index];
                          final simImages = (property['images'] is List)
                              ? List<String>.from(property['images'])
                              : ['assets/images/residential1.jpg'];
                          return GestureDetector(
                            onTap: () => handleSimilarPropertyClick(
                                property['property_id'].toString()),
                            child: Container(
                              width: 200,
                              margin: EdgeInsets.only(
                                right: index != similarProperties.length - 1
                                    ? 16
                                    : 0,
                              ),
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
                                        child: simImages[0].startsWith('http')
                                            ? CachedNetworkImage(
                                                imageUrl: simImages[0],
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  height: 120,
                                                  width: double.infinity,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: CircularProgressIndicator(
                                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF39322)),
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) {
                                                  return Image.asset(
                                                    'assets/images/${property['category']?.toString().toLowerCase() ?? 'residential'}1.jpg',
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                simImages[0],
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
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
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            property['category'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          property['title'] ?? '',
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
                                            const Icon(
                                              Icons.place,
                                              size: 12,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                property['location'] ?? '',
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
                                        CurrencyFormatter.formatNairaRichText(
                                          property['price'] is num
                                              ? property['price'] as num
                                              : (property['price'] != null
                                                  ? num.tryParse(property['price'].toString()) ?? 0
                                                  : 0),
                                          textStyle: const TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF39322),
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
                  ],
                  
                  const SizedBox(height: 100),
                ],
              ),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (propertyData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleVisitScreen(propertyData: propertyData!),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF000080),
                  side: const BorderSide(color: Color(0xFF000080)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Schedule Visit'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (propertyData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactAgentScreen(propertyData: propertyData!),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF000080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Contact Agent'),
              ),
            ),
          ],
        ),
      ),
      
      // Edit Bid Popup
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _showEditBidPopup || _showCancelBidPopup
          ? Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.5),
              child: _showEditBidPopup
                  ? EditBidPopup(
                      bid: widget.bid,
                      onSubmit: _updateBid,
                      onClose: () => setState(() => _showEditBidPopup = false),
                    )
                  : CancelBidPopup(
                      bid: widget.bid,
                      onConfirm: _cancelBid,
                      onClose: () => setState(() => _showCancelBidPopup = false),
                    ),
            )
          : null,
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF39322).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFF39322),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// EditBidPopup Widget
class EditBidPopup extends StatefulWidget {
  final Bid bid;
  final Function(double) onSubmit;
  final VoidCallback onClose;

  const EditBidPopup({
    Key? key,
    required this.bid,
    required this.onSubmit,
    required this.onClose,
  }) : super(key: key);

  @override
  State<EditBidPopup> createState() => _EditBidPopupState();
}

class _EditBidPopupState extends State<EditBidPopup> {
  late TextEditingController _bidAmountController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bidAmountController = TextEditingController(
      text: widget.bid.bidAmount.toString(),
    );
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final bidAmount = double.tryParse(_bidAmountController.text);
    if (bidAmount == null || bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid bid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Call the API to update the bid
    BidsApi.updateBid(
      bidId: widget.bid.id,
      bidAmount: bidAmount,
    ).then((success) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (success) {
          widget.onSubmit(bidAmount);
          widget.onClose();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update bid. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Bid',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Listing: ${widget.bid.listingTitle}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Asking Price: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  CurrencyFormatter.formatNairaRichText(
                    widget.bid.listingPrice,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bidAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Bid Amount (₦)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFF39322),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFF39322),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Update Bid'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CancelBidPopup Widget
class CancelBidPopup extends StatefulWidget {
  final Bid bid;
  final VoidCallback onConfirm;
  final VoidCallback onClose;

  const CancelBidPopup({
    Key? key,
    required this.bid,
    required this.onConfirm,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CancelBidPopup> createState() => _CancelBidPopupState();
}

class _CancelBidPopupState extends State<CancelBidPopup> {
  bool _isSubmitting = false;

  void _handleConfirm() {
    setState(() {
      _isSubmitting = true;
    });

    // Call the API to cancel the bid
    BidsApi.cancelBid(widget.bid.id).then((success) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (success) {
          widget.onConfirm();
          widget.onClose();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel bid. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cancel Bid',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to cancel your bid on "${widget.bid.listingTitle}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bid Amount: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  CurrencyFormatter.formatNairaRichText(
                    widget.bid.bidAmount,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF39322),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('No, Keep Bid'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Yes, Cancel Bid'),
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
}