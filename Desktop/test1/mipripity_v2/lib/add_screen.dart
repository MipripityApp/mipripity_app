import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'add_view_model.dart';
import 'shared/bottom_navigation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class AddScreen extends StatefulWidget {
  final Function onNavigateBack;

  const AddScreen({super.key, required this.onNavigateBack});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Define all listing categories with their images
  final List<Map<String, String>> listingCategories = [
    {"label": "Chair", "img": "assets/icons/chair.gif"},
    {"label": "Warehouse", "img": "assets/icons/warehouse.gif"},
    {"label": "Retail Store", "img": "assets/icons/store.gif"},
    {"label": "Duplex", "img": "assets/icons/duplex.gif"},
    {"label": "Table", "img": "assets/icons/table.gif"},
    {"label": "Bath Tub", "img": "assets/icons/bathtub.gif"},
    {"label": "Mirror", "img": "assets/icons/mirror.gif"},
    {"label": "Sofa", "img": "assets/icons/sofa.gif"},
    {"label": "A.C", "img": "assets/icons/ac.gif"},
    {"label": "Television", "img": "assets/icons/television.gif"},
    {"label": "Speaker", "img": "assets/icons/speaker.gif"},
    {"label": "Fan", "img": "assets/icons/fan.gif"},
    {"label": "Story Building", "img": "assets/icons/story building.gif"},
    {"label": "Office", "img": "assets/icons/office.gif"},
    {"label": "Land", "img": "assets/icons/land.gif"},
    {"label": "Curtain", "img": "assets/icons/curtain.gif"},
    {"label": "Window", "img": "assets/icons/window.gif"},
    {"label": "Iron", "img": "assets/icons/iron.gif"},
    {"label": "Tiles", "img": "assets/icons/tile.gif"},
    {"label": "Clock", "img": "assets/icons/clock.gif"},
    {"label": "Door", "img": "assets/icons/door.gif"},
    {"label": "Fence wire", "img": "assets/icons/barbed-wire.gif"},
    {"label": "Paint", "img": "assets/icons/paint.gif"},
    {"label": "Art work", "img": "assets/icons/artwork.gif"},
    {"label": "Artifact", "img": "assets/icons/artifact.gif"},
    {"label": "Cement", "img": "assets/icons/cement.gif"},
    {"label": "Sand", "img": "assets/icons/sand-bucket.gif"},
    {"label": "Tank", "img": "assets/icons/tank.gif"},
    {"label": "Gate", "img": "assets/icons/gate.gif"},
    {"label": "Console", "img": "assets/icons/console.gif"},
    {"label": "Company", "img": "assets/icons/company.gif"},
    {"label": "Co-Living Space", "img": "assets/icons/co-living.gif"},
    {"label": "Studio Apartment", "img": "assets/icons/studio apartment.gif"},
    {"label": "Serviced Apartment", "img": "assets/icons/serviced apartment.gif"},
    {"label": "Single Room", "img": "assets/icons/single-room.gif"},
    {"label": "Garden Apartment", "img": "assets/icons/garden-apartment.gif"},
    {"label": "Luxury Apartment", "img": "assets/icons/luxury apartment.gif"},
    {"label": "Cortage", "img": "assets/icons/cortage.gif"},
    {"label": "2 Bedroom Flat", "img": "assets/icons/2 bedroom flat.gif"},
    {"label": "Loft Apartment", "img": "assets/icons/loft apartment.gif"},
    {"label": "Farm House", "img": "assets/icons/farm house.gif"},
    {"label": "Condimonium", "img": "assets/icons/condimonium.gif"},
    {"label": "Room & Palor", "img": "assets/icons/room-palor.gif"},
    {"label": "Vacation Home", "img": "assets/icons/vacation home.gif"},
    {"label": "Town House", "img": "assets/icons/town house.gif"},
    {"label": "3 Bedroom Flat", "img": "assets/icons/3bedroom.gif"},
    {"label": "1 Room Self Contain", "img": "assets/icons/1 room self contain.gif"},
    {"label": "Pent House", "img": "assets/icons/pent house.gif"},
    {"label": "Bungalow Single Room", "img": "assets/icons/bungalow-single-room.gif"},
    {"label": "4 Bedroom Flat", "img": "assets/icons/4 bedroom flat.gif"},
    {"label": "Estate", "img": "assets/icons/estate.gif"},
    {"label": "Bungalow Flat", "img": "assets/icons/bungalow flat.gif"},
    {"label": "Block of Flat", "img": "assets/icons/block of flat.gif"},
    {"label": "Villa", "img": "assets/icons/villa.gif"},
    {"label": "Mini Flat", "img": "assets/icons/mini flat.gif"},
    {"label": "Air BnB", "img": "assets/icons/airbnb.gif"},
    {"label": "Self Storage Facility", "img": "assets/icons/selfstorage.gif"},
    {"label": "shortlet", "img": "assets/icons/shortlet.gif"},
    {"label": "Hub", "img": "assets/icons/hub.gif"},
    {"label": "Event Centre", "img": "assets/icons/eventcentre.gif"},
    {"label": "Hotel", "img": "assets/icons/hotel.gif"},
    {"label": "Business", "img": "assets/icons/business.gif"},
    {"label": "Resort Centre", "img": "assets/icons/resort.gif"},
    {"label": "Mall", "img": "assets/icons/mall.gif"},
    {"label": " ", "img": "assets/images/do.jpg"},
    {"label": " ", "img": "assets/images/do.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AddViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Fixed header
                  _buildHeader(viewModel),
                  
                  // Main content with padding to account for fixed header
                  Expanded(
                    child: !viewModel.showForm
                        ? _buildCategoryGrid(viewModel)
                        : const SizedBox(height: 10),
                  ),
                ],
              ),
              
              // Full Page Form
              if (viewModel.showForm && viewModel.selectedCategory != null)
                _buildFormPage(viewModel),
              
              // Bottom Navigation (only show when form is not open)
              if (!viewModel.showForm)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SharedBottomNavigation(
                    activeTab: "add",
                    onTabChange: (tab) {
                      SharedBottomNavigation.handleNavigation(context, tab);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AddViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header with title and profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Listing',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your property listing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notification Icon
                      Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              size: 20,
                              color: Color(0xFF000080),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF39322),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '3',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Profile Image
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/chatbot.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search input
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 0,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search listings',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(AddViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: listingCategories.length,
              itemBuilder: (context, index) {
                final category = listingCategories[index];
                return _buildCategoryButton(
                  category["label"]!,
                  category["img"]!,
                  viewModel,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label, String imagePath, AddViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.selectCategory(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPage(AddViewModel viewModel) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Form Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => viewModel.closeForm(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add ${viewModel.selectedCategory}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: viewModel.formSubmitted
                      ? _buildSuccessMessage(viewModel)
                      : _buildFormContent(viewModel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(AddViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Listing Submitted!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your ${viewModel.selectedCategory?.toLowerCase()} listing has been submitted successfully.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => viewModel.closeForm(),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFF39322),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Back to Categories'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(AddViewModel viewModel) {
    if (viewModel.selectedCategory == null) {
      return const SizedBox.shrink();
    }

    // Error message display if any
    if (viewModel.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                viewModel.clearError();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Loading indicator when submitting
    if (viewModel.isSubmitting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFF39322),
            ),
            const SizedBox(height: 24),
            Text(
              'Submitting ${viewModel.selectedCategory} Listing...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000080),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we process your information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Check for material items first
    if (_isMaterialItem(viewModel.selectedCategory!)) {
      return GenericForm(
        category: viewModel.selectedCategory!,
        onSubmit: (data) => viewModel.submitForm(data),
      );
    } else if (viewModel.isCommercialProperty(viewModel.selectedCategory!)) {
      return CommercialForm(
        category: viewModel.selectedCategory!,
        onSubmit: (data) => viewModel.submitForm(data),
      );
    } else if (viewModel.isResidentialProperty(viewModel.selectedCategory!)) {
      return ResidentialForm(
        category: viewModel.selectedCategory!,
        onSubmit: (data) => viewModel.submitForm(data),
      );
    } else if (viewModel.isLandProperty(viewModel.selectedCategory!)) {
      return LandForm(
        category: viewModel.selectedCategory!,
        onSubmit: (data) => viewModel.submitForm(data),
      );
    } else {
      return GenericForm(
        category: viewModel.selectedCategory!,
        onSubmit: (data) => viewModel.submitForm(data),
      );
    }
  }

  bool _isMaterialItem(String category) {
    final materialItems = [
      'Chair', 'Table', 'Bath Tub', 'Mirror', 'Sofa', 'A.C', 'Television', 
      'Speaker', 'Fan', 'Curtain', 'Window', 'Iron', 'Tiles', 'Clock', 
      'Door', 'Fence wire', 'Paint', 'Art work', 'Artifact', 'Cement', 
      'Sand', 'Tank', 'Gate', 'Console'
    ];
    return materialItems.contains(category);
  }
}

// Network Signal Display Widget
class NetworkSignalDisplay extends StatelessWidget {
  final double latitude;
  final double longitude;

  const NetworkSignalDisplay({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  int _getSignalStrength(String provider, double lat, double lng) {
    if (lat == 0 && lng == 0) return 0;
    
    final seed = (lat * 1000).round() + (lng * 1000).round() + provider.codeUnitAt(0);
    final random = (seed % 5) + 1;
    
    switch (provider) {
      case 'MTN':
        return random > 2 ? random : random + 1;
      case 'AIRTEL':
        return random;
      case 'GLO':
        return random > 3 ? random - 1 : random;
      case '9MOBILE':
        return random > 4 ? random - 2 : random;
      default:
        return random;
    }
  }

  Widget _buildSignalIndicator(String provider, int strength) {
    final Color color = provider == 'MTN' ? Colors.yellow[700]! :
                        provider == 'AIRTEL' ? Colors.red :
                        provider == 'GLO' ? Colors.green :
                        Colors.green[900]!;
    
    return Column(
      children: [
        Text(
          provider,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Container(
              width: 4,
              height: 6 + (index * 2),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: index < strength ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (latitude == 0 && longitude == 0) {
      return const SizedBox.shrink();
    }

    final mtnStrength = _getSignalStrength('MTN', latitude, longitude);
    final airtelStrength = _getSignalStrength('AIRTEL', latitude, longitude);
    final gloStrength = _getSignalStrength('GLO', latitude, longitude);
    final mobileStrength = _getSignalStrength('9MOBILE', latitude, longitude);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Network Signal Strength',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSignalIndicator('MTN', mtnStrength),
              _buildSignalIndicator('AIRTEL', airtelStrength),
              _buildSignalIndicator('GLO', gloStrength),
              _buildSignalIndicator('9MOBILE', mobileStrength),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Signal strength is an estimate based on location',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Image Upload Widget
class ImageUploadWidget extends StatefulWidget {
  final List<String> images;
  final Function(List<String>) onImagesChanged;

  const ImageUploadWidget({
    super.key,
    required this.images,
    required this.onImagesChanged,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final List<String> newImages = List<String>.from(widget.images);
        
        for (var file in pickedFiles) {
          newImages.add(file.path);
        }
        
        widget.onImagesChanged(newImages);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pickedFiles.length} image(s) added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        final List<String> newImages = List<String>.from(widget.images);
        newImages.add(pickedFile.path);
        widget.onImagesChanged(newImages);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images/Videos *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: _isUploading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image),
                label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Add Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF39322),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.images.isEmpty
              ? const Center(
                  child: Text(
                    'No images selected\nTap "Add Images" to get started',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: widget.images[index].contains('.mp4') || 
                                     widget.images[index].contains('.mov') ||
                                     widget.images[index].contains('video')
                                  ? const Icon(Icons.video_file, size: 50, color: Colors.grey)
                                  : File(widget.images[index]).existsSync()
                                      ? Image.file(
                                          File(widget.images[index]),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                                          },
                                        )
                                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                final updatedImages = List<String>.from(widget.images);
                                updatedImages.removeAt(index);
                                widget.onImagesChanged(updatedImages);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (widget.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${widget.images.length} file(s) selected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}

// Multi-Select Chip Widget
class MultiSelectChip extends StatefulWidget {
  final List<String> options;
  final List<String> selectedItems;
  final Function(List<String>) onSelectionChanged;
  final String label;

  const MultiSelectChip({
    super.key,
    required this.options,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.label,
  });

  @override
  State<MultiSelectChip> createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.selectedItems.map((item) {
                    return Chip(
                      label: Text(
                        item,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        final updatedSelection = List<String>.from(widget.selectedItems);
                        updatedSelection.remove(item);
                        widget.onSelectionChanged(updatedSelection);
                      },
                      backgroundColor: const Color(0xFFF39322).withOpacity(0.2),
                      labelStyle: const TextStyle(color: Color(0xFF000080)),
                    );
                  }).toList(),
                ),
                const Divider(),
              ],
              
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text(
                    'Select ${widget.label}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: widget.options
                      .where((item) => !widget.selectedItems.contains(item))
                      .map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final updatedSelection = List<String>.from(widget.selectedItems);
                      updatedSelection.add(value);
                      widget.onSelectionChanged(updatedSelection);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Demography Form Widget
class DemographyFormWidget extends StatefulWidget {
  final Map<String, dynamic> demographyData;
  final Function(Map<String, dynamic>) onDataChanged;

  const DemographyFormWidget({
    super.key,
    required this.demographyData,
    required this.onDataChanged,
  });

  @override
  State<DemographyFormWidget> createState() => _DemographyFormWidgetState();
}

class _DemographyFormWidgetState extends State<DemographyFormWidget> {
  final List<String> _countries = [
    'Nigeria', 'Ghana', 'Kenya', 'South Africa', 'Egypt', 'Morocco', 
    'Ethiopia', 'Tanzania', 'Uganda', 'Cameroon'
  ];
  
  final List<String> _states = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa',
    'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo',
    'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna',
    'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos',
    'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo',
    'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara',
    'Abuja'
  ];
  
  final List<String> _allLgas = [
    'Demsa (Adamawa), Est. Population (125,600)',
    'Fufore (Adamawa), Est. Population (209,800)',
    'Ganye (Adamawa), Est. Population (169,400)',
    'Girei (Adamawa), Est. Population (142,800)',
    'Gombi (Adamawa), Est. Population (181,500)',
    'Guyuk (Adamawa), Est. Population (158,900)',
    'Hong (Adamawa), Est. Population (184,700)',
    'Jada (Adamawa), Est. Population (159,300)',
    'Lamurde (Adamawa), Est. Population (112,400)',
    'Madagali (Adamawa), Est. Population (176,200)',
    'Maiha (Adamawa), Est. Population (114,500)',
    'Mayo-Belwa (Adamawa), Est. Population (162,300)',
    'Michika (Adamawa), Est. Population (185,700)',
    'Mubi North (Adamawa), Est. Population (200,400)',
    'Mubi South (Adamawa), Est. Population (150,600)',
    'Numan (Adamawa), Est. Population (135,800)',
    'Shelleng (Adamawa), Est. Population (128,900)',
    'Song (Adamawa), Est. Population (170,200)',
    'Toungo (Adamawa), Est. Population (98,700)',
    'Yola North (Adamawa), Est. Population (199,800)',
    'Yola South (Adamawa), Est. Population (189,500)',
    'Aba North (Abia), Est. Population (86,331)',
    'Aba South (Abia), Est. Population (413,852)',
    'Arochukwu (Abia), Est. Population (97,800)',
    'Bende (Abia), Est. Population (132,271)',
    'Ikwuano (Abia), Est. Population (99,200)',
    'Isiala Ngwa North (Abia), Est. Population (153,700)',
    'Isiala Ngwa South (Abia), Est. Population (134,400)',
    'Isuikwuato (Abia), Est. Population (103,800)',
    'Obi Ngwa (Abia), Est. Population (172,800)',
    'Ohafia (Abia), Est. Population (184,800)',
    'Osisioma Ngwa (Abia), Est. Population (219,400)',
    'Ugwunagbo (Abia), Est. Population (97,100)',
    'Ukwa East (Abia), Est. Population (83,700)',
    'Ukwa West (Abia), Est. Population (89,500)',
    'Umuahia North (Abia), Est. Population (220,660)',
    'Umuahia South (Abia), Est. Population (138,900)',
    'Umunneochi (Abia), Est. Population (92,300)',
    'Aguata (Anambra), Est. Population (190,000)',
    'Anambra East (Anambra), Est. Population (140,000)',
    'Anambra West (Anambra), Est. Population (130,000)',
    'Anaocha (Anambra), Est. Population (160,000)',
    'Awka North (Anambra), Est. Population (120,000)',
    'Awka South (Anambra), Est. Population (400,000)',
    'Ayamelum (Anambra), Est. Population (150,000)',
    'Dunukofia (Anambra), Est. Population (110,000)',
    'Ekwusigo (Anambra), Est. Population (130,000)',
    'Idemili North (Anambra), Est. Population (200,000)',
    'Idemili South (Anambra), Est. Population (180,000)',
    'Ihiala (Anambra), Est. Population (220,000)',
    'Njikoka (Anambra), Est. Population (140,000)',
    'Nnewi North (Anambra), Est. Population (250,000)',
    'Nnewi South (Anambra), Est. Population (200,000)',
    'Ogbaru (Anambra), Est. Population (180,000)',
    'Onitsha North (Anambra), Est. Population (450,000)',
    'Onitsha South (Anambra), Est. Population (400,000)',
    'Orumba North (Anambra), Est. Population (130,000)',
    'Orumba South (Anambra), Est. Population (120,000)',
    'Oyi (Anambra), Est. Population (150,000)',
    'Abak (Akwa Ibom), Est. Population (139,000)',
    'Eastern Obolo (Akwa Ibom), Est. Population (76,000)',
    'Eket (Akwa Ibom), Est. Population (220,600)',
    'Esit Eket (Akwa Ibom), Est. Population (118,000)',
    'Essien Udim (Akwa Ibom), Est. Population (158,000)',
    'Etim Ekpo (Akwa Ibom), Est. Population (132,000)',
    'Etinan (Akwa Ibom), Est. Population (145,000)',
    'Ibeno (Akwa Ibom), Est. Population (112,000)',
    'Ibesikpo Asutan (Akwa Ibom), Est. Population (127,000)',
    'Ibiono Ibom (Akwa Ibom), Est. Population (168,000)',
    'Ika (Akwa Ibom), Est. Population (98,000)',
    'Ikono (Akwa Ibom), Est. Population (168,000)',
    'Ikot Abasi (Akwa Ibom), Est. Population (142,000)',
    'Ikot Ekpene (Akwa Ibom), Est. Population (179,000)',
    'Ini (Akwa Ibom), Est. Population (123,000)',
    'Itu (Akwa Ibom), Est. Population (150,000)',
    'Mbo (Akwa Ibom), Est. Population (101,000)',
    'Mkpat Enin (Akwa Ibom), Est. Population (226,200)',
    'Nsit Atai (Akwa Ibom), Est. Population (95,000)',
    'Nsit Ibom (Akwa Ibom), Est. Population (110,000)',
    'Nsit Ubium (Akwa Ibom), Est. Population (120,000)',
    'Obot Akara (Akwa Ibom), Est. Population (130,000)',
    'Okobo (Akwa Ibom), Est. Population (89,000)',
    'Onna (Akwa Ibom), Est. Population (157,200)',
    'Oron (Akwa Ibom), Est. Population (95,000)',
    'Oruk Anam (Akwa Ibom), Est. Population (145,000)',
    'Udung Uko (Akwa Ibom), Est. Population (76,000)',
    'Ukanafun (Akwa Ibom), Est. Population (112,000)',
    'Uruan (Akwa Ibom), Est. Population (105,000)',
    'Urue-Offong/Oruko (Akwa Ibom), Est. Population (88,000)',
    'Uyo (Akwa Ibom), Est. Population (304,000)',
  ];
  
  final List<String> _occupations = [
    'Business Owner', 'Civil Servant', 'Teacher', 'Doctor', 'Engineer', 
    'Lawyer', 'Accountant', 'Banker', 'Student', 'Trader', 'Farmer', 'Realtor', 
    'IT Professional', 'Consultant', 'Retired', 'Unemployed'
  ];
  
  final List<String> _ageGroups = ['All', '18-24', '25-34', '35-44', '45-54', '55+'];
  final List<String> _classes = ['All', 'Upper', 'Middle', 'Lower'];

  List<String> _getFilteredLGAs() {
    final selectedStates = List<String>.from(widget.demographyData['states'] ?? []);
    
    if (selectedStates.isEmpty) {
      return _allLgas;
    }
    
    return _allLgas.where((lga) {
      for (final state in selectedStates) {
        if (lga.contains('($state)')) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLGAs = _getFilteredLGAs();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Demography',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          MultiSelectChip(
            label: 'Countries',
            options: _countries,
            selectedItems: List<String>.from(widget.demographyData['countries'] ?? []),
            onSelectionChanged: (selectedItems) {
              final updatedData = Map<String, dynamic>.from(widget.demographyData);
              updatedData['countries'] = selectedItems;
              widget.onDataChanged(updatedData);
            },
          ),
          const SizedBox(height: 16),
          
          MultiSelectChip(
            label: 'States',
            options: _states,
            selectedItems: List<String>.from(widget.demographyData['states'] ?? []),
            onSelectionChanged: (selectedItems) {
              final updatedData = Map<String, dynamic>.from(widget.demographyData);
              updatedData['states'] = selectedItems;
              
              final currentLGAs = List<String>.from(updatedData['lgas'] ?? []);
              final validLGAs = currentLGAs.where((lga) {
                if (selectedItems.isEmpty) return true;
                for (final state in selectedItems) {
                  if (lga.contains('($state)')) {
                    return true;
                  }
                }
                return false;
              }).toList();
              
              updatedData['lgas'] = validLGAs;
              widget.onDataChanged(updatedData);
            },
          ),
          const SizedBox(height: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MultiSelectChip(
                label: 'Local Government Areas',
                options: filteredLGAs,
                selectedItems: List<String>.from(widget.demographyData['lgas'] ?? []),
                onSelectionChanged: (selectedItems) {
                  final updatedData = Map<String, dynamic>.from(widget.demographyData);
                  updatedData['lgas'] = selectedItems;
                  widget.onDataChanged(updatedData);
                },
              ),
              if ((widget.demographyData['states']?.length ?? 0) > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Showing LGAs from ${(widget.demographyData['states'] as List<String>).join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Age Group',
              border: OutlineInputBorder(),
            ),
            value: widget.demographyData['ageGroup'],
            items: _ageGroups.map((ageGroup) {
              return DropdownMenuItem(
                value: ageGroup,
                child: Text(ageGroup),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final updatedData = Map<String, dynamic>.from(widget.demographyData);
                updatedData['ageGroup'] = value;
                widget.onDataChanged(updatedData);
              }
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
            ),
            value: widget.demographyData['class'],
            items: _classes.map((classType) {
              return DropdownMenuItem(
                value: classType,
                child: Text(classType),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final updatedData = Map<String, dynamic>.from(widget.demographyData);
                updatedData['class'] = value;
                widget.onDataChanged(updatedData);
              }
            },
          ),
          const SizedBox(height: 16),
          
          MultiSelectChip(
            label: 'Occupations',
            options: _occupations,
            selectedItems: List<String>.from(widget.demographyData['occupations'] ?? []),
            onSelectionChanged: (selectedItems) {
              final updatedData = Map<String, dynamic>.from(widget.demographyData);
              updatedData['occupations'] = selectedItems;
              widget.onDataChanged(updatedData);
            },
          ),
        ],
      ),
    );
  }
}

// Urgency Form Widget
class UrgencyFormWidget extends StatefulWidget {
  final Map<String, dynamic> urgencyData;
  final Function(Map<String, dynamic>) onDataChanged;

  const UrgencyFormWidget({
    super.key,
    required this.urgencyData,
    required this.onDataChanged,
  });

  @override
  State<UrgencyFormWidget> createState() => _UrgencyFormWidgetState();
}

class _UrgencyFormWidgetState extends State<UrgencyFormWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Urgency Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            initialValue: widget.urgencyData['reason'],
            decoration: const InputDecoration(
              labelText: 'Reason for Urgency',
              border: OutlineInputBorder(),
              hintText: 'e.g., Relocating, Need quick cash, etc.',
            ),
            maxLines: 3,
            onChanged: (value) {
              final updatedData = Map<String, dynamic>.from(widget.urgencyData);
              updatedData['reason'] = value ?? '';
              widget.onDataChanged(updatedData);
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            initialValue: widget.urgencyData['deadline'],
            decoration: const InputDecoration(
              labelText: 'Deadline (e.g., 7 days, 2 weeks)',
              border: OutlineInputBorder(),
              hintText: 'When do you need this sold?',
            ),
            onChanged: (value) {
              final updatedData = Map<String, dynamic>.from(widget.urgencyData);
              updatedData['deadline'] = value ?? '';
              widget.onDataChanged(updatedData);
            },
          ),
        ],
      ),
    );
  }
}

// Commercial Form Widget
class CommercialForm extends StatefulWidget {
  final String category;
  final Function(Map<String, dynamic>) onSubmit;

  const CommercialForm({
    super.key,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<CommercialForm> createState() => _CommercialFormState();
}

class _CommercialFormState extends State<CommercialForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'property_id': '',
    'title': '',
    'description': '',
    'price': '',
    'location': '',
    'city': '',
    'state': '',
    'country': 'Nigeria',
    'latitude': '',
    'longitude': '',
    'status': 'Available',
    'lister_name': '',
    'lister_email': '',
    'lister_whatsapp': '',
    'has_internet': false,
    'has_electricity': false,
    'year_built': DateTime.now().year.toString(),
    'area': '',
    'terms_and_condition': '',
    'target_demography': false,
    'demographyData': {
      'demo_countries': <String>[],
      'demo_states': <String>[],
      'demo_lgas': <String>[],
      'edmo_ageGroup': 'All',
      'class': 'All',
      'occupations': <String>[],
    },
    'is_Urgent': false,
    'urgencyData': {
      'reason': '',
      'deadline': '',
    },
    'images': <String>[],
  };

  bool _isUploading = false;

  final cloudinary = CloudinaryPublic(
    'dxhrlaz6j',
    'mipripity',
    cache: false,
  );

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _formData['images'].addAll(result.paths.whereType<String>());
      });
    }
  }

  Future<String?> uploadImageToCloudinary(String filePath) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    List<String> imageUrls = [];
    for (String path in _formData['images']) {
      if (path.startsWith('http')) {
        imageUrls.add(path);
      } else {
        String? url = await uploadImageToCloudinary(path);
        if (url != null) imageUrls.add(url);
      }
    }
    _formData['images'] = imageUrls;

    setState(() => _isUploading = false);

    widget.onSubmit(_formData);
  }
  
  String _generateWhatsAppLink(String number) {
    if (number.isEmpty) return '';
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return 'https://wa.me/$cleanNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commercial Property Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 24),
          
          ImageUploadWidget(
            images: _formData['images'],
            onImagesChanged: (images) {
              setState(() {
                _formData['images'] = images;
              });
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
              hintText: 'Enter a descriptive title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 5) {
                return 'Title must be at least 5 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['title'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description *',
              border: OutlineInputBorder(),
              hintText: 'Provide detailed description',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['description'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Status *',
              border: OutlineInputBorder(),
            ),
            value: _formData['status'],
            items: ['Available', 'Pending', 'Sold'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData['status'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a status';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Market Value (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['marketValue'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['price'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Location *',
              border: OutlineInputBorder(),
              hintText: 'City, State, Country',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
            onSaved: (value) {
              _formData['location'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['latitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['latitude'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['longitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['longitude'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          NetworkSignalDisplay(
            latitude: double.tryParse(_formData['latitude'] ?? '0') ?? 0,
            longitude: double.tryParse(_formData['longitude'] ?? '0') ?? 0,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number *',
              border: OutlineInputBorder(),
              prefixText: '+',
              hintText: '234XXXXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your WhatsApp number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
            onSaved: (value) {
              _formData['whatsappNumber'] = value ?? '';
              if (value != null && value.isNotEmpty) {
                _formData['whatsappLink'] = _generateWhatsAppLink(value);
              } else {
                _formData['whatsappLink'] = '';
              }
            },
          ),
          const SizedBox(height: 24),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Terms & Conditions',
              border: OutlineInputBorder(),
              hintText: 'Enter your terms and conditions',
            ),
            maxLines: 3,
            onSaved: (value) {
              _formData['termsAndConditions'] = value ?? '';
            },
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Internet Available'),
            value: _formData['hasInternet'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['hasInternet'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          SwitchListTile(
            title: const Text('24/7 Electricity'),
            value: _formData['hasElectricity'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['hasElectricity'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          const SizedBox(height: 24),

          const Text(
            'Scope',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Target Specific Demography'),
            subtitle: const Text('Specify who should see this listing'),
            value: _formData['targetDemography'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['targetDemography'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['targetDemography'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: DemographyFormWidget(
                demographyData: _formData['demographyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['demographyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 24),

          const Text(
            'Premium Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Urgent Sale'),
            subtitle: const Text('Mark this as urgent for faster visibility'),
            value: _formData['isUrgent'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['isUrgent'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['isUrgent'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: UrgencyFormWidget(
                urgencyData: _formData['urgencyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['urgencyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF39322),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Residential Form Widget
class ResidentialForm extends StatefulWidget {
  final String category;
  final Function(Map<String, dynamic>) onSubmit;

  const ResidentialForm({
    super.key,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<ResidentialForm> createState() => _ResidentialFormState();
}

class _ResidentialFormState extends State<ResidentialForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'property_id': '',
    'title': '',
    'description': '',
    'marketValue': '',
    'price': '',
    'location': '',
    'city': '',
    'state': '',
    'country': 'Nigeria',
    'latitude': '',
    'longitude': '',
    'status': 'Available',
    'lister_name': '',
    'lister_email': '',
    'lister_whatsapp': '',
    'bedrooms': '1',
    'bathrooms': '1',
    'toilets': '1',
    'parking_spaces': '0',
    'has_internet': false,
    'has_electricity': false,
    'year_built': DateTime.now().year.toString(),
    'area': '',
    'terms_and_condition': '',
    'target_demography': false,
    'demographyData': {
      'demo_countries': <String>[],
      'demo_states': <String>[],
      'demo_lgas': <String>[],
      'edmo_ageGroup': 'All',
      'class': 'All',
      'occupations': <String>[],
    },
    'is_Urgent': false,
    'urgencyData': {
      'reason': '',
      'deadline': '',
    },
    'images': <String>[],
  };

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if ((_formData['images'] as List<String>).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onSubmit({
        ..._formData,
        'category': widget.category,
        'type': 'residential',
      });
    }
  }

  String _generateWhatsAppLink(String number) {
    if (number.isEmpty) return '';
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return 'https://wa.me/$cleanNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Residential Property Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 24),
          
          ImageUploadWidget(
            images: _formData['images'],
            onImagesChanged: (images) {
              setState(() {
                _formData['images'] = images;
              });
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
              hintText: 'Enter a descriptive title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 5) {
                return 'Title must be at least 5 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['title'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description *',
              border: OutlineInputBorder(),
              hintText: 'Provide detailed description',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['description'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Status *',
              border: OutlineInputBorder(),
            ),
            value: _formData['status'],
            items: ['Available', 'Pending', 'Sold'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData['status'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a status';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Market Value (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['marketValue'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['price'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Location *',
              border: OutlineInputBorder(),
              hintText: 'City, State, Country',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
            onSaved: (value) {
              _formData['location'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['latitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['latitude'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['longitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['longitude'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          NetworkSignalDisplay(
            latitude: double.tryParse(_formData['latitude'] ?? '0') ?? 0,
            longitude: double.tryParse(_formData['longitude'] ?? '0') ?? 0,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number *',
              border: OutlineInputBorder(),
              prefixText: '+',
              hintText: '234XXXXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your WhatsApp number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
            onSaved: (value) {
              _formData['whatsappNumber'] = value ?? '';
              if (value != null && value.isNotEmpty) {
                _formData['whatsappLink'] = _generateWhatsAppLink(value);
              } else {
                _formData['whatsappLink'] = '';
              }
            },
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Property Features',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Bedrooms',
                  _formData['bedrooms'] ?? '1',
                  (value) {
                    setState(() {
                      _formData['bedrooms'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  'Bathrooms',
                  _formData['bathrooms'] ?? '1',
                  (value) {
                    setState(() {
                      _formData['bathrooms'] = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Toilets',
                  _formData['toilets'] ?? '1',
                  (value) {
                    setState(() {
                      _formData['toilets'] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  'Parking Spaces',
                  _formData['parkingSpaces'] ?? '0',
                  (value) {
                    setState(() {
                      _formData['parkingSpaces'] = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Terms & Conditions',
              border: OutlineInputBorder(),
              hintText: 'Enter your terms and conditions',
            ),
            maxLines: 3,
            onSaved: (value) {
              _formData['termsAndConditions'] = value ?? '';
            },
          ),
          const SizedBox(height: 24),

          const Text(
            'Scope',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Target Specific Demography'),
            subtitle: const Text('Specify who should see this listing'),
            value: _formData['targetDemography'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['targetDemography'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['targetDemography'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: DemographyFormWidget(
                demographyData: _formData['demographyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['demographyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 24),

          const Text(
            'Premium Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Urgent Sale'),
            subtitle: const Text('Mark this as urgent for faster visibility'),
            value: _formData['isUrgent'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['isUrgent'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['isUrgent'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: UrgencyFormWidget(
                urgencyData: _formData['urgencyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['urgencyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF39322),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  final currentValue = int.tryParse(value) ?? 0;
                  if (currentValue > 0) {
                    onChanged((currentValue - 1).toString());
                  }
                },
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final currentValue = int.tryParse(value) ?? 0;
                  onChanged((currentValue + 1).toString());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Land Form Widget
class LandForm extends StatefulWidget {
  final String category;
  final Function(Map<String, dynamic>) onSubmit;

  const LandForm({
    super.key,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<LandForm> createState() => _LandFormState();
}

class _LandFormState extends State<LandForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'property_id': '',
    'title': '',
    'description': '',
    'price': '',
    'location': '',
    'city': '',
    'state': '',
    'country': 'Nigeria',
    'latitude': '',
    'longitude': '',
    'status': 'Available',
    'lister_name': '',
    'lister_email': '',
    'lister_whatsapp': '',
    'land_title': '', // DB field name
    'land_size': '', // DB field name
    'has_internet': false,
    'has_electricity': false,
    'area': '',
    'is_verified': false,
    'is_active': true,
    'terms_and_condition': '',
    'target_demography': false,
    'demographyData': {
      'demo_countries': <String>[],
      'demo_states': <String>[],
      'demo_lgas': <String>[],
      'edmo_ageGroup': 'All',
      'class': 'All',
      'occupations': <String>[],
    },
    'is_Urgent': false,
    'urgencyData': {
      'reason': '',
      'deadline': '',
    },
    'images': <String>[],
  };

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if ((_formData['images'] as List<String>).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onSubmit({
        ..._formData,
        'category': widget.category,
        'type': 'land',
      });
    }
  }

  String _generateWhatsAppLink(String number) {
    if (number.isEmpty) return '';
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return 'https://wa.me/$cleanNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Land Property Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 24),
          
          ImageUploadWidget(
            images: _formData['images'],
            onImagesChanged: (images) {
              setState(() {
                _formData['images'] = images;
              });
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
              hintText: 'Enter a descriptive title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 5) {
                return 'Title must be at least 5 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['title'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description *',
              border: OutlineInputBorder(),
              hintText: 'Provide detailed description',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['description'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Status *',
              border: OutlineInputBorder(),
            ),
            value: _formData['status'],
            items: ['Available', 'Pending', 'Sold'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData['status'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a status';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Market Value (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['marketValue'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['price'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Location *',
              border: OutlineInputBorder(),
              hintText: 'City, State, Country',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
            onSaved: (value) {
              _formData['location'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['latitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['latitude'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['longitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['longitude'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          NetworkSignalDisplay(
            latitude: double.tryParse(_formData['latitude'] ?? '0') ?? 0,
            longitude: double.tryParse(_formData['longitude'] ?? '0') ?? 0,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number *',
              border: OutlineInputBorder(),
              prefixText: '+',
              hintText: '234XXXXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your WhatsApp number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
            onSaved: (value) {
              _formData['whatsappNumber'] = value ?? '';
              if (value != null && value.isNotEmpty) {
                _formData['whatsappLink'] = _generateWhatsAppLink(value);
              } else {
                _formData['whatsappLink'] = '';
              }
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Land Title *',
              border: OutlineInputBorder(),
              hintText: 'e.g., Certificate of Occupancy, Deed of Assignment',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a land title';
              }
              return null;
            },
            onSaved: (value) {
              _formData['landTitle'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Land Size (sqm) *',
              border: OutlineInputBorder(),
              hintText: 'Enter size in square meters',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the land size';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
            onSaved: (value) {
              _formData['landSize'] = value;
            },
          ),
          
          const SizedBox(height: 24),

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Terms & Conditions',
              border: OutlineInputBorder(),
              hintText: 'Enter your terms and conditions',
            ),
            maxLines: 3,
            onSaved: (value) {
              _formData['termsAndConditions'] = value ?? '';
            },
          ),
          const SizedBox(height: 24),

          const Text(
            'Scope',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Target Specific Demography'),
            subtitle: const Text('Specify who should see this listing'),
            value: _formData['targetDemography'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['targetDemography'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['targetDemography'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: DemographyFormWidget(
                demographyData: _formData['demographyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['demographyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 24),

          const Text(
            'Premium Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Urgent Sale'),
            subtitle: const Text('Mark this as urgent for faster visibility'),
            value: _formData['isUrgent'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['isUrgent'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['isUrgent'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: UrgencyFormWidget(
                urgencyData: _formData['urgencyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['urgencyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF39322),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Generic Form Widget (Enhanced)
class GenericForm extends StatefulWidget {
  final String category;
  final Function(Map<String, dynamic>) onSubmit;

  const GenericForm({
    super.key,
    required this.category,
    required this.onSubmit,
  });

  @override
  State<GenericForm> createState() => _GenericFormState();
}

class _GenericFormState extends State<GenericForm> {
  String? _tncFileName;
  String? _tncFilePath;
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'property_id': '',
    'title': '',
    'description': '',
    'price': '',
    'location': '',
    'latitude': '',
    'longitude': '',
    'lister_whatsapp': '',
    'status': 'Available',
    'quantity': '',
    'condition': 'New',
    'terms_and_condition': '',
    'target_demography': false,
    'demographyData': {
      'demo_countries': <String>[],
      'demo_states': <String>[],
      'demo_lgas': <String>[],
      'edmo_ageGroup': 'All',
      'class': 'All',
      'occupations': <String>[],
    },
    'is_Urgent': false,
    'urgencyData': {
      'reason': '',
      'deadline': '',
    },
    'images': <String>[],
  };

  final List<String> _conditions = ['New', 'Used', 'Refurbished'];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      if ((_formData['images'] as List<String>).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_tncFilePath != null) {
        _formData['termsAndConditionsFile'] = _tncFilePath;
      }

      widget.onSubmit({
        ..._formData,
        'category': widget.category,
        'type': 'material',
      });
    }
  }

  String _generateWhatsAppLink(String number) {
    if (number.isEmpty) return '';
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    return 'https://wa.me/$cleanNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.category} Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 24),
          
          ImageUploadWidget(
            images: _formData['images'],
            onImagesChanged: (images) {
              setState(() {
                _formData['images'] = images;
              });
            },
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
              hintText: 'Enter a descriptive title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 5) {
                return 'Title must be at least 5 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['title'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description *',
              border: OutlineInputBorder(),
              hintText: 'Provide detailed description',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
            onSaved: (value) {
              _formData['description'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Status *',
              border: OutlineInputBorder(),
            ),
            value: _formData['status'],
            items: ['Available', 'Pending', 'Sold'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData['status'] = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a status';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Market Value (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['marketValue'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (₦) *',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['price'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Location *',
              border: OutlineInputBorder(),
              hintText: 'City, State, Country',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
            onSaved: (value) {
              _formData['location'] = value;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['latitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['latitude'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    hintText: '0.000000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _formData['longitude'] = value;
                    });
                  },
                  onSaved: (value) {
                    _formData['longitude'] = value;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          NetworkSignalDisplay(
            latitude: double.tryParse(_formData['latitude'] ?? '0') ?? 0,
            longitude: double.tryParse(_formData['longitude'] ?? '0') ?? 0,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number *',
              border: OutlineInputBorder(),
              prefixText: '+',
              hintText: '234XXXXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your WhatsApp number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
            onSaved: (value) {
              _formData['whatsappNumber'] = value ?? '';
              if (value != null && value.isNotEmpty) {
                _formData['whatsappLink'] = _generateWhatsAppLink(value);
              } else {
                _formData['whatsappLink'] = '';
              }
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    border: OutlineInputBorder(),
                    hintText: '1',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 1) {
                      return 'Invalid quantity';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formData['quantity'] = value;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Condition *',
                    border: OutlineInputBorder(),
                  ),
                  value: _formData['condition'],
                  items: _conditions.map((condition) {
                    return DropdownMenuItem(
                      value: condition,
                      child: Text(condition),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _formData['condition'] = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a condition';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload T&C Document (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
                          );

                          if (result != null) {
                            setState(() {
                              _tncFileName = result.files.single.name;
                              _tncFilePath = result.files.single.path!;
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('File uploaded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error uploading file: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_tncFileName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Uploaded: $_tncFileName',
                              style: const TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                _tncFileName = null;
                                _tncFilePath = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    const Text('OR'),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Enter Terms & Conditions',
                        border: OutlineInputBorder(),
                        hintText: 'Type your terms and conditions here...',
                      ),
                      maxLines: 4,
                      onSaved: (value) {
                        _formData['termsAndConditions'] = value ?? '';
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Scope',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Target Specific Demography'),
            subtitle: const Text('Specify who should see this listing'),
            value: _formData['targetDemography'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['targetDemography'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['targetDemography'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: DemographyFormWidget(
                demographyData: _formData['demographyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['demographyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 24),

          const Text(
            'Premium Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Urgent Sale'),
            subtitle: const Text('Mark this as urgent for faster visibility'),
            value: _formData['isUrgent'] ?? false,
            onChanged: (value) {
              setState(() {
                _formData['isUrgent'] = value;
              });
            },
            activeColor: const Color(0xFFF39322),
          ),
          
          if (_formData['isUrgent'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: UrgencyFormWidget(
                urgencyData: _formData['urgencyData'],
                onDataChanged: (data) {
                  setState(() {
                    _formData['urgencyData'] = data;
                  });
                },
              ),
            ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFF39322),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}