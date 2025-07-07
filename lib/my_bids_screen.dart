import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'api/bids_api.dart';
import 'utils/currency_formatter.dart';
import 'shared/bottom_navigation.dart';
import 'property_bid_details_screen.dart';

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

// BidCard Widget
class BidCard extends StatelessWidget {
  final Bid bid;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onView;

  const BidCard({
    Key? key,
    required this.bid,
    required this.onEdit,
    required this.onCancel,
    required this.onView,
  }) : super(key: key);

  // Get default image based on property category
  String _getDefaultImageForCategory(String category) {
    switch (category.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    // Determine if the image is a network URL or local asset
    bool isNetworkImage = bid.listingImage.startsWith('http');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with property image and details
          Stack(
            children: [
              // Property Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: isNetworkImage
                    ? CachedNetworkImage(
                        imageUrl: bid.listingImage,
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
                          print('Error loading image: $error for URL: $url');
                          return Image.asset(
                            _getDefaultImageForCategory(bid.listingCategory),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        bid.listingImage,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Status Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bid.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(bid.status),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Category Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bid.listingCategory,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000080),
                    ),
                  ),
                ),
              ),
              
              // Property Details Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.listingTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bid.listingLocation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
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
          
          // Bid Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price Comparison
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
                            bid.listingPrice,
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
                            bid.bidAmount,
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: bid.bidAmount < bid.listingPrice
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Bid Percentage
                Row(
                  children: [
                    const Text(
                      'Bid Percentage:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((bid.bidAmount / bid.listingPrice) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: bid.bidAmount < bid.listingPrice
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Submitted:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getTimeAgo(bid.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ],
                ),
                
                // Response Message (if any)
                if (bid.responseMessage != null && bid.responseMessage!.isNotEmpty)
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
                                'Response:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const Spacer(),
                              if (bid.responseDate != null)
                                Text(
                                  getTimeAgo(bid.responseDate!),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bid.responseMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onView,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF000080),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Property'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (bid.status == 'pending')
                      Row(
                        children: [
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit),
                            color: const Color(0xFFF39322),
                            tooltip: 'Edit Bid',
                          ),
                          IconButton(
                            onPressed: onCancel,
                            icon: const Icon(Icons.cancel),
                            color: Colors.red,
                            tooltip: 'Cancel Bid',
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Dialog(
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
    return Dialog(
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
    );
  }
}

// Main MyBidsScreen
class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({Key? key}) : super(key: key);

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Bid> _allBids = [];
  List<Bid> _filteredBids = [];
  bool _loading = true;
  String? _error;
  String _sortBy = 'newest';
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  Bid? _selectedBid;
  bool _showEditPopup = false;
  bool _showCancelPopup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabIndexChange);
    _fetchBids();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabIndexChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabIndexChange() {
    if (_tabController.indexIsChanging) {
      _filterBidsByTab(_tabController.index);
    }
  }

  void _filterBidsByTab(int tabIndex) {
    setState(() {
      _loading = true;
    });

    // Filter bids based on tab selection
    setState(() {
      switch (tabIndex) {
        case 0: // All
          _filteredBids = _allBids;
          break;
        case 1: // Pending
          _filteredBids = _allBids.where((bid) => bid.status == 'pending').toList();
          break;
        case 2: // Accepted
          _filteredBids = _allBids.where((bid) => bid.status == 'accepted').toList();
          break;
        case 3: // Rejected
          _filteredBids = _allBids.where((bid) => bid.status == 'rejected').toList();
          break;
        case 4: // Withdrawn/Expired
          _filteredBids = _allBids.where((bid) => 
            bid.status == 'withdrawn' || bid.status == 'expired').toList();
          break;
      }
      _loading = false;
    });
  }

  void _fetchBids() {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Get bids from API with forceRefresh to ensure latest data
    BidsApi.getUserBids(forceRefresh: true).then((bids) {
      if (mounted) {
        setState(() {
          _allBids = bids;
          _filteredBids = bids;
          _loading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bids: ${error.toString()}';
          _loading = false;
        });
      }
    });
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      _filterBidsByTab(_tabController.index);
      return;
    }

    setState(() {
      _loading = true;
    });

    // Filter by search query
    final lowercaseQuery = query.toLowerCase();
    
    // First filter by tab
    List<Bid> tabFilteredBids;
    switch (_tabController.index) {
      case 0: // All
        tabFilteredBids = _allBids;
        break;
      case 1: // Pending
        tabFilteredBids = _allBids.where((bid) => bid.status == 'pending').toList();
        break;
      case 2: // Accepted
        tabFilteredBids = _allBids.where((bid) => bid.status == 'accepted').toList();
        break;
      case 3: // Rejected
        tabFilteredBids = _allBids.where((bid) => bid.status == 'rejected').toList();
        break;
      case 4: // Withdrawn/Expired
        tabFilteredBids = _allBids.where((bid) => 
          bid.status == 'withdrawn' || bid.status == 'expired').toList();
        break;
      default:
        tabFilteredBids = _allBids;
    }
    
    // Then filter by search query
    setState(() {
      _filteredBids = tabFilteredBids.where((bid) {
        return bid.listingTitle.toLowerCase().contains(lowercaseQuery) ||
            bid.listingCategory.toLowerCase().contains(lowercaseQuery) ||
            bid.listingLocation.toLowerCase().contains(lowercaseQuery) ||
            bid.status.toLowerCase().contains(lowercaseQuery) ||
            CurrencyFormatter.formatNaira(bid.bidAmount).toLowerCase().contains(lowercaseQuery);
      }).toList();
      
      _loading = false;
    });
  }

  void _handleSort(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _loading = true;
    });

    // Sort bids based on the selected sorting option
    setState(() {
      switch (sortBy) {
        case 'newest':
          _filteredBids.sort((a, b) => 
            DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
          break;
        case 'oldest':
          _filteredBids.sort((a, b) => 
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));
          break;
        case 'highest':
          _filteredBids.sort((a, b) => b.bidAmount.compareTo(a.bidAmount));
          break;
        case 'lowest':
          _filteredBids.sort((a, b) => a.bidAmount.compareTo(b.bidAmount));
          break;
        case 'percentage_highest':
          _filteredBids.sort((a, b) => 
            (b.bidAmount / b.listingPrice).compareTo(a.bidAmount / a.listingPrice));
          break;
        case 'percentage_lowest':
          _filteredBids.sort((a, b) => 
            (a.bidAmount / a.listingPrice).compareTo(b.bidAmount / b.listingPrice));
          break;
      }
      _loading = false;
    });
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _filterBidsByTab(_tabController.index);
      }
    });
  }

  void _handleEditBid(Bid bid) {
    setState(() {
      _selectedBid = bid;
      _showEditPopup = true;
    });
  }

  void _handleCancelBid(Bid bid) {
    setState(() {
      _selectedBid = bid;
      _showCancelPopup = true;
    });
  }

  void _handleViewProperty(Bid bid) {
    // Add haptic feedback for better user experience
    HapticFeedback.lightImpact();
    
    // Navigate to our bid-specific property details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyBidDetailsScreen(bid: bid),
      ),
    ).then((refreshNeeded) {
      // If the PropertyBidDetailsScreen indicates a refresh is needed (after edit/cancel)
      if (refreshNeeded == true) {
        _fetchBids();
      }
    });
  }

  void _updateBid(double newAmount) {
    if (_selectedBid == null) return;

    setState(() {
      _loading = true;
    });
    
    // Refresh bids from API after successful update
    _fetchBids();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bid updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelBid() {
    if (_selectedBid == null) return;

    setState(() {
      _loading = true;
    });
    
    // Refresh bids from API after successful cancellation
    _fetchBids();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bid cancelled successfully'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search bids...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                onChanged: _handleSearch,
              )
            : const Text(
                'My Bids',
                style: TextStyle(
                  color: Color(0xFF000080),
                  fontWeight: FontWeight.bold,
                ),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close : Icons.search,
              color: const Color(0xFF000080),
            ),
            onPressed: _toggleSearchMode,
          ),
          if (!_isSearchMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Color(0xFF000080)),
              onSelected: _handleSort,
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'newest',
                  child: Text('Newest First'),
                ),
                const PopupMenuItem<String>(
                  value: 'oldest',
                  child: Text('Oldest First'),
                ),
                const PopupMenuItem<String>(
                  value: 'highest',
                  child: Text('Highest Bid First'),
                ),
                const PopupMenuItem<String>(
                  value: 'lowest',
                  child: Text('Lowest Bid First'),
                ),
                const PopupMenuItem<String>(
                  value: 'percentage_highest',
                  child: Text('Highest Percentage First'),
                ),
                const PopupMenuItem<String>(
                  value: 'percentage_lowest',
                  child: Text('Lowest Percentage First'),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFF39322),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF39322),
          tabs: [
            Tab(
              text: 'All (${_allBids.length})',
            ),
            Tab(
              text: 'Pending (${_allBids.where((bid) => bid.status == 'pending').length})',
            ),
            Tab(
              text: 'Accepted (${_allBids.where((bid) => bid.status == 'accepted').length})',
            ),
            Tab(
              text: 'Rejected (${_allBids.where((bid) => bid.status == 'rejected').length})',
            ),
            Tab(
              text: 'Withdrawn/Expired (${_allBids.where((bid) => bid.status == 'withdrawn' || bid.status == 'expired').length})',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          TabBarView(
            controller: _tabController,
            children: List.generate(5, (index) {
              return _buildBidsList();
            }),
          ),

          // Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SharedBottomNavigation(
              activeTab: "bid",
              onTabChange: (tab) {
                SharedBottomNavigation.handleNavigation(context, tab);
              },
            ),
          ),

          // Edit Bid Popup
          if (_showEditPopup && _selectedBid != null)
            EditBidPopup(
              bid: _selectedBid!,
              onSubmit: _updateBid,
              onClose: () => setState(() => _showEditPopup = false),
            ),

          // Cancel Bid Popup
          if (_showCancelPopup && _selectedBid != null)
            CancelBidPopup(
              bid: _selectedBid!,
              onConfirm: _cancelBid,
              onClose: () => setState(() => _showCancelPopup = false),
            ),
        ],
      ),
    );
  }

  Widget _buildBidsList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF39322),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _fetchBids();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF39322),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredBids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.gavel,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearchMode && _searchController.text.isNotEmpty
                  ? 'No bids match your search'
                  : 'No bids found in this category',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearchMode && _searchController.text.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _handleSearch('');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF39322),
                ),
                child: const Text('Clear Search'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/explore');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF39322),
                ),
                child: const Text('Explore Properties'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Bottom padding for navigation bar
      itemCount: _filteredBids.length,
      itemBuilder: (context, index) {
        final bid = _filteredBids[index];
        return BidCard(
          bid: bid,
          onEdit: () => _handleEditBid(bid),
          onCancel: () => _handleCancelBid(bid),
          onView: () => _handleViewProperty(bid),
        );
      },
    );
  }
}