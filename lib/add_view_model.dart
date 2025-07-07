import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'services/image_upload_service.dart';
import 'api/property_api.dart';

class AddViewModel extends ChangeNotifier {
  String? selectedCategory;
  bool showForm = false;
  bool formSubmitted = false;
  String activeTab = 'add';
  
  // List to store uploaded image URLs
  List<String> uploadedImageUrls = [];
  
  // List to store local image files before upload
  List<File> selectedImages = [];

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
    errorMessage = null;
    notifyListeners();
  }

  void closeForm() {
    showForm = false;
    selectedCategory = null;
    formSubmitted = false;
    errorMessage = null;
    isSubmitting = false;
    selectedImages.clear();
    uploadedImageUrls.clear();
    notifyListeners();
  }

  // Database service instance
  final DatabaseService _databaseService = DatabaseService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  
  // Error handling
  String? errorMessage;
  bool isSubmitting = false;
  
  // Method to pick multiple images from gallery (Fixed version)
  Future<void> pickImages() async {
    try {
      // Use getMultiImage() instead of pickMultipleImages()
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty) {
        // Clear previous selections
        selectedImages.clear();
        
        // Convert XFile to File and add to list
        for (XFile xFile in pickedFiles) {
          final File imageFile = File(xFile.path);
          
          // Validate image before adding
          if (ImageUploadService.isValidImageFile(imageFile)) {
            // Check file size
            if (await ImageUploadService.isValidFileSize(imageFile)) {
              selectedImages.add(imageFile);
            } else {
              print('Skipping image ${xFile.name}: File too large');
            }
          } else {
            print('Skipping image ${xFile.name}: Invalid format');
          }
        }
        
        if (selectedImages.isNotEmpty) {
          print('Selected ${selectedImages.length} valid images');
          errorMessage = null;
        } else {
          errorMessage = 'No valid images selected. Please choose images under 10MB.';
        }
        
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error picking images: ${e.toString()}';
      notifyListeners();
      print("Error in pickImages: $e");
    }
  }

  // Alternative method for older versions of image_picker
  Future<void> pickImagesAlternative() async {
    try {
      // For older versions that don't support pickMultiImage
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        // Validate image before adding
        if (ImageUploadService.isValidImageFile(imageFile)) {
          // Check file size
          if (await ImageUploadService.isValidFileSize(imageFile)) {
            selectedImages.add(imageFile);
            errorMessage = null;
            print('Selected image: ${pickedFile.path}');
          } else {
            errorMessage = 'Image is too large. Maximum size is 10MB.';
          }
        } else {
          errorMessage = 'Invalid image format. Please select a valid image.';
        }
        
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error picking image: ${e.toString()}';
      notifyListeners();
      print("Error in pickImagesAlternative: $e");
    }
  }

  // Method to pick a single image from gallery
  Future<void> pickSingleImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        // Validate image before adding
        if (ImageUploadService.isValidImageFile(imageFile)) {
          // Check file size
          if (await ImageUploadService.isValidFileSize(imageFile)) {
            selectedImages.add(imageFile);
            errorMessage = null;
            print('Selected image: ${pickedFile.path}');
          } else {
            errorMessage = 'Image is too large. Maximum size is 10MB.';
          }
        } else {
          errorMessage = 'Invalid image format. Please select a valid image.';
        }
        
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error picking image: ${e.toString()}';
      notifyListeners();
      print("Error in pickSingleImage: $e");
    }
  }

  // Method to upload selected images to Cloudinary
  Future<bool> uploadSelectedImages() async {
    if (selectedImages.isEmpty) {
      print('No images selected for upload');
      return true; // Return true if no images to upload
    }

    try {
      print('Uploading ${selectedImages.length} images to Cloudinary...');
      
      // Convert File objects to file paths
      List<String> imagePaths = selectedImages.map((file) => file.path).toList();
      
      // Upload using the existing service
      UploadResult uploadResult = await ImageUploadService.uploadMultipleToCloudinary(imagePaths);
      
      if (uploadResult.isSuccess) {
        // All images uploaded successfully
        uploadedImageUrls.addAll(uploadResult.successUrls);
        print('Successfully uploaded ${uploadResult.successUrls.length} images');
        return true;
      } else if (uploadResult.isPartialSuccess) {
        // Some images failed, but some succeeded
        uploadedImageUrls.addAll(uploadResult.successUrls);
        print('Partially successful upload: ${uploadResult.successUrls.length} succeeded, ${uploadResult.failedPaths.length} failed');
        
        // Show warning but continue
        errorMessage = 'Some images failed to upload. ${uploadResult.successUrls.length} images uploaded successfully.';
        notifyListeners();
        return true;
      } else {
        // All uploads failed
        String errorReason = uploadResult.errorMessage ?? 'Unknown error';
        errorMessage = 'Failed to upload images: $errorReason';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Error uploading images: ${e.toString()}';
      notifyListeners();
      print('Error in uploadSelectedImages: $e');
      return false;
    }
  }

  // Remove a selected image
  void removeSelectedImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  // Remove an uploaded image
  void removeUploadedImage(int index) {
    if (index >= 0 && index < uploadedImageUrls.length) {
      uploadedImageUrls.removeAt(index);
      notifyListeners();
    }
  }

  // Get the current user's email
  Future<String?> _getCurrentUserEmail() async {
    try {
      // First try to get user profile
      final userProfile = await _userService.getCurrentUserProfile();
      if (userProfile != null && userProfile['email'] != null) {
        print('Retrieved user email: ${userProfile['email']}');
        return userProfile['email'] as String;
      }
      
      // If profile doesn't have email, try using the ID to fetch details
      final userId = await _userService.getCurrentUserId();
      if (userId != null) {
        final userDetails = await _userService.getUserById(userId);
        if (userDetails != null && userDetails['email'] != null) {
          print('Retrieved user email by ID: ${userDetails['email']}');
          return userDetails['email'] as String;
        }
      }
      
      // Last resort: check shared preferences for cached email
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('user_email');
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        print('Using cached email from preferences: $cachedEmail');
        return cachedEmail;
      }
      
      print('Warning: Could not retrieve user email');
      return null;
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

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
      
      // Get current user ID
      int userId;
      try {
        final currentUserId = await _userService.getCurrentUserId();
        if (currentUserId != null) {
          userId = currentUserId;
          print('Using existing user ID: $userId');
        } else {
          print('No user ID found, using default ID');
          userId = 1;
          await _userService.saveCurrentUserId(userId);
        }
      } catch (e) {
        print('Error getting user ID: $e, using default ID');
        userId = 1;
        try {
          await _userService.saveCurrentUserId(userId);
        } catch (_) {}
      }
      
      // Get user email and add to data
      final userEmail = await _getCurrentUserEmail();
      if (userEmail != null && userEmail.isNotEmpty) {
        data['lister_email'] = userEmail;
      } else {
        data['lister_email'] = 'demo@mipripity.com';
        print('Using fallback email: demo@mipripity.com');
      }
      
      // Process form data
      print('Submitting property to API: ${data['title']}');
      
      // Set property type based on category
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
      
      // Generate a unique property_id
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomPart = (userId * 1000 + timestamp % 1000).toString().padLeft(4, '0');
      data['property_id'] = 'PROP-${timestamp.toString().substring(timestamp.toString().length - 6)}-$randomPart';
      print('Generated property_id: ${data['property_id']}');
      
      // Upload images first
      if (selectedImages.isNotEmpty) {
        print('Uploading ${selectedImages.length} selected images...');
        bool uploadSuccess = await uploadSelectedImages();
        
        if (!uploadSuccess) {
          print('Image upload failed, cannot proceed with property submission');
          return false;
        }
      }
      
      // Add uploaded image URLs to data
      data['images'] = uploadedImageUrls;
      print('Added ${uploadedImageUrls.length} image URLs to property data');
      
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
        _showSuccessMessage();
        
        // Clear images after successful submission
        selectedImages.clear();
        uploadedImageUrls.clear();
        
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

  // Legacy method that uses database service
  Future<void> submitForm(Map<String, dynamic> data) async {
    try {
      // Upload images first if any are selected
      if (selectedImages.isNotEmpty) {
        print('Uploading ${selectedImages.length} selected images before form submission...');
        bool uploadSuccess = await uploadSelectedImages();
        
        if (!uploadSuccess) {
          print('Image upload failed, cannot proceed with form submission');
          return;
        }
      }
      
      // Add uploaded image URLs to form data
      data['images'] = uploadedImageUrls;
      print('Added ${uploadedImageUrls.length} image URLs to form data');
      
      // Prepare the form data
      await _prepareFormData(data);
      
      // Generate property_id if not present
      if (!data.containsKey('property_id') || data['property_id'] == null || data['property_id'].toString().isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final userId = await _userService.getCurrentUserId() ?? 1;
        final randomPart = (userId * 1000 + timestamp % 1000).toString().padLeft(4, '0');
        data['property_id'] = 'PROP-${timestamp.toString().substring(timestamp.toString().length - 6)}-$randomPart';
        print('Generated property_id for form submission: ${data['property_id']}');
      }
      
      // Try API submission first
      bool apiSuccess = await submitProperty(data);
      
      if (apiSuccess) {
        formSubmitted = true;
        _showSuccessMessage();
        return;
      }
      
      // Fallback to database submission
      print('API submission failed, falling back to database submission');
      
      int userId;
      try {
        final currentUserId = await _userService.getCurrentUserId();
        userId = currentUserId ?? 1;
      } catch (e) {
        print('Error getting user ID for database submission: $e, using default ID');
        userId = 1;
      }
      
      final success = await _databaseService.submitCompleteListing(
        formData: data,
        userId: userId,
      );
      
      if (success) {
        print('Listing submitted successfully to database');
        formSubmitted = true;
        _showSuccessMessage();
        
        // Clear images after successful submission
        selectedImages.clear();
        uploadedImageUrls.clear();
      } else {
        // Save to shared preferences for later sync
        try {
          final prefs = await SharedPreferences.getInstance();
          final pendingListings = prefs.getStringList('pending_listings') ?? [];
          pendingListings.add(jsonEncode(data));
          await prefs.setStringList('pending_listings', pendingListings);
          
          formSubmitted = true;
          _showSuccessMessage();
          print('Listing saved to pending submissions for later sync');
          
          // Clear images after successful save
          selectedImages.clear();
          uploadedImageUrls.clear();
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
  Future<bool> _prepareFormData(Map<String, dynamic> data) async {
    // Set default values
    data['submittedAt'] = DateTime.now().toIso8601String();
    data['status'] = data['status'] ?? 'Available';
    data['category'] = selectedCategory ?? data['category'] ?? 'Unknown';
    
    // Generate property_id if not present
    if (!data.containsKey('property_id') || data['property_id'] == null || data['property_id'].toString().isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = await _userService.getCurrentUserId() ?? 1;
      final randomPart = (userId * 1000 + timestamp % 1000).toString().padLeft(4, '0');
      data['property_id'] = 'PROP-${timestamp.toString().substring(timestamp.toString().length - 6)}-$randomPart';
      print('Generated property_id for form preparation: ${data['property_id']}');
    }
    
    // Set lister_whatsapp
    if (data['whatsappNumber'] != null && data['whatsappNumber'].toString().isNotEmpty) {
      data['lister_whatsapp'] = data['whatsappNumber'];
    } else if (data['lister_whatsapp'] == null || data['lister_whatsapp'].toString().isEmpty) {
      data['lister_whatsapp'] = '+2348000000000';
    }
    
    // Set lister_email
    final userEmail = await _getCurrentUserEmail();
    if (userEmail != null && userEmail.isNotEmpty) {
      data['lister_email'] = userEmail;
    } else {
      data['lister_email'] = 'demo@mipripity.com';
    }
    
    // Images are already handled in submitForm method
    if (!data.containsKey('images')) {
      data['images'] = uploadedImageUrls;
    }
    
    return true;
  }

  // Validate form data
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
    if (data['whatsappNumber'] != null && data['whatsappNumber'].toString().isNotEmpty) {
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

    if (errors.isNotEmpty) {
      errorMessage = 'Please fix the following errors:\n• ${errors.join('\n• ')}';
      notifyListeners();
      return false;
    }

    return true;
  }

  void _showSuccessMessage() {
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

  void retrySubmission(Map<String, dynamic> data) {
    errorMessage = null;
    notifyListeners();
    submitForm(data);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void resetForm() {
    selectedCategory = null;
    showForm = false;
    formSubmitted = false;
    errorMessage = null;
    isSubmitting = false;
    selectedImages.clear();
    uploadedImageUrls.clear();
    notifyListeners();
  }
}