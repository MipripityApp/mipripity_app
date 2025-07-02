import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'services/image_upload_service.dart';

class AddViewModel extends ChangeNotifier {
  String? selectedCategory;
  bool showForm = false;
  bool formSubmitted = false;
  String activeTab = 'add';

  // List of material items
  final List<String> materialItems = [
    'Chair', 'Table', 'Bath Tub', 'Mirror', 'Sofa', 'A.C', 'Television', 
    'Speaker', 'Fan', 'Curtain', 'Window', 'Iron', 'Tiles', 'Clock', 
    'Door', 'Fence wire', 'Paint', 'Art work', 'Artifact', 'Cement', 
    'Sand', 'Tank', 'Gate', 'Console'
  ];

  // List of commercial properties
  final List<String> commercialProperties = [
    'Warehouse', 'Store', 'Factory', 'Office', 'Company'
  ];

  // List of residential properties
  final List<String> residentialProperties = [
    'Duplex', 'Story Building', 'Co-Living Space', 'Studio Apartment',
    'Serviced Apartment', 'Single Room', 'Garden Apartment', 'Luxury Apartment',
    'Cortage', '2 Bedroom Flat', 'Loft Apartment', 'Farm House', 'Condimonium',
    'Room & Palor', 'Vacation Home', 'Town House', '3 Bedroom Flat',
    '1 Room Self Contain', 'Pent House', 'Bungalow Single Room', '4 Bedroom Flat',
    'Estate', 'Bungalow Flat', 'Block of Flat', 'Villa', 'Mini Flat'
  ];

  // List of land properties
  final List<String> landProperties = ['Land'];

  void selectCategory(String category) {
    selectedCategory = category;
    showForm = true;
    formSubmitted = false;
    errorMessage = null; // Clear any previous errors
    notifyListeners();
  }

  void closeForm() {
    showForm = false;
    selectedCategory = null;
    formSubmitted = false;
    errorMessage = null;
    isSubmitting = false;
    notifyListeners();
  }

  // Database service instance
  final DatabaseService _databaseService = DatabaseService();
  final UserService _userService = UserService();
  
  // Error handling
  String? errorMessage;
  bool isSubmitting = false;

  // Enhanced submit form data to database with better error handling and Cloudinary image upload
  Future<void> submitForm(Map<String, dynamic> data) async {
    try {
      // Validate required fields before submission
      if (!_validateFormData(data)) {
        return;
      }

      // Update UI state
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();
      
      // Get current user ID
      final userId = await _userService.getOrCreateDefaultUser();
      
      // Process form data
      print('Submitting listing to database: ${data['title']}');
      
      // Upload images to Cloudinary first
      print('Uploading images to Cloudinary...');
      List<String> imagePaths = List<String>.from(data['images'] ?? []);
      
      if (imagePaths.isNotEmpty) {
        List<String> uploadedImageUrls = await ImageUploadService.uploadMultipleToCloudinary(imagePaths);
        
        if (uploadedImageUrls.isEmpty && imagePaths.isNotEmpty) {
          errorMessage = 'Failed to upload images. Please check your internet connection and try again.';
          isSubmitting = false;
          notifyListeners();
          return;
        }
        
        // Replace local paths with Cloudinary URLs
        data['images'] = uploadedImageUrls;
        print('Uploaded ${uploadedImageUrls.length} images to Cloudinary');
      }
      
      // Add timestamp and additional metadata
      data['submittedAt'] = DateTime.now().toIso8601String();
      data['userId'] = userId;
      
      // Submit to database with uploaded image URLs
      final success = await _databaseService.submitCompleteListing(
        formData: data,
        userId: userId,
      );
      
      if (success) {
        print('Listing submitted successfully to database');
        formSubmitted = true;
        
        // Show success message
        _showSuccessMessage();
      } else {
        errorMessage = 'Failed to submit listing to database. Please check your internet connection and try again.';
        print(errorMessage);
      }
    } catch (e) {
      errorMessage = 'An unexpected error occurred: ${e.toString()}. Please try again.';
      print('Exception submitting form: $e');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // Validate form data before submission
  bool _validateFormData(Map<String, dynamic> data) {
    final List<String> errors = [];

    // Check required fields
    if (data['title'] == null || data['title'].toString().trim().isEmpty) {
      errors.add('Title is required');
    }

    if (data['description'] == null || data['description'].toString().trim().isEmpty) {
      errors.add('Description is required');
    }

    if (data['price'] == null || data['price'].toString().trim().isEmpty) {
      errors.add('Price is required');
    }

    if (data['location'] == null || data['location'].toString().trim().isEmpty) {
      errors.add('Location is required');
    }

    if (data['whatsappNumber'] == null || data['whatsappNumber'].toString().trim().isEmpty) {
      errors.add('WhatsApp number is required');
    }

    // Check if images are provided
    final images = data['images'] as List<String>?;
    if (images == null || images.isEmpty) {
      errors.add('At least one image is required');
    }

    // Validate price format
    if (data['price'] != null) {
      final price = double.tryParse(data['price'].toString());
      if (price == null || price <= 0) {
        errors.add('Please enter a valid price');
      }
    }

    // Validate market value format
    if (data['marketValue'] != null && data['marketValue'].toString().isNotEmpty) {
      final marketValue = double.tryParse(data['marketValue'].toString());
      if (marketValue == null || marketValue <= 0) {
        errors.add('Please enter a valid market value');
      }
    }

    // Validate WhatsApp number format
    if (data['whatsappNumber'] != null) {
      final whatsappNumber = data['whatsappNumber'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (whatsappNumber.length < 10) {
        errors.add('Please enter a valid WhatsApp number');
      }
    }

    // Type-specific validations
    if (data['type'] == 'material') {
      if (data['quantity'] == null || data['quantity'].toString().trim().isEmpty) {
        errors.add('Quantity is required for material items');
      } else {
        final quantity = int.tryParse(data['quantity'].toString());
        if (quantity == null || quantity <= 0) {
          errors.add('Please enter a valid quantity');
        }
      }
    }

    if (data['type'] == 'residential') {
      // Validate bedroom/bathroom counts
      final bedrooms = int.tryParse(data['bedrooms']?.toString() ?? '0');
      final bathrooms = int.tryParse(data['bathrooms']?.toString() ?? '0');
      
      if (bedrooms == null || bedrooms < 0) {
        errors.add('Please enter a valid number of bedrooms');
      }
      
      if (bathrooms == null || bathrooms < 0) {
        errors.add('Please enter a valid number of bathrooms');
      }
    }

    if (data['type'] == 'land') {
      if (data['landSize'] == null || data['landSize'].toString().trim().isEmpty) {
        errors.add('Land size is required');
      } else {
        final landSize = double.tryParse(data['landSize'].toString());
        if (landSize == null || landSize <= 0) {
          errors.add('Please enter a valid land size');
        }
      }
      
      if (data['landTitle'] == null || data['landTitle'].toString().trim().isEmpty) {
        errors.add('Land title is required');
      }
    }

    // If there are validation errors, set error message
    if (errors.isNotEmpty) {
      errorMessage = 'Please fix the following errors:\n• ${errors.join('\n• ')}';
      notifyListeners();
      return false;
    }

    return true;
  }

  // Show success message (you can customize this)
  void _showSuccessMessage() {
    // This could trigger a snackbar or other UI feedback
    print('Form submitted successfully!');
  }

  void setActiveTab(String tab) {
    activeTab = tab;
    notifyListeners();
  }

  bool isMaterialItem(String category) {
    return materialItems.contains(category);
  }

  bool isCommercialProperty(String category) {
    return commercialProperties.contains(category);
  }

  bool isResidentialProperty(String category) {
    return residentialProperties.contains(category);
  }

  bool isLandProperty(String category) {
    return landProperties.contains(category);
  }

  // Method to retry submission
  void retrySubmission(Map<String, dynamic> data) {
    errorMessage = null;
    notifyListeners();
    submitForm(data);
  }

  // Method to clear error
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // Method to reset form state
  void resetForm() {
    selectedCategory = null;
    showForm = false;
    formSubmitted = false;
    errorMessage = null;
    isSubmitting = false;
    notifyListeners();
  }
}