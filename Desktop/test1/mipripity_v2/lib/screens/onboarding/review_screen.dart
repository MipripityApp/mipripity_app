import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/onboarding_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimation();
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
  
  Future<void> _handleComplete() async {
    setState(() {
      _isSubmitting = true;
    });
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final success = await onboardingProvider.completeOnboarding();
    
    if (!mounted) return;
    
    if (success) {
      // Navigate to login screen
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  void _handleBack() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    onboardingProvider.previousStep();
  }
  
  void _editStep(OnboardingStep step) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    // Navigate directly to the specific step
    onboardingProvider.setCurrentStep(step);
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final user = onboardingProvider.user;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFF39322),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Review Your Profile',
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
                        '5',
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
                      value: 1.0, // Final step
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
                      'Almost there!',
                      style: TextStyle(
                        color: Color(0xFF000080),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please review your information before completing the setup.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Review information sections
              Expanded(
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic information
                        _buildSectionCard(
                          title: 'Basic Information',
                          icon: Icons.person,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Name', '${user.firstName} ${user.lastName}'),
                              _buildInfoRow('Email', user.email),
                              _buildInfoRow('Phone', user.phoneNumber),
                            ],
                          ),
                          onEdit: null, // Can't edit basic info in onboarding
                        ),
                        
                        // Interests
                        _buildSectionCard(
                          title: 'Real Estate Interests',
                          icon: Icons.interests,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.interests != null && user.interests!.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: user.interests!.map((interest) {
                                    return Chip(
                                      label: Text(interest),
                                      backgroundColor: const Color(0xFFFFF4E6),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFFF39322),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                Text(
                                  'No interests selected',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          onEdit: () => _editStep(OnboardingStep.interests),
                        ),
                        
                        // Personal information
                        _buildSectionCard(
                          title: 'Personal Information',
                          icon: Icons.badge,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Gender', user.gender ?? 'Not provided'),
                              _buildInfoRow(
                                'Date of Birth', 
                                user.dateOfBirth != null 
                                    ? DateFormat('MMMM d, yyyy').format(user.dateOfBirth!)
                                    : 'Not provided'
                              ),
                              _buildInfoRow('Address', user.address ?? 'Not provided'),
                              _buildInfoRow('State', user.state ?? 'Not provided'),
                              _buildInfoRow('LGA', user.lga ?? 'Not provided'),
                            ],
                          ),
                          onEdit: () => _editStep(OnboardingStep.personalInfo),
                        ),
                        
                        // Agency details (only if user is an agent)
                        if (user.isRealEstateAgent)
                          _buildSectionCard(
                            title: 'Agency Details',
                            icon: Icons.business,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Agency Name', user.agencyName ?? 'Not provided'),
                                _buildInfoRow(
                                  'Verification Status', 
                                  user.agencyVerified == true
                                      ? 'Verified'
                                      : 'Not verified'
                                ),
                              ],
                            ),
                            onEdit: () => _editStep(OnboardingStep.agencyDetails),
                          ),
                        
                        // Profile photo
                        _buildSectionCard(
                          title: 'Profile Photo',
                          icon: Icons.photo_camera,
                          content: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                image: user.avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(user.avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: user.avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          onEdit: () => _editStep(OnboardingStep.profilePhoto),
                        ),
                      ],
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
              
              // Complete button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || onboardingProvider.isLoading 
                      ? null 
                      : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFF39322),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting || onboardingProvider.isLoading
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
                              'Finish Onboarding',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
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
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39322).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFF39322),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                ),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color(0xFFF39322),
                    ),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Color(0xFFF39322),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}