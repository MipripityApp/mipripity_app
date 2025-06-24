import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

class AgencyDetailsScreen extends StatefulWidget {
  const AgencyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<AgencyDetailsScreen> createState() => _AgencyDetailsScreenState();
}

class _AgencyDetailsScreenState extends State<AgencyDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _agencyNameController = TextEditingController();
  
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _verificationAttempted = false;
  String? _verificationError;
  
  @override
  void initState() {
    super.initState();
    _setupAnimation();
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
  
  void _initializeUserData() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = onboardingProvider.user;
    
    if (user != null && user.agencyName != null) {
      _agencyNameController.text = user.agencyName!;
      _isVerified = user.agencyVerified ?? false;
      _verificationAttempted = true;
    }
  }
  
  @override
  void dispose() {
    _agencyNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  bool _validateForm() {
    if (_formKey.currentState!.validate()) {
      return true;
    }
    return false;
  }
  
  Future<void> _verifyAgency() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final agencyName = _agencyNameController.text.trim();
      
      // This would be an actual API call in production
      // For this demo, we'll simulate verification
      // Verify if the name contains "Agency" or "Realty"
      final bool verified = agencyName.toLowerCase().contains('agency') || 
                           agencyName.toLowerCase().contains('realty') ||
                           agencyName.toLowerCase().contains('properties') ||
                           agencyName.toLowerCase().contains('estate');
      
      setState(() {
        _isVerifying = false;
        _isVerified = verified;
        _verificationAttempted = true;
        _verificationError = verified ? null : 'Agency verification failed. Please check the name and try again.';
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationAttempted = true;
        _verificationError = 'An error occurred during verification: $e';
      });
    }
  }
  
  Future<void> _handleContinue() async {
    if (!_validateForm()) return;
    
    if (!_verificationAttempted) {
      await _verifyAgency();
    }
    
    // Always allow continuing, even if verification failed
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final success = await onboardingProvider.updateAgencyDetails(
      agencyName: _agencyNameController.text.trim(),
    );
    
    if (success) {
      onboardingProvider.nextStep();
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
          'Professional Details',
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
                        '3',
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
                      value: 0.6, // Third step out of 5
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
                      'Agency Information',
                      style: TextStyle(
                        color: Color(0xFF000080),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your real estate agency details for verification.',
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
                          // Agency Name
                          const Text(
                            'Agency Name',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _agencyNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your agency name',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.business,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              suffixIcon: _verificationAttempted
                                  ? _isVerified
                                      ? Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.green,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : Container(
                                          margin: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        )
                                  : null,
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
                                  color: _verificationAttempted
                                      ? _isVerified
                                          ? Colors.green
                                          : Colors.red
                                      : Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _verificationAttempted
                                      ? _isVerified
                                          ? Colors.green
                                          : Colors.red
                                      : const Color(0xFFF39322),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your agency name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Verification button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isVerifying ? null : _verifyAgency,
                              icon: _isVerifying
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.verified_user, size: 16),
                              label: Text(
                                _verificationAttempted
                                    ? 'Verify Again'
                                    : 'Verify Agency Name',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: _verificationAttempted
                                    ? _isVerified
                                        ? Colors.green
                                        : Colors.blue
                                    : Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Verification result message
                          if (_verificationAttempted) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isVerified ? Colors.green[50] : Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: _isVerified ? Colors.green : Colors.red,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isVerified ? Icons.check_circle : Icons.error,
                                        color: _isVerified ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isVerified
                                            ? 'Agency Verified'
                                            : 'Verification Failed',
                                        style: TextStyle(
                                          color: _isVerified ? Colors.green[700] : Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isVerified
                                        ? 'Your agency has been successfully verified. You can now continue to the next step.'
                                        : _verificationError ?? 'Verification failed. Please check the agency name and try again.',
                                    style: TextStyle(
                                      color: _isVerified ? Colors.green[700] : Colors.red[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Verification info
                          if (!_verificationAttempted) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.blue[500]!,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Verification Information',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'We will verify your agency name with the Corporate Affairs Commission (CAC) database. This helps establish trust with potential clients.',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Additional info message
                          if (!_isVerified && _verificationAttempted) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(top: 16),
                              decoration: BoxDecoration(
                                color: Colors.yellow[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.yellow[700]!,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.yellow[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Can\'t verify?',
                                        style: TextStyle(
                                          color: Colors.yellow[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You can still proceed with registration. Verification can be completed later from your profile settings. For now, we\'ll mark your agency as unverified.',
                                    style: TextStyle(
                                      color: Colors.yellow[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                  onPressed: onboardingProvider.isLoading || _isVerifying ? null : _handleContinue,
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
}