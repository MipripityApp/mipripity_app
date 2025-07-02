import '../services/user_service.dart';

// Utility function to update user data in the backend
Future<bool> updateUserData(String email, Map<String, dynamic> updateData, {int? userId}) async {
  try {
    final userService = UserService();
    
    // If no userId is provided, first try to get it from SharedPreferences
    if (userId == null) {
      userId = await userService.getCurrentUserId();
      
      // If still null, fall back to getting user by email
      if (userId == null) {
        final userData = await userService.getUserByEmail(email);
        if (userData == null) {
          print('User not found with email: $email');
          return false;
        }
        userId = userData['id'] as int;
      }
    }
    
    // Now we have a userId one way or another
    
    // Get user data to use as fallback if needed
    Map<String, dynamic>? userData;
    try {
      userData = await userService.getUserById(userId);
    } catch (e) {
      print('Unable to get user data by ID: $e');
      // Continue without userData - we'll use only updateData
    }
    
    // Update user profile with the provided data (basic info)
    final result = await userService.updateUserProfile(
      userId: userId,
      firstName: updateData['firstName'] ?? userData?['first_name'],
      lastName: updateData['lastName'] ?? userData?['last_name'],
      phoneNumber: updateData['phoneNumber'] ?? userData?['phone_number'],
      whatsappLink: updateData['whatsappLink'] ?? userData?['whatsapp_link'],
      avatarUrl: updateData['avatarUrl'] ?? updateData['profile_picture_url'] ?? userData?['avatar_url'],
    );
    
    // Store extended personal information in user settings
    // (since the main users table doesn't have columns for these fields)
    if (updateData.containsKey('gender') || 
        updateData.containsKey('date_of_birth') || 
        updateData.containsKey('address') || 
        updateData.containsKey('state') || 
        updateData.containsKey('city') ||
        updateData.containsKey('country') ||
        updateData.containsKey('postal_code')) {
      
      // Create settings map with personal info stored as preferences
      final Map<String, dynamic> settingsData = {
        // Standard settings with defaults
        'theme_preference': 'System',
        'language_preference': 'English',
        'currency_preference': 'NGN',
        'distance_unit': 'Kilometers',
        'date_format': 'DD/MM/YYYY',
        
        // Store personal information as user preferences
        'user_gender': updateData['gender'],
        'user_birth_date': updateData['date_of_birth'],
        'user_address': updateData['address'],
        'user_state': updateData['state'],
        'user_city': updateData['city'],
        'user_country': updateData['country'],
        'user_postal_code': updateData['postal_code'],
        
        // Default notification settings
        'push_notifications': true,
        'email_notifications': true,
        'sms_notifications': false,
        'in_app_notifications': true,
      };
      
      // Update user settings
      final settingsResult = await userService.updateUserSettings(userId, settingsData);
      
      if (settingsResult == null) {
        print('Warning: Failed to update user settings for user ID: $userId');
        // Continue anyway as the main profile was updated
      }
    }
    
    if (result != null) {
      print('User data updated successfully for user ID: $userId');
      return true;
    } else {
      print('Failed to update user data for user ID: $userId');
      return false;
    }
  } catch (e) {
    print('Error updating user data: $e');
    return false;
  }
}

// Update user settings
Future<bool> updateUserSettings(String email, Map<String, dynamic> settingsData) async {
  try {
    final userService = UserService();
    
    // Get user by email first to get the user ID
    final userData = await userService.getUserByEmail(email);
    if (userData == null) {
      print('User not found with email: $email');
      return false;
    }
    
    final userId = userData['id'] as int;
    
    // Update user settings
    final result = await userService.updateUserSettings(userId, settingsData);
    
    if (result != null) {
      print('User settings updated successfully for user ID: $userId');
      return true;
    } else {
      print('Failed to update user settings for user ID: $userId');
      return false;
    }
  } catch (e) {
    print('Error updating user settings: $e');
    return false;
  }
}