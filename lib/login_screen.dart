import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _setupAnimations();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('email') ?? '';
      });
    }
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_validateFields()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final userProvider = provider.Provider.of<UserProvider>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setBool('remember_me', _rememberMe);

    final success = await userProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  bool _validateFields() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter both email and password'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }

    return true;
  }

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
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                  Color(0xFF533A7B),
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BackgroundPainter(_rotationAnimation.value),
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
                                                  const Color(0xFFF39322).withOpacity(0.3),
                                                  const Color(0xFF000080).withOpacity(0.1),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.security,
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

                              // Floating elements
                              ...List.generate(6, (index) {
                                return AnimatedBuilder(
                                  animation: _backgroundAnimationController,
                                  builder: (context, child) {
                                    final offset = _backgroundAnimationController.value * 2 * math.pi;
                                    final x = 50 + 100 * math.cos(offset + index * math.pi / 3);
                                    final y = 50 + 100 * math.sin(offset + index * math.pi / 3);
                                    
                                    return Positioned(
                                      left: x + size.width * 0.2,
                                      top: y + size.height * 0.3,
                                      child: Container(
                                        width: 20 + (index % 3) * 10,
                                        height: 20 + (index % 3) * 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: [
                                            const Color(0xFFF39322),
                                            const Color(0xFF000080),
                                            Colors.white,
                                          ][index % 3].withOpacity(0.3),
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

                    // Right side - Enhanced form
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
                                width: 40,
                                height: 40,
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
                                  icon: const Icon(Icons.close, size: 18),
                                  color: Colors.white.withOpacity(0.8),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Form content with enhanced animation
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
                                                  'Welcome Back',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Sign in to continue your journey',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 32),

                                              // Error message with glassmorphism
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

                                              // Email field with glassmorphism
                                              Text(
                                                'Email Address',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: Colors.white.withOpacity(0.1),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextFormField(
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
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),

                                              // Password field with header row
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Password',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.9),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.pushNamed(context, '/forgot-password');
                                                    },
                                                    child: ShaderMask(
                                                      shaderCallback: (bounds) => const LinearGradient(
                                                        colors: [
                                                          Color(0xFFF39322),
                                                          Color(0xFFFFD700),
                                                        ],
                                                      ).createShader(bounds),
                                                      child: const Text(
                                                        'Forgot password?',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: Colors.white.withOpacity(0.1),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: TextFormField(
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
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),

                                              // Remember me checkbox
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(6),
                                                      color: _rememberMe 
                                                          ? const Color(0xFFF39322) 
                                                          : Colors.white.withOpacity(0.1),
                                                      border: Border.all(
                                                        color: _rememberMe 
                                                            ? const Color(0xFFF39322) 
                                                            : Colors.white.withOpacity(0.3),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Checkbox(
                                                      value: _rememberMe,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _rememberMe = value ?? false;
                                                        });
                                                      },
                                                      activeColor: Colors.transparent,
                                                      checkColor: Colors.white,
                                                      side: BorderSide.none,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Remember me',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 32),

                                              // Login button with gradient
                                              SizedBox(
                                                width: double.infinity,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFFF39322),
                                                        Color(0xFFFFD700),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFF39322).withOpacity(0.3),
                                                        blurRadius: 15,
                                                        offset: const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: userProvider.isLoading ? null : _handleLogin,
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
                                                                'Sign In',
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

                                              // Sign up link
                                              Center(
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Don\'t have an account? ',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      WidgetSpan(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            Navigator.pushReplacementNamed(context, '/register');
                                                          },
                                                          child: ShaderMask(
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

class _BackgroundPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw animated geometric shapes
    for (int i = 0; i < 8; i++) {
      final offset = animationValue * 2 * math.pi + i * math.pi / 4;
      final x = size.width * 0.5 + 200 * math.cos(offset);
      final y = size.height * 0.5 + 200 * math.sin(offset);
      
      paint.color = [
        const Color(0xFFF39322).withOpacity(0.1),
        const Color(0xFF000080).withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ][i % 3];
      
      canvas.drawCircle(
        Offset(x, y),
        20 + 10 * math.sin(animationValue * 3 + i),
        paint,
      );
    }

    // Draw connecting lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = Colors.white.withOpacity(0.1);

    for (int i = 0; i < 6; i++) {
      final offset1 = animationValue * 2 * math.pi + i * math.pi / 3;
      final offset2 = animationValue * 2 * math.pi + (i + 1) * math.pi / 3;
      
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