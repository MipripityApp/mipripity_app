import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'services/image_upload_service.dart';
import 'api/property_api.dart';

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

  // New submitProperty method to call the PropertyApi
  Future<bool> submitProperty(Map<String, dynamic> data) async {
    try {
      // Validate required fields before submission
      if (!_validateFormData(data)) {
        return false;
      }

      // Update UI state
      isSubmitting = true;
      errorMessage = null;
      notifyListeners();
      
      // Get current user ID from preferences directly - don't try to create a new user
      int userId;
      try {
        // Only get the existing user ID, don't try to create a new one
        final currentUserId = await _userService.getCurrentUserId();
        if (currentUserId != null) {
          userId = currentUserId;
          print('Using existing user ID: $userId');
        } else {
          // If no user ID found, use default
          print('No user ID found, using default ID');
          userId = 1; // Use default ID as fallback
          // Save this default ID to preferences
          await _userService.saveCurrentUserId(userId);
        }
      } catch (e) {
        // If user service fails, use a default user ID
        print('Error getting user ID: $e, using default ID');
        userId = 1; // Use default ID as fallback
        try {
          await _userService.saveCurrentUserId(userId);
        } catch (_) {
          // Ignore errors when saving default user ID
        }
      }
      
      // Process form data
      print('Submitting property to API: ${data['title']}');
      
      // Make sure property type is set based on category if not already defined
      if (!data.containsKey('type') && selectedCategory != null) {
        if (isResidentialProperty(selectedCategory!)) {
          data['type'] = 'residential';
        } else if (isCommercialProperty(selectedCategory!)) {
          data['type'] = 'commercial';
        } else if (isLandProperty(selectedCategory!)) {
          data['type'] = 'land';
        } else if (isMaterialItem(selectedCategory!)) {
          data['type'] = 'material';
        } else {
          data['type'] = 'generic';
        }
        print('Set property type to ${data['type']} based on category $selectedCategory');
      }
      
      // Upload images to Cloudinary first
      print('Uploading images to Cloudinary...');
      List<String> imagePaths = List<String>.from(data['images'] ?? []);
      
      if (imagePaths.isNotEmpty) {
        // Filter out blob URLs that can't be processed
        List<String> processableImages = imagePaths.where((path) => 
          !path.startsWith('blob:') || path.startsWith('http')
        ).toList();
        
        if (processableImages.isEmpty && imagePaths.isNotEmpty) {
          // All images are blob URLs and can't be processed
          print('Warning: All selected images are blob URLs which cannot be processed directly.');
          // Continue with submission but with empty images array
          data['images'] = [];
        } else {
          List<String> uploadedImageUrls = await ImageUploadService.uploadMultipleToCloudinary(processableImages);
          
          if (uploadedImageUrls.isEmpty && processableImages.isNotEmpty) {
            print('Warning: Failed to upload images. Continuing with submission without images.');
            data['images'] = [];
          } else {
            // Replace local paths with Cloudinary URLs
            data['images'] = uploadedImageUrls;
            print('Uploaded ${uploadedImageUrls.length}/${processableImages.length} images to Cloudinary');
          }
        }
      }
      
      // Add timestamp and additional metadata
      data['submittedAt'] = DateTime.now().toIso8601String();
      data['userId'] = userId;
      data['lister_whatsapp'] = data['whatsappNumber'] ?? '';
      data['category'] = selectedCategory ?? data['category'] ?? 'Unknown';
      
      // Call the PropertyApi to post the property
      final success = await PropertyApi.postProperty(data);
      
      if (success) {
        print('Property submitted successfully to API');
        formSubmitted = true;
        
        // Show success message
        _showSuccessMessage();
        return true;
      } else {
        errorMessage = 'Failed to submit property to API. Please check your internet connection and try again.';
        print(errorMessage);
        return false;
      }
    } catch (e) {
      errorMessage = 'An unexpected error occurred: ${e.toString()}. Please try again.';
      print('Exception submitting property: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // Legacy method that uses database service - we'll update this to use our new submitProperty method
  Future<void> submitForm(Map<String, dynamic> data) async {
    try {
      // Prepare the form data before submission
      _prepareFormData(data);
      
      // First, attempt to submit via the API
      bool apiSuccess = await submitProperty(data);
      
      if (apiSuccess) {
        // If API submission was successful, we're done
        formSubmitted = true;
        _showSuccessMessage();
        return;
      }
      
      // If API submission failed, fall back to database submission
      print('API submission failed, falling back to database submission');
      
      // Get current user ID from preferences directly - don't try to create a new user
      int userId;
      try {
        // Only get the existing user ID, don't try to create a new one
        final currentUserId = await _userService.getCurrentUserId();
        userId = currentUserId ?? 1;
      } catch (e) {
        print('Error getting user ID for database submission: $e, using default ID');
        userId = 1; // Use default ID as fallback
      }
      
      // Submit to database as fallback
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
        // Try one more approach - save to shared preferences for later sync
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingListings = prefs.getStringList('pending_listings') ?? [];
          pendingListings.add(jsonEncode(data));
          await prefs.setStringList('pending_listings', pendingListings);
          
          formSubmitted = true;
          _showSuccessMessage();
          print('Listing saved to pending submissions for later sync');
        } catch (e) {
          errorMessage = 'Failed to submit listing. Please try again later.';
          print('Failed to save listing to shared preferences: $e');
        }
      }
    } catch (e) {
      errorMessage = 'An unexpected error occurred: ${e.toString()}. Please try again.';
      print('Exception submitting form: $e');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // Prepare form data for submission
  void _prepareFormData(Map<String, dynamic> data) {
    // Set default values for missing fields
    data['submittedAt'] = DateTime.now().toIso8601String();
    data['status'] = data['status'] ?? 'Available';
    data['category'] = selectedCategory ?? data['category'] ?? 'Unknown';
    
    // Ensure lister_whatsapp field is set
    if (data['whatsappNumber'] != null && data['whatsappNumber'].toString().isNotEmpty) {
      data['lister_whatsapp'] = data['whatsappNumber'];
    } else if (data['lister_whatsapp'] == null || data['lister_whatsapp'].toString().isEmpty) {
      data['lister_whatsapp'] = '+2348000000000'; // Default number
    }
    
    // Clean up blob URLs from images array
    if (data['images'] != null && data['images'] is List) {
      List<String> images = List<String>.from(data['images']);
      data['images'] = images.where((url) => !url.startsWith('blob:')).toList();
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

    // Make WhatsApp optional but warn if missing
    if (data['whatsappNumber'] == null || data['whatsappNumber'].toString().trim().isEmpty) {
      print('Warning: WhatsApp number is missing, will use default');
    }

    // Make images optional but warn if missing
    final images = data['images'] as List<String>?;
    if (images == null || images.isEmpty) {
      print('Warning: No images provided for the listing');
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