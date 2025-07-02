import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_svg/flutter_svg.dart';
import 'providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreeToTerms = false;
  bool _subscribeToNewsletter = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_validateFields()) return;

    final userProvider = provider.Provider.of<UserProvider>(context, listen: false);

    // Generate WhatsApp link
    final phoneNumber = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappLink = 'https://wa.me/$phoneNumber';

    final success = await userProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      whatsappLink: whatsappLink,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please complete your profile setup.')),
      );
      
      // Create user data to pass to onboarding
      final userData = {
        'id': userProvider.appUser!.id,
        'email': _emailController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'whatsapp_link': whatsappLink,
      };
      
      // Navigate to onboarding flow
      Navigator.pushReplacementNamed(
        context, 
        '/onboarding',
        arguments: userData,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.error ?? 'Registration failed')),
      );
    }
  }

  bool _validateFields() {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  // Google sign-in functionality removed

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: provider.Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return Row(
              children: [
                // Left side - Illustration (hidden on small screens)
                if (!isSmallScreen)
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // Main illustration
                          Center(
                            child: FadeTransition(
                              opacity: _fadeInAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(_animationController),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: SvgPicture.asset(
                                    'assets/images/login_illustration.svg', // Using login illustration as fallback
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Gradient overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 96,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.white, Colors.white.withOpacity(0)],
                                ),
                              ),
                            ),
                          ),
                          // Decorative elements
                          Positioned(
                            top: 80,
                            left: 80,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF39322).withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 160,
                            right: 80,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF000080).withOpacity(0.05),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Right side - Form
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24 : 48,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: Colors.grey[500],
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Form content with animation
                        Expanded(
                          child: SingleChildScrollView(
                            child: FadeTransition(
                              opacity: _fadeInAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(_animationController),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Color(0xFF000080),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Join us to find your dream property',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      // Error message if any
                                      if (userProvider.error != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(16),
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
                                            userProvider.error!,
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                      // Name fields row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'First Name',
                                                  style: TextStyle(
                                                    color: Color(0xFF4A4A4A),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: _firstNameController,
                                                  decoration: InputDecoration(
                                                    hintText: 'John',
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 14,
                                                    ),
                                                    prefixIcon: Icon(
                                                      Icons.person_outline,
                                                      color: Colors.grey[400],
                                                      size: 20,
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
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Last Name',
                                                  style: TextStyle(
                                                    color: Color(0xFF4A4A4A),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextFormField(
                                                  controller: _lastNameController,
                                                  decoration: InputDecoration(
                                                    hintText: 'Doe',
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
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Email field
                                      const Text(
                                        'Email Address',
                                        style: TextStyle(
                                          color: Color(0xFF4A4A4A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          hintText: 'your@email.com',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: Colors.grey[400],
                                            size: 20,
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
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Phone field
                                      const Text(
                                        'Phone Number',
                                        style: TextStyle(
                                          color: Color(0xFF4A4A4A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          hintText: '+234 800 000 0000',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.phone_outlined,
                                            color: Colors.grey[400],
                                            size: 20,
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
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Password field
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          color: Color(0xFF4A4A4A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: !_showPassword,
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _showPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showPassword = !_showPassword;
                                              });
                                            },
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
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Confirm Password field
                                      const Text(
                                        'Confirm Password',
                                        style: TextStyle(
                                          color: Color(0xFF4A4A4A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: !_showConfirmPassword,
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.lock_outline,
                                            color: Colors.grey[400],
                                            size: 20,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _showConfirmPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _showConfirmPassword = !_showConfirmPassword;
                                              });
                                            },
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
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      // Terms and conditions checkbox
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _agreeToTerms,
                                              onChanged: (value) {
                                                setState(() {
                                                  _agreeToTerms = value ?? false;
                                                });
                                              },
                                              activeColor: const Color(0xFFF39322),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                text: 'I agree to the ',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                                children: const [
                                                  TextSpan(
                                                    text: 'Terms and Conditions',
                                                    style: TextStyle(
                                                      color: Color(0xFFF39322),
                                                      fontWeight: FontWeight.w500,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                  TextSpan(text: ' and '),
                                                  TextSpan(
                                                    text: 'Privacy Policy',
                                                    style: TextStyle(
                                                      color: Color(0xFFF39322),
                                                      fontWeight: FontWeight.w500,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Newsletter subscription checkbox
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _subscribeToNewsletter,
                                              onChanged: (value) {
                                                setState(() {
                                                  _subscribeToNewsletter = value ?? false;
                                                });
                                              },
                                              activeColor: const Color(0xFFF39322),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Subscribe to our newsletter for property updates',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Register button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: userProvider.isLoading ? null : _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: const Color(0xFFF39322),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: userProvider.isLoading
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
                                                      'Create Account',
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
                                      const SizedBox(height: 32),
                                      // Sign in link
                                      Center(
                                        child: RichText(
                                          text: TextSpan(
                                            text: 'Already have an account? ',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            children: [
                                              WidgetSpan(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // Navigate to login
                                                    Navigator.pushReplacementNamed(context, '/login');
                                                  },
                                                  child: const Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      color: Color(0xFFF39322),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Google sign-in removed
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}