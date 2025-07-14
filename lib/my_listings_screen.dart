import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'shared/bottom_navigation.dart';
import 'api/listings_api.dart';
import 'utils/currency_formatter.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Listing> _listings = [];
  String? _error;
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  late TabController _tabController;
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  List<Listing> _filteredListings = [];
  
  // Status counts
  int _activeCount = 0;
  int _pendingCount = 0;
  int _soldCount = 0;
  int _expiredCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChangeInner);
    _fetchListings();
    
    // Add listener for search
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChangeInner);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChangeInner() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'All';
            break;
          case 1:
            _selectedFilter = 'active';
            break;
          case 2:
            _selectedFilter = 'pending';
            break;
          case 3:
            _selectedFilter = 'sold';
            break;
        }
      });
      _filterListings();
    }
  }

  void _handleSearch() {
    _filterListings();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
      } else {
        // Focus on the search field when entering search mode
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
    _filterListings();
  }

  void _fetchListings() {
    // Fetch real data from PostgreSQL database
    setState(() {
      _loading = true;
      _error = null;
    });

    // Force refresh to ensure latest data
    ListingsApi.getUserListings(forceRefresh: true).then((listings) {
      if (mounted) {
        setState(() {
          _listings = listings;
          _loading = false;
          
          // Count listings by status
          _activeCount = listings.where((listing) => listing.status == 'active').length;
          _pendingCount = listings.where((listing) => listing.status == 'pending').length;
          _soldCount = listings.where((listing) => listing.status == 'sold').length;
          _expiredCount = listings.where((listing) => listing.status == 'expired').length;
        });
        
        _filterListings();
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load listings: ${error.toString()}';
        });
      }
    });
  }

  void _filterListings() {
    if (_listings.isEmpty) return;

    List<Listing> filtered = List.from(_listings);

    // Apply status filter if not "All"
    if (_selectedFilter != 'All') {
      filtered = filtered.where((listing) => listing.status == _selectedFilter.toLowerCase()).toList();
    }

    // Apply search filter if in search mode
    if (_isSearchMode && _searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((listing) {
        return listing.title.toLowerCase().contains(searchTerm) ||
               listing.description.toLowerCase().contains(searchTerm) ||
               listing.location.toLowerCase().contains(searchTerm) ||
               listing.category.toLowerCase().contains(searchTerm) ||
               listing.city.toLowerCase().contains(searchTerm);
      }).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Newest':
        filtered.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
        break;
      case 'Oldest':
        filtered.sort((a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));
        break;
      case 'Price (High to Low)':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price (Low to High)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Most Viewed':
        filtered.sort((a, b) => b.views.compareTo(a.views));
        break;
    }

    setState(() {
      _filteredListings = filtered;
    });
  }

  void _handleSortChange(String? value) {
    if (value != null) {
      setState(() {
        _selectedSort = value;
      });
      _filterListings();
    }
  }

  void _showDeleteConfirmation(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteListing(listing.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteListing(String id) {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting listing...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Delete from backend database
    ListingsApi.deleteListing(id).then((success) {
      if (mounted) {
        if (success) {
          setState(() {
            _listings.removeWhere((listing) => listing.id == id);
            
            // Update counts
            _activeCount = _listings.where((listing) => listing.status == 'active').length;
            _pendingCount = _listings.where((listing) => listing.status == 'pending').length;
            _soldCount = _listings.where((listing) => listing.status == 'sold').length;
            _expiredCount = _listings.where((listing) => listing.status == 'expired').length;
          });
          
          _filterListings();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete listing. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting listing: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _editListing(Listing listing) {
    // Navigate to edit listing screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing listing: ${listing.title}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _viewListingDetails(Listing listing) {
    // Navigate to listing details
    Navigator.pushNamed(context, '/property-details/${listing.id}');
  }

  void _addNewListing() {
    // Navigate to add listing screen
    Navigator.pushNamed(context, '/add');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Column(
            children: [
              // App Bar
              Container(
                color: const Color.fromARGB(255, 246, 246, 248),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Title/Search Bar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            if (_isSearchMode)
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search your listings...',
                                    border: InputBorder.none,
                                  ),
                                  autofocus: true,
                                ),
                              )
                            else
                              const Expanded(
                                child: Text(
                                  'My Listings',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(_isSearchMode ? Icons.close : Icons.search),
                              onPressed: _toggleSearchMode,
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.sort),
                              onSelected: _handleSortChange,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'Newest',
                                  child: Text('Newest'),
                                ),
                                const PopupMenuItem(
                                  value: 'Oldest',
                                  child: Text('Oldest'),
                                ),
                                const PopupMenuItem(
                                  value: 'Price (High to Low)',
                                  child: Text('Price (High to Low)'),
                                ),
                                const PopupMenuItem(
                                  value: 'Price (Low to High)',
                                  child: Text('Price (Low to High)'),
                                ),
                                const PopupMenuItem(
                                  value: 'Most Viewed',
                                  child: Text('Most Viewed'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Bar
                      if (!_isSearchMode)
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: const Color(0xFFF39322),
                          tabs: [
                            Tab(text: 'All (${_listings.length})'),
                            Tab(text: 'Active ($_activeCount)'),
                            Tab(text: 'Pending ($_pendingCount)'),
                            Tab(text: 'Sold ($_soldCount)'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // Body Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF39322),
                        ),
                      )
                    : _error != null
                        ? Center(
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
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchListings,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF39322),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _filteredListings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.inventory,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isSearchMode && _searchController.text.isNotEmpty
                                          ? 'No listings match your search'
                                          : 'No listings found in this category',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _addNewListing,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF39322),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Add New Listing'),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for navigation
                                child: ListView.builder(
                                  itemCount: _filteredListings.length,
                                  itemBuilder: (context, index) {
                                    final listing = _filteredListings[index];
                                    return _buildListingCard(listing);
                                  },
                                ),
                              ),
              ),
            ],
          ),
          
          // Floating Action Button
          Positioned(
            bottom: 90, // Positioned above the bottom navigation
            right: 16,
            child: FloatingActionButton(
              onPressed: _addNewListing,
              backgroundColor: const Color(0xFFF39322),
              child: const Icon(Icons.add),
            ),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SharedBottomNavigation(
              activeTab: "my-listing", // Changed to "listings" to represent this screen
              onTabChange: (tab) {
                SharedBottomNavigation.handleNavigation(context, tab);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    // Format the date
    final createdDate = DateTime.parse(listing.createdAt);
    final now = DateTime.now();
    final difference = now.difference(createdDate);
    
    String timeAgo;
    if (difference.inDays > 30) {
      timeAgo = '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      timeAgo = 'Just now';
    }

    // Get status color
    Color statusColor;
    switch (listing.status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'sold':
        statusColor = Colors.blue;
        break;
      case 'expired':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewListingDetails(listing),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Status Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: listing.image.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: listing.image,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
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
                          String defaultImage;
                          switch(listing.category.toLowerCase()) {
                            case 'commercial':
                              defaultImage = 'assets/images/commercial1.jpg';
                              break;
                            case 'land':
                              defaultImage = 'assets/images/land1.jpeg';
                              break;
                            case 'material':
                              defaultImage = 'assets/images/material1.jpg';
                              break;
                            default:
                              defaultImage = 'assets/images/residential1.jpg';
                          }
                          return Image.asset(
                            defaultImage,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        listing.image,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      listing.category.substring(0, 1).toUpperCase() + listing.category.substring(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
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
                      color: statusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      listing.status.substring(0, 1).toUpperCase() + listing.status.substring(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Listing Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${listing.location}, ${listing.city}, ${listing.state}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CurrencyFormatter.formatNairaRichText(
                    listing.price,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF39322),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${listing.views} views',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editListing(listing),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(listing),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}