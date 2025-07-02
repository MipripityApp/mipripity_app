import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/onboarding_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  
  String _selectedGender = 'Male';
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 18)); // Default to 18 years ago
  String _selectedState = '';
  String _selectedLGA = '';
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  List<String> _stateOptions = [];
  List<String> _lgaOptions = [];
  
  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadStateOptions();
    _initializeUserData();
  }
  
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }
  
  void _loadStateOptions() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    _stateOptions = onboardingProvider.getNigerianStates();
    
    // Default to Lagos if no state is selected
    if (_selectedState.isEmpty && _stateOptions.isNotEmpty) {
      _selectedState = 'Lagos';
      _updateLGAOptions();
    }
  }
  
  void _initializeUserData() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = onboardingProvider.user;
    
    if (user != null) {
      if (user.gender != null) {
        _selectedGender = user.gender!;
      }
      
      if (user.dateOfBirth != null) {
        _selectedDate = user.dateOfBirth!;
      }
      
      if (user.address != null) {
        _addressController.text = user.address!;
      }
      
      if (user.state != null) {
        _selectedState = user.state!;
        _updateLGAOptions();
      }
      
      if (user.lga != null) {
        _selectedLGA = user.lga!;
      }
    }
  }
  
  void _updateLGAOptions() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    _lgaOptions = onboardingProvider.getLGAsForState(_selectedState);
    
    // If there are LGAs and none is selected, select the first one
    if (_lgaOptions.isNotEmpty && (_selectedLGA.isEmpty || !_lgaOptions.contains(_selectedLGA))) {
      _selectedLGA = _lgaOptions.first;
    }
    
    setState(() {});
  }
  
  @override
  void dispose() {
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF39322),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF39322),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  bool _validateForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedState.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a state'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      if (_selectedLGA.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a local government area'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      return true;
    }
    return false;
  }
  
  Future<void> _handleContinue() async {
    if (!_validateForm()) return;
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final success = await onboardingProvider.updatePersonalInfo(
      gender: _selectedGender,
      dateOfBirth: _selectedDate,
      address: _addressController.text.trim(),
      state: _selectedState,
      lga: _selectedLGA,
    );
    
    if (success) {
      onboardingProvider.nextStep();
    } else {
      // Error handling is done in provider, which shows error message
    }
  }
  
  void _handleBack() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    onboardingProvider.previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Personal Information',
          style: TextStyle(
            color: Color(0xFF000080),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : 48,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF39322),
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0.4, // Second step out of 5
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF39322)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Title and description
              FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tell us more about yourself',
                      style: TextStyle(
                        color: Color(0xFF000080),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This information helps us provide better property recommendations.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Form
              Expanded(
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gender
                          const Text(
                            'Gender',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                style: const TextStyle(
                                  color: Color(0xFF4A4A4A),
                                  fontSize: 14,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedGender = newValue;
                                    });
                                  }
                                },
                                items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Date of Birth
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM d, yyyy').format(_selectedDate),
                                    style: const TextStyle(
                                      color: Color(0xFF4A4A4A),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Address
                          const Text(
                            'Address',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Enter your home address',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF39322),
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // State and LGA (side by side for larger screens)
                          isSmallScreen
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // State dropdown
                                    const Text(
                                      'State',
                                      style: TextStyle(
                                        color: Color(0xFF4A4A4A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildStateDropdown(),
                                    const SizedBox(height: 20),
                                    
                                    // LGA dropdown
                                    const Text(
                                      'Local Government Area',
                                      style: TextStyle(
                                        color: Color(0xFF4A4A4A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLGADropdown(),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // State dropdown
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'State',
                                            style: TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildStateDropdown(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // LGA dropdown
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Local Government Area',
                                            style: TextStyle(
                                              color: Color(0xFF4A4A4A),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildLGADropdown(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Error message if any
              if (onboardingProvider.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: Colors.red[500]!,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Text(
                    onboardingProvider.error!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onboardingProvider.isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFF39322),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: onboardingProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStateDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState.isNotEmpty && _stateOptions.contains(_selectedState) 
              ? _selectedState 
              : null,
          isExpanded: true,
          hint: const Text('Select State'),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedState = newValue;
                _selectedLGA = ''; // Reset LGA when state changes
              });
              _updateLGAOptions();
            }
          },
          items: _stateOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildLGADropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLGA.isNotEmpty && _lgaOptions.contains(_selectedLGA) 
              ? _selectedLGA 
              : null,
          isExpanded: true,
          hint: const Text('Select LGA'),
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 14,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLGA = newValue;
              });
            }
          },
          items: _lgaOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}