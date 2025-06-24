import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_extended.dart';
import '../services/image_upload_service.dart';

enum OnboardingStep {
  interests,      // Step 1: User interests
  personalInfo,   // Step 2: Personal information
  agencyDetails,  // Step 3: Agency details (conditional)
  profilePhoto,   // Step 4: Profile photo upload
  review,         // Step 5: Review all information
  completed       // Onboarding completed
}

class OnboardingProvider extends ChangeNotifier {
  static const String _baseUrl = 'https://mipripity-api-1.onrender.com';
  
  UserExtended? _user;
  OnboardingStep _currentStep = OnboardingStep.interests;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserExtended? get user => _user;
  OnboardingStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize with user data from registration
  void initWithUser(Map<String, dynamic> userData) {
    _user = UserExtended.fromBasicUser(userData);
    notifyListeners();
  }
  
  // Save the current onboarding state to shared preferences
  Future<void> _saveOnboardingState() async {
    if (_user == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_data', jsonEncode(_user!.toJson()));
      await prefs.setInt('onboarding_step', _currentStep.index);
    } catch (e) {
      print('Error saving onboarding state: $e');
    }
  }
  
  // Load onboarding state from shared preferences
  Future<void> loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingData = prefs.getString('onboarding_data');
      final stepIndex = prefs.getInt('onboarding_step');
      
      if (onboardingData != null) {
        final Map<String, dynamic> userData = jsonDecode(onboardingData);
        _user = UserExtended.fromJson(userData);
      }
      
      if (stepIndex != null) {
        _currentStep = OnboardingStep.values[stepIndex];
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading onboarding state: $e');
    }
  }
  
  // Clear onboarding state
  Future<void> clearOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_data');
      await prefs.remove('onboarding_step');
    } catch (e) {
      print('Error clearing onboarding state: $e');
    }
  }
  
  // Move to the next onboarding step
  void nextStep() {
    if (_currentStep == OnboardingStep.completed) return;
    
    // If user is not an agent or agency, skip the agency details step
    if (_currentStep == OnboardingStep.personalInfo && 
        _user != null && 
        !_user!.isRealEstateAgent) {
      _currentStep = OnboardingStep.profilePhoto;
    } else {
      // Normal progression to next step
      _currentStep = OnboardingStep.values[_currentStep.index + 1];
    }
    
    _saveOnboardingState();
    notifyListeners();
  }
  
  // Move to the previous onboarding step
  void previousStep() {
    if (_currentStep == OnboardingStep.interests) return;
    
    // If user is not an agent or agency, skip the agency details step
    if (_currentStep == OnboardingStep.profilePhoto && 
        _user != null && 
        !_user!.isRealEstateAgent) {
      _currentStep = OnboardingStep.personalInfo;
    } else {
      // Normal progression to previous step
      _currentStep = OnboardingStep.values[_currentStep.index - 1];
    }
    
    _saveOnboardingState();
    notifyListeners();
  }
  
  // Set the current step directly (for navigation from review screen)
  void setCurrentStep(OnboardingStep step) {
    if (_currentStep == step) return;
    
    _currentStep = step;
    _saveOnboardingState();
    notifyListeners();
  }

  // Get authorization headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    
    return headers;
  }
  
  // STEP 1: Update user interests
  Future<bool> updateUserInterests(List<String> interests) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Update local state
      _user = _user!.copyWith(interests: interests);
      
      // Save to API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/${_user!.id}/update-profile'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({'interests': interests}),
      );
      
      _isLoading = false;
      
      if (response.statusCode == 200) {
        await _saveOnboardingState();
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update interests: ${response.body}';
        notifyListeners();
        
        // Even if API call fails, keep local changes and allow continuing
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating interests: $e';
      notifyListeners();
      
      // Even if API call fails, keep local changes and allow continuing
      return true;
    }
  }
  
  // STEP 2: Update personal information
  Future<bool> updatePersonalInfo({
    required String gender,
    required DateTime dateOfBirth,
    required String address,
    required String state,
    required String lga,
  }) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Update local state
      _user = _user!.copyWith(
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
        state: state,
        lga: lga,
      );
      
      // Save to API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/${_user!.id}/update-profile'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'gender': gender,
          'date_of_birth': dateOfBirth.toIso8601String(),
          'address': address,
          'state': state,
          'lga': lga,
        }),
      );
      
      _isLoading = false;
      
      if (response.statusCode == 200) {
        await _saveOnboardingState();
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update personal information: ${response.body}';
        notifyListeners();
        
        // Even if API call fails, keep local changes and allow continuing
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating personal information: $e';
      notifyListeners();
      
      // Even if API call fails, keep local changes and allow continuing
      return true;
    }
  }
  
  // STEP 3: Update agency details
  Future<bool> updateAgencyDetails({
    required String agencyName,
  }) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // First, update local state
      _user = _user!.copyWith(
        agencyName: agencyName,
        agencyVerified: false, // Will be updated by verification API
      );
      
      // Then, verify agency with CAC API (or simulated verification)
      final verificationResponse = await http.post(
        Uri.parse('$_baseUrl/api/users/${_user!.id}/verify-agency'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'agency_name': agencyName,
        }),
      );
      
      _isLoading = false;
      
      if (verificationResponse.statusCode == 200) {
        // Parse verification result
        final verificationResult = jsonDecode(verificationResponse.body);
        final bool verified = verificationResult['verified'] ?? false;
        
        // Update local state with verification result
        _user = _user!.copyWith(agencyVerified: verified);
        await _saveOnboardingState();
        notifyListeners();
        return true;
      } else {
        // Even if verification fails, allow continuing
        _error = 'Agency verification failed: ${verificationResponse.body}';
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating agency details: $e';
      notifyListeners();
      
      // Even if API call fails, keep local changes and allow continuing
      return true;
    }
  }
  
  // STEP 4: Upload profile photo
  Future<bool> uploadProfilePhoto(File imageFile) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Upload image to Cloudinary
      final imageUrl = await ImageUploadService.uploadToCloudinary(imageFile);
      
      if (imageUrl == null) {
        _isLoading = false;
        _error = 'Failed to upload profile photo';
        notifyListeners();
        return false;
      }
      
      // Update local state
      _user = _user!.copyWith(avatarUrl: imageUrl);
      
      // Update profile with avatar URL
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/users/${_user!.id}'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'avatar_url': imageUrl,
        }),
      );
      
      _isLoading = false;
      
      if (response.statusCode == 200) {
        await _saveOnboardingState();
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile photo: ${response.body}';
        notifyListeners();
        
        // Even if API call fails, keep local changes and allow continuing
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error uploading profile photo: $e';
      notifyListeners();
      
      // Even if API call fails, keep local changes and allow continuing
      return true;
    }
  }
  
  // STEP 5: Complete onboarding
  Future<bool> completeOnboarding() async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Mark onboarding as completed
      _user = _user!.copyWith(onboardingCompleted: true);
      
      // Update onboarding status in API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/${_user!.id}/update-profile'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'onboarding_completed': true,
        }),
      );
      
      _isLoading = false;
      
      if (response.statusCode == 200) {
        // Save final state
        await _saveOnboardingState();
        
        // Set current step to completed
        _currentStep = OnboardingStep.completed;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to complete onboarding: ${response.body}';
        notifyListeners();
        
        // Even if API call fails, consider onboarding completed
        _currentStep = OnboardingStep.completed;
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error completing onboarding: $e';
      notifyListeners();
      
      // Even if API call fails, consider onboarding completed
      _currentStep = OnboardingStep.completed;
      return true;
    }
  }
  
  // Get Nigerian states list (mock data for demo)
  List<String> getNigerianStates() {
    return [
      'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 
      'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'FCT', 
      'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 
      'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 
      'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara'
    ];
  }
  
  // Get Local Government Areas for a state (mock data for demo)
  List<String> getLGAsForState(String state) {
    final Map<String, List<String>> lgasByState = {
      'Lagos': ['Alimosho', 'Ajeromi-Ifelodun', 'Kosofe', 'Mushin', 'Oshodi-Isolo', 
                'Ojo', 'Ikorodu', 'Surulere', 'Agege', 'Ifako-Ijaiye', 'Shomolu', 
                'Amuwo-Odofin', 'Lagos Mainland', 'Ikeja', 'Eti-Osa', 'Badagry', 
                'Apapa', 'Lagos Island', 'Epe', 'Ibeju-Lekki'],
      'Abuja': ['Abaji', 'Bwari', 'Gwagwalada', 'Kuje', 'Kwali', 'Municipal Area Council'],
      'Rivers': ['Port Harcourt', 'Obio-Akpor', 'Okrika', 'Ogu–Bolo', 'Eleme', 
                 'Tai', 'Gokana', 'Khana', 'Oyigbo', 'Opobo–Nkoro', 'Andoni', 
                 'Bonny', 'Degema', 'Asari-Toru', 'Akuku-Toru', 'Abua–Odual', 
                 'Ahoada West', 'Ahoada East', 'Ogba–Egbema–Ndoni', 'Emohua', 
                 'Ikwerre', 'Etche', 'Omuma'],
      // Add more states as needed
    };
    
    // Return LGAs for the state if available, otherwise return an empty list
    return lgasByState[state] ?? [];
  }
}