import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
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
  late AnimationController _backgroundAnimationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      _backgroundAnimationController,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
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
    _backgroundAnimationController.dispose();
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
      // Use the user ID from the appUser object
      if (userProvider.appUser != null) {
        final userId = userProvider.appUser!.id;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please complete your profile setup.')),
        );
        
        // Create user data to pass to onboarding with correct PostgreSQL ID
        final userData = {
          'id': userId, // Use the user ID from userProvider.appUser
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
        // Handle case where ID is not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful but user ID not found. Please try logging in again.')),
        );
        // Navigate to login
        Navigator.pushReplacementNamed(context, '/login');
      }
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
      body: Stack(
        children: [
          // Animated 3D Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E), // Deep indigo
                  Color(0xFF303F9F), // Indigo
                  Color(0xFF3949AB), // Medium indigo
                  Color(0xFF5C6BC0), // Light indigo
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RegisterBackgroundPainter(_rotationAnimation.value),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Glassmorphism overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: provider.Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return Row(
                  children: [
                    // Left side - Enhanced illustration (hidden on small screens)
                    if (!isSmallScreen)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border(
                              right: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Main illustration with enhanced animation
                              Center(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _slideAnimation.value),
                                      child: FadeTransition(
                                        opacity: _fadeInAnimation,
                                        child: Transform.scale(
                                          scale: 0.8 + 0.2 * _fadeInAnimation.value,
                                          child: Container(
                                            width: 300,
                                            height: 300,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  const Color(0xFF3949AB).withOpacity(0.3),
                                                  const Color(0xFF1A237E).withOpacity(0.1),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.app_registration,
                                                size: 100,
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Floating elements - different from login screen
                              ...List.generate(6, (index) {
                                return AnimatedBuilder(
                                  animation: _backgroundAnimationController,
                                  builder: (context, child) {
                                    final offset = _backgroundAnimationController.value * 2 * math.pi;
                                    final angle = offset + index * math.pi / 3;
                                    final radius = 120 + 20 * math.sin(offset * 2 + index);
                                    final x = radius * math.cos(angle);
                                    final y = radius * math.sin(angle);
                                    
                                    return Positioned(
                                      left: x + size.width * 0.2,
                                      top: y + size.height * 0.3,
                                      child: Container(
                                        width: 10 + (index % 4) * 12,
                                        height: 10 + (index % 4) * 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: [
                                            const Color(0xFF3949AB),
                                            const Color(0xFF1A237E),
                                            const Color(0xFF5C6BC0),
                                            Colors.white,
                                          ][index % 4].withOpacity(0.3),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
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
                            // Close button with glassmorphism
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  color: Colors.white.withOpacity(0.8),
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
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _slideAnimation.value),
                                      child: FadeTransition(
                                        opacity: _fadeInAnimation,
                                        child: Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Header with gradient text
                                              ShaderMask(
                                                shaderCallback: (bounds) => const LinearGradient(
                                                  colors: [
                                                    Color(0xFFF39322),
                                                    Color(0xFFFFD700),
                                                  ],
                                                ).createShader(bounds),
                                                child: const Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Join us to find your dream property',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              // Error message if any
                                              if (userProvider.error != null) ...[
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.red.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    userProvider.error!,
                                                    style: TextStyle(
                                                      color: Colors.red[300],
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
                                                        Text(
                                                          'First Name',
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.9),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        TextFormField(
                                                          controller: _firstNameController,
                                                          style: const TextStyle(color: Colors.white),
                                                          decoration: InputDecoration(
                                                            hintText: 'John',
                                                            hintStyle: TextStyle(
                                                              color: Colors.white.withOpacity(0.5),
                                                              fontSize: 14,
                                                            ),
                                                            prefixIcon: Icon(
                                                              Icons.person_outline,
                                                              color: Colors.white.withOpacity(0.7),
                                                              size: 20,
                                                            ),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(16),
                                                              borderSide: BorderSide(
                                                                color: Colors.white.withOpacity(0.2),
                                                              ),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(16),
                                                              borderSide: BorderSide(
                                                                color: Colors.white.withOpacity(0.2),
                                                              ),
                                                            ),
                                                            filled: true,
                                                            fillColor: Colors.white.withOpacity(0.1),
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
                                                        Text(
                                                          'Last Name',
                                                          style: TextStyle(
                                                            color: Colors.white.withOpacity(0.9),
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        TextFormField(
                                                          controller: _lastNameController,
                                                          style: const TextStyle(color: Colors.white),
                                                          decoration: InputDecoration(
                                                            hintText: 'Doe',
                                                            hintStyle: TextStyle(
                                                              color: Colors.white.withOpacity(0.5),
                                                              fontSize: 14,
                                                            ),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(16),
                                                              borderSide: BorderSide(
                                                                color: Colors.white.withOpacity(0.2),
                                                              ),
                                                            ),
                                                            enabledBorder: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(16),
                                                              borderSide: BorderSide(
                                                                color: Colors.white.withOpacity(0.2),
                                                              ),
                                                            ),
                                                            filled: true,
                                                            fillColor: Colors.white.withOpacity(0.1),
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
                                              Text(
                                                'Email Address',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _emailController,
                                                keyboardType: TextInputType.emailAddress,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: 'your@email.com',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white.withOpacity(0.5),
                                                    fontSize: 14,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.email_outlined,
                                                    color: Colors.white.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
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
                                              Text(
                                                'Phone Number',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _phoneController,
                                                keyboardType: TextInputType.phone,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: '+234 800 000 0000',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white.withOpacity(0.5),
                                                    fontSize: 14,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.phone_outlined,
                                                    color: Colors.white.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
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
                                              Text(
                                                'Password',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _passwordController,
                                                obscureText: !_showPassword,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: '••••••••',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white.withOpacity(0.5),
                                                    fontSize: 14,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.lock_outline,
                                                    color: Colors.white.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _showPassword
                                                          ? Icons.visibility_off_outlined
                                                          : Icons.visibility_outlined,
                                                      color: Colors.white.withOpacity(0.7),
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _showPassword = !_showPassword;
                                                      });
                                                    },
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
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
                                              Text(
                                                'Confirm Password',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                controller: _confirmPasswordController,
                                                obscureText: !_showConfirmPassword,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: InputDecoration(
                                                  hintText: '••••••••',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white.withOpacity(0.5),
                                                    fontSize: 14,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.lock_outline,
                                                    color: Colors.white.withOpacity(0.7),
                                                    size: 20,
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _showConfirmPassword
                                                          ? Icons.visibility_off_outlined
                                                          : Icons.visibility_outlined,
                                                      color: Colors.white.withOpacity(0.7),
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _showConfirmPassword = !_showConfirmPassword;
                                                      });
                                                    },
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                    borderSide: BorderSide(
                                                      color: Colors.white.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.1),
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
                                                      checkColor: Colors.white,
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
                                                          color: Colors.white.withOpacity(0.8),
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
                                                      checkColor: Colors.white,
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
                                                        color: Colors.white.withOpacity(0.8),
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
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFF3949AB),
                                                        Color(0xFF5C6BC0),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF3949AB).withOpacity(0.3),
                                                        blurRadius: 15,
                                                        offset: const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: userProvider.isLoading ? null : _handleRegister,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.transparent,
                                                      shadowColor: Colors.transparent,
                                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
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
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                              SizedBox(width: 8),
                                                              Icon(
                                                                Icons.arrow_forward,
                                                                size: 16,
                                                                color: Colors.white,
                                                              ),
                                                            ],
                                                          ),
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
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      WidgetSpan(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            // Navigate to login
                                                            Navigator.pushReplacementNamed(context, '/login');
                                                          },
                                                          child: ShaderMask(
                                                            shaderCallback: (bounds) => const LinearGradient(
                                                              colors: [
                                                                Color(0xFFF39322),
                                                                Color(0xFFFFD700),
                                                              ],
                                                            ).createShader(bounds),
                                                            child: const Text(
                                                              'Sign In',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                              ),
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
                                    );
                                  },
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
        ],
      ),
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
  final double animationValue;

  _RegisterBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw animated geometric shapes - different from login screen
    for (int i = 0; i < 8; i++) {
      final offset = animationValue * 2 * math.pi + i * math.pi / 4;
      final x = size.width * 0.5 + 200 * math.cos(offset);
      final y = size.height * 0.5 + 200 * math.sin(offset);
      
      paint.color = [
        const Color(0xFF3949AB).withOpacity(0.1),
        const Color(0xFF1A237E).withOpacity(0.1),
        const Color(0xFF5C6BC0).withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ][i % 4];
      
      // Use different shapes for variety
      if (i % 3 == 0) {
        // Circles
        canvas.drawCircle(
          Offset(x, y),
          30 + 15 * math.sin(animationValue * 3 + i),
          paint,
        );
      } else if (i % 3 == 1) {
        // Squares
        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: 40 + 20 * math.sin(animationValue * 2 + i),
          height: 40 + 20 * math.sin(animationValue * 2 + i),
        );
        canvas.drawRect(rect, paint);
      } else {
        // Triangles
        final path = Path();
        final shapeSize = 30 + 15 * math.sin(animationValue * 4 + i);
        path.moveTo(x, y - shapeSize);
        path.lineTo(x + shapeSize, y + shapeSize);
        path.lineTo(x - shapeSize, y + shapeSize);
        path.close();
        canvas.drawPath(path, paint);
      }
    }

    // Draw connecting lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = Colors.white.withOpacity(0.1);

    for (int i = 0; i < 6; i++) {
      final offset1 = animationValue * 2 * math.pi + i * math.pi / 3;
      final offset2 = animationValue * 2 * math.pi + (i + 2) * math.pi / 3;
      
      final x1 = size.width * 0.5 + 150 * math.cos(offset1);
      final y1 = size.height * 0.5 + 150 * math.sin(offset1);
      final x2 = size.width * 0.5 + 150 * math.cos(offset2);
      final y2 = size.height * 0.5 + 150 * math.sin(offset2);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}