import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_extended.dart';
import '../services/user_service.dart';
import '../api/agency_api.dart';

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
  final UserService _userService = UserService();
  
  // Getters
  UserExtended? get user => _user;
  OnboardingStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize with user data from registration
  void initWithUser(Map<String, dynamic> userData) {
    _user = UserExtended.fromBasicUser(userData);
    // Save user ID for future API calls
    if (_user?.id != null) {
      _userService.saveCurrentUserId(_user!.id);
    }
    notifyListeners();
  }
  
  // Initialize with existing user ID
  Future<void> initWithUserId(int userId) async {
    try {
      await _userService.saveCurrentUserId(userId);
      final userData = await _userService.getUserById(userId);
      if (userData != null) {
        _user = UserExtended.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing with user ID: $e');
    }
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

  // Get authorization headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    
    try {
      final token = await _userService.getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    
    return headers;
  }
  
  // STEP 1: Update user interests (local state only)
  Future<bool> updateUserInterests(List<String> interests) async {
    if (_user == null) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Update local state only as backend API doesn't support interests field yet
      _user = _user!.copyWith(interests: interests);
      
      // Store in local storage for persistence across app restarts
      await _saveOnboardingState();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error updating interests: $e';
      notifyListeners();
      return false;
    }
  }
  
  // STEP 2: Update personal information (local only)
  void updatePersonalInfoLocally({
    required String gender,
    required DateTime dateOfBirth,
    required String address,
    required String state,
    required String lga,
  }) {
    if (_user == null) return;
    
    // Update local state only
    _user = _user!.copyWith(
      gender: gender,
      dateOfBirth: dateOfBirth,
      address: address,
      state: state,
      lga: lga,
    );
    
    // Save to local storage
    _saveOnboardingState();
    notifyListeners();
  }
  
  // STEP 3: Update agency details with CAC verification data
  void updateAgencyDetailsLocally({
    required String agencyName,
    bool? agencyVerified,
    String? rcNumber,
    String? officialAgencyName,
  }) {
    if (_user == null) return;
    
    // Update local state with verification data
    _user = _user!.copyWith(
      agencyName: agencyName,
      agencyVerified: agencyVerified ?? _user!.agencyVerified,
      rcNumber: rcNumber ?? _user!.rcNumber,
      officialAgencyName: officialAgencyName ?? _user!.officialAgencyName,
    );
    
    // Save to local storage
    _saveOnboardingState();
    notifyListeners();
  }
  
  // Verify agency with CAC database
  Future<Map<String, dynamic>> verifyAgency(String agencyName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final AgencyApi agencyApi = AgencyApi();
      final result = await agencyApi.verifyAgency(agencyName);
      
      _isLoading = false;
      
      if (result['success']) {
        final body = result['body'];
        final status = body['status'];
        
        if (status == 'verified') {
          // Update user with verification data
          updateAgencyDetailsLocally(
            agencyName: agencyName,
            agencyVerified: true,
            rcNumber: body['rc_number'],
            officialAgencyName: body['official_name'],
          );
          
          notifyListeners();
          return {
            'success': true,
            'verified': true,
            'message': 'Agency verified successfully',
            'rc_number': body['rc_number'],
            'official_name': body['official_name'],
          };
        } else {
          // Update as not verified
          updateAgencyDetailsLocally(
            agencyName: agencyName,
            agencyVerified: false,
          );
          
          notifyListeners();
          return {
            'success': true,
            'verified': false,
            'message': 'Agency not found in CAC database',
          };
        }
      } else {
        _error = 'Verification failed: ${result['body']['error']}';
        notifyListeners();
        return {
          'success': false,
          'verified': false,
          'message': _error,
        };
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error during verification: $e';
      notifyListeners();
      return {
        'success': false,
        'verified': false,
        'message': _error,
      };
    }
  }
  
  // STEP 4: Update profile photo (local only)
  void updateProfilePhotoLocally(File imageFile) {
    if (_user == null) return;
    
    // Store the image path locally - this will be used in the review screen
    // For now, we'll use a placeholder URL
    final imageUrl = 'https://via.placeholder.com/150x150.png?text=${_user!.firstName}';
    
    // Update local state only
    _user = _user!.copyWith(avatarUrl: imageUrl);
    
    // Store the actual image file path for later upload
    _saveImagePathToPreferences(imageFile.path);
    
    // Save to local storage
    _saveOnboardingState();
    notifyListeners();
  }
  
  // Store image file path for later upload
  Future<void> _saveImagePathToPreferences(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_profile_image', imagePath);
    } catch (e) {
      print('Error saving image path: $e');
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
      
      // Get current user ID
      final userId = await _userService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      
      // Update last login to mark completion
      final response = await http.put(
        Uri.parse('$_baseUrl/users/id/$userId/last-login'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'last_login': DateTime.now().toIso8601String(),
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
        // Even if API call fails, consider onboarding completed locally
        _currentStep = OnboardingStep.completed;
        await _saveOnboardingState();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error completing onboarding: $e';
      
      // Even if API call fails, consider onboarding completed locally
      _currentStep = OnboardingStep.completed;
      await _saveOnboardingState();
      notifyListeners();
      return true;
    }
  }
  
  // Get Nigerian states list
  List<String> getNigerianStates() {
    return [
      'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 
      'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'FCT', 
      'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 
      'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 
      'Plateau', 'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara'
    ];
  }
  
  // Get Local Government Areas for a state
  List<String> getLGAsForState(String state) {
    final Map<String, List<String>> lgasByState = {
      'Lagos': ['Alimosho', 'Ajeromi-Ifelodun', 'Kosofe', 'Mushin', 'Oshodi-Isolo', 
                'Ojo', 'Ikorodu', 'Surulere', 'Agege', 'Ifako-Ijaiye', 'Shomolu', 
                'Amuwo-Odofin', 'Lagos Mainland', 'Ikeja', 'Eti-Osa', 'Badagry', 
                'Apapa', 'Lagos Island', 'Epe', 'Ibeju-Lekki'],
      'FCT': ['Abaji', 'Bwari', 'Gwagwalada', 'Kuje', 'Kwali', 'Municipal Area Council'],
      'Rivers': ['Port Harcourt', 'Obio-Akpor', 'Okrika', 'Ogu–Bolo', 'Eleme', 
                 'Tai', 'Gokana', 'Khana', 'Oyigbo', 'Opobo–Nkoro', 'Andoni', 
                 'Bonny', 'Degema', 'Asari-Toru', 'Akuku-Toru', 'Abua–Odual', 
                 'Ahoada West', 'Ahoada East', 'Ogba–Egbema–Ndoni', 'Emohua', 
                 'Ikwerre', 'Etche', 'Omuma'],
      'Kano': ['Ajingi', 'Albasu', 'Bagwai', 'Bebeji', 'Bichi', 'Bunkure', 'Dala', 
               'Dambatta', 'Dawakin Kudu', 'Dawakin Tofa', 'Doguwa', 'Fagge', 
               'Gabasawa', 'Garko', 'Garun Mallam', 'Gaya', 'Gezawa', 'Gwale', 
               'Gwarzo', 'Kabo', 'Kano Municipal', 'Karaye', 'Kibiya', 'Kiru', 
               'Kumbotso', 'Kunchi', 'Kura', 'Madobi', 'Makoda', 'Minjibir', 
               'Nasarawa', 'Rano', 'Rimin Gado', 'Rogo', 'Shanono', 'Sumaila', 
               'Takai', 'Tarauni', 'Tofa', 'Tsanyawa', 'Tudun Wada', 'Ungogo', 
               'Warawa', 'Wudil'],
      // Add more states as needed
    };
    
    return lgasByState[state] ?? ['Select State First'];
  }

  void setCurrentStep(OnboardingStep step) {
    _currentStep = step;
    _saveOnboardingState();
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
