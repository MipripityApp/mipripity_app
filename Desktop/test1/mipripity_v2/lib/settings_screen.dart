import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/bottom_navigation.dart';
import 'services/user_service.dart';
import 'models/user.dart';
import 'providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Service instance
  final UserService _userService = UserService();
  
  // Settings state - matches database fields
  Map<String, dynamic> _userSettings = {
    // Notification preferences
    'push_notifications': true,
    'email_notifications': true, 
    'sms_notifications': false,
    'in_app_notifications': true,
    'notification_sound': true,
    'notification_vibration': true,
    
    // App preferences
    'theme_preference': 'System',
    'language_preference': 'English',
    'currency_preference': 'NGN (₦)',
    'distance_unit': 'Kilometers',
    'date_format': 'DD/MM/YYYY',
    
    // Security settings
    'two_factor_auth': false,
    'biometric_auth': false,
    'location_tracking': true,
    'auto_logout_minutes': 30,
    
    // Privacy settings
    'profile_visibility': 'public',
    'show_email': false,
    'show_phone': true,
  };
  
  // UI State variables - initialized from _userSettings
  // Notification preferences
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _inAppNotifications = true;
  bool _notificationSound = true;
  bool _notificationVibration = true;
  
  // App preferences
  String _selectedTheme = 'System';
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'NGN (₦)';
  String _selectedDistanceUnit = 'Kilometers';
  String _selectedDateFormat = 'DD/MM/YYYY';
  
  // Security settings
  bool _twoFactorAuth = false;
  bool _biometricAuth = false;
  bool _locationTracking = true;
  int _autoLogoutMinutes = 30;
  
  // Privacy settings
  String _profileVisibility = 'public';
  bool _showEmail = false;
  bool _showPhone = true;
  
  String _activeTab = 'home';
  
  // User data
  Map<String, dynamic> _userData = {
    'id': 0,
    'fullName': '',
    'email': '',
    'phone': '',
    'avatarUrl': 'assets/images/chatbot.png',
    'joinDate': '',
    'lastLogin': '',
  };
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserSettings();
  }
  
Future<void> _loadUserData() async {
    print("Starting to load user data...");
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Step 1: Try to get user from UserProvider first
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.getCurrentUser();
      
      if (currentUser != null) {
        setState(() {
          _userData = {
            'id': currentUser.id,
            'fullName': currentUser.fullName,
            'email': currentUser.email,
            'phone': currentUser.phoneNumber,
            'avatarUrl': currentUser.avatarUrl ?? 'assets/images/chatbot.png',
            'joinDate': 'Member', // We might not have created_at from provider
            'lastLogin': 'Recently',
          };
          _isLoading = false;
        });
        print("User data loaded from provider");
        return;
      }
      
      // Step 2: Try to get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      
      if (userDataJson != null) {
        final userMap = jsonDecode(userDataJson);
        setState(() {
          _userData = {
            'id': userMap['id'] ?? 0,
            'fullName': '${userMap['first_name'] ?? userMap['firstName'] ?? ''} ${userMap['last_name'] ?? userMap['lastName'] ?? ''}',
            'email': userMap['email'] ?? '',
            'phone': userMap['phone_number'] ?? userMap['phoneNumber'] ?? '',
            'avatarUrl': userMap['avatar_url'] ?? userMap['avatarUrl'] ?? 'assets/images/chatbot.png',
            'joinDate': 'Member', // We might not have this info from SharedPreferences
            'lastLogin': 'Recently',
          };
          _isLoading = false;
        });
        print("User data loaded from SharedPreferences");
        return;
      }
      
      // Step 3: If we still don't have user data, try API calls
      // First, try to get the current user profile data which should include email
      final profile = await _userService.getCurrentUserProfile();
      
      // If no profile data or no email, we need to handle that
      if (profile == null || profile['email'] == null) {
        // Get user ID and try a different approach
        final userId = await _userService.getCurrentUserId();
        if (userId == null) {
          throw Exception("No user information found. Please log in again.");
        }
        
        // Try fetching by ID as a fallback
        final userData = await _userService.getUserById(userId);
        if (userData == null) {
          throw Exception("Could not load user profile. Please try again.");
        }
        
        print("Received user data via ID: $userData");
        _updateUserDataState(userData);
      } else {
        // We have the email, use it to get full user data
        final email = profile['email'];
        final userData = await _userService.getUserByEmail(email);
        
        if (userData == null) {
          throw Exception("Could not load user profile by email. Please try again.");
        }
        
        print("Received user data via email: $userData");
        _updateUserDataState(userData);
      }
      
      print("User data loaded successfully from API");
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load user data: $e';
      });
      
      // Show error message to user without falling back to guest data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load user data. Please check your connection and try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _loadUserData(); // Retry loading user data
              },
            ),
          ),
        );
      }
    }
  }
  
  // Helper method to update user data state
  void _updateUserDataState(Map<String, dynamic> userData) {
    setState(() {
      _userData = {
        'id': userData['id'] ?? 0,
        'fullName': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
        'email': userData['email'] ?? '',
        'phone': userData['phoneNumber'] ?? '',
        'avatarUrl': userData['avatarUrl'] ?? 'assets/images/chatbot.png',
        // Format join date - using created_at if available
        'joinDate': userData['created_at'] != null 
            ? _formatDate(userData['created_at']) 
            : 'New Member',
        'lastLogin': 'Recently',
      };
      _isLoading = false;
    });
  }
  
  Future<void> _loadUserSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final userId = await _userService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Fetch settings from the API
      final settings = await _userService.getUserSettings(userId);
      
      if (settings != null) {
        setState(() {
          // Map each setting from the database to our local state
          // Use nullish coalescing to provide default values if a setting is missing
          
          // Notification preferences
          _userSettings['push_notifications'] = settings['push_notifications'] ?? true;
          _userSettings['email_notifications'] = settings['email_notifications'] ?? true;
          _userSettings['sms_notifications'] = settings['sms_notifications'] ?? false;
          _userSettings['in_app_notifications'] = settings['in_app_notifications'] ?? true;
          _userSettings['notification_sound'] = settings['notification_sound'] ?? true;
          _userSettings['notification_vibration'] = settings['notification_vibration'] ?? true;
          
          // App preferences
          _userSettings['theme_preference'] = settings['theme_preference'] ?? 'System';
          _userSettings['language_preference'] = settings['language_preference'] ?? 'English';
          _userSettings['currency_preference'] = settings['currency_preference'] ?? 'NGN (₦)';
          _userSettings['distance_unit'] = settings['distance_unit'] ?? 'Kilometers';
          _userSettings['date_format'] = settings['date_format'] ?? 'DD/MM/YYYY';
          
          // Security settings
          _userSettings['two_factor_auth'] = settings['two_factor_auth'] ?? false;
          _userSettings['biometric_auth'] = settings['biometric_auth'] ?? false;
          _userSettings['location_tracking'] = settings['location_tracking'] ?? true;
          _userSettings['auto_logout_minutes'] = settings['auto_logout_minutes'] ?? 30;
          
          // Privacy settings
          _userSettings['profile_visibility'] = settings['profile_visibility'] ?? 'public';
          _userSettings['show_email'] = settings['show_email'] ?? false;
          _userSettings['show_phone'] = settings['show_phone'] ?? true;
          
          // Initialize UI state variables from settings
          _pushNotifications = _userSettings['push_notifications'];
          _emailNotifications = _userSettings['email_notifications'];
          _smsNotifications = _userSettings['sms_notifications'];
          _inAppNotifications = _userSettings['in_app_notifications'];
          _notificationSound = _userSettings['notification_sound'];
          _notificationVibration = _userSettings['notification_vibration'];
          
          _selectedTheme = _userSettings['theme_preference'];
          _selectedLanguage = _userSettings['language_preference'];
          _selectedCurrency = _userSettings['currency_preference'];
          _selectedDistanceUnit = _userSettings['distance_unit'];
          _selectedDateFormat = _userSettings['date_format'];
          
          _twoFactorAuth = _userSettings['two_factor_auth'];
          _biometricAuth = _userSettings['biometric_auth'];
          _locationTracking = _userSettings['location_tracking'];
          _autoLogoutMinutes = _userSettings['auto_logout_minutes'];
          
          _profileVisibility = _userSettings['profile_visibility'];
          _showEmail = _userSettings['show_email'];
          _showPhone = _userSettings['show_phone'];
          
          _isLoading = false;
        });
        
        print('User settings loaded successfully');
      } else {
        throw Exception('Failed to load settings');
      }
    } catch (e) {
      print('Error loading user settings: $e');
      setState(() {
        _isLoading = false;
        // Keep default values if we failed to load from API
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Format date string
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  // Get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  // Save user settings based on category
  Future<void> _saveUserSettings(String category) async {
    try {
      // First, update the internal settings map from UI state variables
      // This ensures we save the latest values from the UI
      
      // Update notification settings
      if (category == 'notifications') {
        _userSettings['push_notifications'] = _pushNotifications;
        _userSettings['email_notifications'] = _emailNotifications;
        _userSettings['sms_notifications'] = _smsNotifications;
        _userSettings['in_app_notifications'] = _inAppNotifications;
        _userSettings['notification_sound'] = _notificationSound;
        _userSettings['notification_vibration'] = _notificationVibration;
        
        // Call the specialized method for notifications
        await _saveNotificationPreferences();
      }
      // Update app preferences
      else if (category == 'app') {
        _userSettings['theme_preference'] = _selectedTheme;
        _userSettings['language_preference'] = _selectedLanguage;
        _userSettings['currency_preference'] = _selectedCurrency;
        _userSettings['distance_unit'] = _selectedDistanceUnit;
        _userSettings['date_format'] = _selectedDateFormat;
        
        // Call the specialized method for app preferences
        await _saveAppPreferences();
      }
      // Update security settings
      else if (category == 'security') {
        _userSettings['two_factor_auth'] = _twoFactorAuth;
        _userSettings['biometric_auth'] = _biometricAuth;
        _userSettings['location_tracking'] = _locationTracking;
        _userSettings['auto_logout_minutes'] = _autoLogoutMinutes;
        
        // Call the specialized method for security settings
        await _saveSecuritySettings();
      }
    } catch (e) {
      print('Error saving user settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Save notification preferences to database
  Future<void> _saveNotificationPreferences() async {
    try {
      final userId = await _userService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Create notification settings object to send to API
      final notificationSettings = {
        'push_notifications': _userSettings['push_notifications'],
        'email_notifications': _userSettings['email_notifications'],
        'sms_notifications': _userSettings['sms_notifications'],
        'in_app_notifications': _userSettings['in_app_notifications'],
        'notification_sound': _userSettings['notification_sound'],
        'notification_vibration': _userSettings['notification_vibration'],
      };
      
      // Send to API
      final result = await _userService.updateNotificationPreferences(
        userId, 
        notificationSettings
      );
      
      if (result != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved successfully'),
            backgroundColor: Color(0xFF000080),
          ),
        );
      } else {
        throw Exception('Failed to update notification preferences');
      }
    } catch (e) {
      print('Error saving notification preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save notification preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Save app preferences to database
  Future<void> _saveAppPreferences() async {
    try {
      final userId = await _userService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Create app preferences object to send to API
      final appPreferences = {
        'theme_preference': _userSettings['theme_preference'],
        'language_preference': _userSettings['language_preference'],
        'currency_preference': _userSettings['currency_preference'],
        'distance_unit': _userSettings['distance_unit'],
        'date_format': _userSettings['date_format'],
      };
      
      // Send to API
      final result = await _userService.updateUserSettings(
        userId, 
        appPreferences
      );
      
      if (result != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App preferences saved successfully'),
            backgroundColor: Color(0xFF000080),
          ),
        );
      } else {
        throw Exception('Failed to update app preferences');
      }
    } catch (e) {
      print('Error saving app preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save app preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Save security settings to database
  Future<void> _saveSecuritySettings() async {
    try {
      final userId = await _userService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Create security settings object to send to API
      final securitySettings = {
        'two_factor_auth': _userSettings['two_factor_auth'],
        'biometric_auth': _userSettings['biometric_auth'],
        'location_tracking': _userSettings['location_tracking'],
        'auto_logout_minutes': _userSettings['auto_logout_minutes'],
      };
      
      // Send to API
      final result = await _userService.updateSecuritySettings(
        userId, 
        securitySettings
      );
      
      if (result != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings saved successfully'),
            backgroundColor: Color(0xFF000080),
          ),
        );
      } else {
        throw Exception('Failed to update security settings');
      }
    } catch (e) {
      print('Error saving security settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save security settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update user profile
  Future<void> _updateUserProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final userId = await _userService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      final result = await _userService.updateUserProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      
      if (result != null) {
        // Update local user data
        setState(() {
          _userData['fullName'] = '$firstName $lastName';
          _userData['phone'] = phoneNumber;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF000080),
          ),
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    print("Building SettingsScreen with loading state: $_isLoading, error state: $_hasError");
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF000080)),
            onPressed: () {
              _showHelpDialog(context);
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFF39322),
                ),
                SizedBox(height: 16),
                Text("Loading settings...", style: TextStyle(color: Color(0xFF000080))),
              ],
            ),
          )
        : _hasError
          ? _buildLoadingOrError()
          : Stack(
              children: [
                // Main content
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80), // Space for bottom nav
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildProfileSection(),
                
                const SizedBox(height: 16),
                
                // Account Settings
                _buildSettingsSection(
                  'Account Settings',
                  [
                    _buildSettingItem(
                      'Change Password',
                      Icons.lock_outline,
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    _buildSettingItem(
                      'Update Email Address',
                      Icons.email_outlined,
                      onTap: () => _showUpdateEmailDialog(context),
                    ),
                    _buildSettingItem(
                      'Manage Linked Accounts',
                      Icons.link,
                      onTap: () {},
                    ),
                    _buildSwitchItem(
                      'Two-Factor Authentication',
                      Icons.security_outlined,
                      _twoFactorAuth,
                      (value) {
                        setState(() {
                          _twoFactorAuth = value;
                        });
                        if (value) {
                          _showSetupTwoFactorDialog(context);
                        }
                      },
                    ),
                    _buildSettingItem(
                      'Delete Account',
                      Icons.delete_outline,
                      textColor: Colors.red,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Notification Preferences
                _buildSettingsSection(
                  'Notification Preferences',
                  [
                    _buildSwitchItem(
                      'Push Notifications',
                      Icons.notifications_outlined,
                      _pushNotifications,
                      (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'Email Notifications',
                      Icons.email_outlined,
                      _emailNotifications,
                      (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'SMS Notifications',
                      Icons.sms_outlined,
                      _smsNotifications,
                      (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                    ),
                        _buildSwitchItem(
                          'In-App Notifications',
                          Icons.app_registration,
                          _inAppNotifications,
                          (value) {
                            setState(() {
                              _inAppNotifications = value;
                            });
                          },
                        ),
                        _buildSettingItem(
                          'Custom Notification Settings',
                          Icons.tune,
                          onTap: () {},
                        ),
                        // Add Save Button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _saveUserSettings('notifications'),
                              icon: const Icon(Icons.save),
                              label: const Text('Save Notification Preferences'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF39322),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                
                const SizedBox(height: 16),
                
                // App Preferences
                _buildSettingsSection(
                  'App Preferences',
                  [
                    _buildDropdownItem(
                      'Theme',
                      Icons.brightness_6_outlined,
                      _selectedTheme,
                      ['System', 'Light', 'Dark'],
                      (value) {
                        setState(() {
                          _selectedTheme = value;
                        });
                      },
                    ),
                    _buildDropdownItem(
                      'Language',
                      Icons.language,
                      _selectedLanguage,
                      ['English', 'French', 'Yoruba', 'Hausa', 'Igbo'],
                      (value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                    ),
                    _buildDropdownItem(
                      'Currency',
                      Icons.currency_exchange,
                      _selectedCurrency,
                      ['NGN (₦)', 'USD (\$)', 'EUR (€)', 'GBP (£)'],
                      (value) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      },
                    ),
                    _buildDropdownItem(
                      'Distance Unit',
                      Icons.straighten,
                      _selectedDistanceUnit,
                      ['Kilometers', 'Miles'],
                      (value) {
                        setState(() {
                          _selectedDistanceUnit = value;
                        });
                      },
                    ),
                        _buildDropdownItem(
                          'Date Format',
                          Icons.calendar_today,
                          _selectedDateFormat,
                          ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                          (value) {
                            setState(() {
                              _selectedDateFormat = value;
                            });
                          },
                        ),
                        // Add Save Button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _saveUserSettings('app'),
                              icon: const Icon(Icons.save),
                              label: const Text('Save App Preferences'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF39322),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                
                const SizedBox(height: 16),
                
                // Privacy and Security
                _buildSettingsSection(
                  'Privacy and Security',
                  [
                    _buildSettingItem(
                      'Privacy Policy',
                      Icons.privacy_tip_outlined,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'Terms of Service',
                      Icons.description_outlined,
                      onTap: () {},
                    ),
                    _buildSwitchItem(
                      'Location Tracking',
                      Icons.location_on_outlined,
                      _locationTracking,
                      (value) {
                        setState(() {
                          _locationTracking = value;
                        });
                      },
                    ),
                    _buildSwitchItem(
                      'Biometric Authentication',
                      Icons.fingerprint,
                      _biometricAuth,
                      (value) {
                        setState(() {
                          _biometricAuth = value;
                        });
                        if (value) {
                          _showBiometricSetupDialog(context);
                        }
                      },
                    ),
                    _buildSettingItem(
                      'Data Sharing Preferences',
                      Icons.share_outlined,
                      onTap: () {},
                    ),
                    // Add Save Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveUserSettings('security'),
                          icon: const Icon(Icons.save),
                          label: const Text('Save Security Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF39322),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Help and Support
                _buildSettingsSection(
                  'Help and Support',
                  [
                    _buildSettingItem(
                      'Contact Support',
                      Icons.support_agent,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'FAQs',
                      Icons.question_answer_outlined,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'Report a Problem',
                      Icons.bug_report_outlined,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'Submit Feedback',
                      Icons.feedback_outlined,
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      'Rate the App',
                      Icons.star_outline,
                      onTap: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // App Information
                _buildSettingsSection(
                  'App Information',
                  [
                    _buildInfoItem('App Version', '1.0.3'),
                    _buildInfoItem('Build Number', '103'),
                    _buildInfoItem('Last Updated', '15 May 2023'),
                    _buildInfoItem('Developer', 'Mipripity Technologies'),
                    _buildSettingItem(
                      'License Information',
                      Icons.info_outline,
                      onTap: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40), // Extra space at bottom
              ],
            ),
          ),
          
                  // Bottom Navigation Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SharedBottomNavigation(
                      activeTab: "settings", // Changed from "explore" to "settings" since this is the settings screen
                      onTabChange: (tab) {
                        SharedBottomNavigation.handleNavigation(context, tab);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  // Show loading indicator or error message
  Widget _buildLoadingOrError() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF39322),
        ),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39322),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Log out and navigate to login screen
                _userService.logoutUser().then((_) {
                  Navigator.pushReplacementNamed(context, '/login');
                });
              },
              child: const Text(
                'Logout and Login Again',
                style: TextStyle(color: Color(0xFF000080)),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Profile Section Widget
  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF39322),
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: AssetImage(_userData['avatarUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39322),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // Handle profile picture change
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['fullName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData['phone'],
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member since',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userData['joinDate'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF000080),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to edit profile
                  _showEditProfileDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFF39322),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Settings Section Widget
  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  // Setting Item Widget
  Widget _buildSettingItem(
    String title,
    IconData icon, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: textColor ?? const Color(0xFF000080),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Switch Item Widget
  Widget _buildSwitchItem(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF000080),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFF39322),
            activeTrackColor: const Color(0xFFF39322).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // Dropdown Item Widget
  Widget _buildDropdownItem(
    String title,
    IconData icon,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () {
        _showDropdownDialog(context, title, value, options, onChanged);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF000080),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Info Item Widget
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Handle tab change
  void _handleTabChange(String tab) {
    setState(() {
      _activeTab = tab;
    });

    // Handle navigation based on tab
    switch (tab) {
      case 'home':
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 'invest':
        Navigator.pushNamed(context, '/invest');
        break;
      case 'add':
        Navigator.pushNamed(context, '/add');
        break;
      case 'bid':
        Navigator.pushNamed(context, '/my-bids');
        break;
      case 'explore':
        Navigator.pushNamed(context, '/explore');
        break;
    }
  }

  // Show Edit Profile Dialog
  void _showEditProfileDialog(BuildContext context) {
    // Split full name into first and last name
    final fullNameParts = _userData['fullName'].split(' ');
    final firstName = fullNameParts.isNotEmpty ? fullNameParts[0] : '';
    final lastName = fullNameParts.length > 1 
      ? fullNameParts.sublist(1).join(' ') 
      : '';
    
    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final emailController = TextEditingController(text: _userData['email']);
    final phoneController = TextEditingController(text: _userData['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email cannot be changed here
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Update user profile in the database
              _updateUserProfile(
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                phoneNumber: phoneController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39322),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show Change Password Dialog
  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Change Password',
            style: TextStyle(
              color: Color(0xFF000080),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate passwords
                if (newPasswordController.text.isEmpty ||
                    currentPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Close dialog
                // Implement actual password change logic
                _changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF39322),
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  // Change password function
  Future<void> _changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // In a real implementation, you would call your API to change the password
      // For now, we're just showing a success message
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Color(0xFF000080),
        ),
      );
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show Update Email Dialog
  void _showUpdateEmailDialog(BuildContext context) {
    final emailController = TextEditingController(text: _userData['email']);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Update Email Address',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'New Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement actual email update logic
              _updateEmail(
                newEmail: emailController.text,
                password: passwordController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39322),
            ),
            child: const Text('Update Email'),
          ),
        ],
      ),
    );
  }

  // Show Delete Account Dialog
  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Warning: This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter Password to Confirm',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Delete account logic would go here
              Navigator.pop(context);
              
              // Navigate to login screen
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Show Setup Two Factor Dialog
  void _showSetupTwoFactorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Setup Two-Factor Authentication',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Two-factor authentication adds an extra layer of security to your account. We will send a verification code to your phone number when you log in.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Verification Method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_android),
                        const SizedBox(width: 8),
                        Text(_userData['phone']),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _twoFactorAuth = false;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Setup 2FA logic would go here
              Navigator.pop(context);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled'),
                  backgroundColor: Color(0xFF000080),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39322),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  // Show Biometric Setup Dialog
  void _showBiometricSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Setup Biometric Authentication',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint,
                size: 64,
                color: Color(0xFFF39322),
              ),
              SizedBox(height: 16),
              Text(
                'Biometric authentication allows you to log in using your fingerprint or face recognition.',
              ),
              SizedBox(height: 16),
              Text(
                'To set up biometric authentication, you will need to verify your identity first.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _biometricAuth = false;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Setup biometric auth logic would go here
              Navigator.pop(context);
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometric authentication enabled'),
                  backgroundColor: Color(0xFF000080),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39322),
            ),
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  // Show Dropdown Dialog
  void _showDropdownDialog(
    BuildContext context,
    String title,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select $title',
          style: const TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(option),
                trailing: option == currentValue
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFFF39322),
                      )
                    : null,
                onTap: () {
                  onChanged(option);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Show Help Dialog
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Settings Help',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Section',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text('• Tap on the camera icon to change your profile picture'),
              Text('• Tap "Edit Profile" to update your personal information'),
              SizedBox(height: 16),
              Text(
                'Account Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text('• Change your password and email address'),
              Text('• Enable two-factor authentication for added security'),
              SizedBox(height: 16),
              Text(
                'Notification Preferences',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text('• Toggle different notification types on or off'),
              SizedBox(height: 16),
              Text(
                'Need more help?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text('Contact our support team at support@mipripity.com'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF39322),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Update email function
  Future<void> _updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      // In a real implementation, you would call your API to update the email
      // For now, we're just updating the local state
      
      setState(() {
        _userData['email'] = newEmail;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email updated successfully'),
          backgroundColor: Color(0xFF000080),
        ),
      );
    } catch (e) {
      print('Error updating email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show Logout Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement actual logout logic
              _logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
  
  // Logout function
  Future<void> _logout() async {
    try {
      await _userService.logoutUser();
      // Navigate to login screen
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
// BottomNavigation Widget
class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const BottomNavigation({
    Key? key,
    required this.activeTab,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                'home',
                'assets/icons/home.png',
                'Home',
              ),
              _buildNavItem(
                context,
                'invest',
                'assets/icons/invest.png',
                'Invest',
              ),
              _buildAddButton(context),
              _buildNavItem(
                context,
                'bid',
                'assets/icons/chat.png',
                'Bid',
              ),
              _buildNavItem(
                context,
                'explore',
                'assets/icons/explore.png',
                'Explore',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String tab,
    String iconPath,
    String label,
  ) {
    final isActive = activeTab == tab;
    return GestureDetector(
      onTap: () => onTabChange(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            isActive ? 'assets/icons/${tab}_active.png' : 'assets/icons/$tab.png',
            width: 24,
            height: 24,
            color: isActive ? const Color(0xFFF39322) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              color: isActive ? const Color(0xFFF39322) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onTabChange('add'),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF39322), Color(0xFF000080)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
