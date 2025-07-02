import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

class InterestScreen extends StatefulWidget {
  const InterestScreen({Key? key}) : super(key: key);

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  final List<String> _availableInterests = [
    'Buyer',
    'Seller',
    'Agent',
    'Realtor',
    'Real Estate Agency',
    'Mixed'
  ];
  
  final List<String> _selectedInterests = [];
  
  @override
  void initState() {
    super.initState();
    _setupAnimation();
    
    // Pre-select interests if user already has them from a previous session
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboardingProvider.user?.interests != null) {
      _selectedInterests.addAll(onboardingProvider.user!.interests!);
    }
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
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }
  
  Future<void> _handleContinue() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    try {
      // Update local state with selected interests
      // Note: Interests will be stored in the UserExtended model but not persisted to backend 
      // due to current API limitations. This data will be available for the rest of the onboarding flow.
      final success = await onboardingProvider.updateUserInterests(_selectedInterests);
      
      if (success) {
        onboardingProvider.nextStep();
      } else {
        // Error handling is done in provider, which shows error message
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Tell us about yourself',
          style: TextStyle(
            color: Color(0xFF000080),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                        '1',
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
                      value: 0.2, // First step out of 5
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
                      'What\'s your interest in real estate?',
                      style: TextStyle(
                        color: Color(0xFF000080),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply to you. This helps us personalize your experience.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Interest options
              Expanded(
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _availableInterests.length,
                    itemBuilder: (context, index) {
                      final interest = _availableInterests[index];
                      final isSelected = _selectedInterests.contains(interest);
                      
                      return InkWell(
                        onTap: () => _toggleInterest(interest),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFF39322) : Colors.grey[300]!,
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFFFFF4E6) : Colors.white,
                          ),
                          child: Stack(
                            children: [
                              // Interest label
                              Center(
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFF39322) : Colors.grey[700],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              
                              // Checkmark for selected items
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFF39322),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
}