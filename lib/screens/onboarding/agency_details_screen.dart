import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/onboarding_provider.dart';

class AgencyDetailsScreen extends StatefulWidget {
  const AgencyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<AgencyDetailsScreen> createState() => _AgencyDetailsScreenState();
}

class _AgencyDetailsScreenState extends State<AgencyDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  final TextEditingController _agencyNameController = TextEditingController();
  WebViewController? _webViewController;
  String _capturedBusinessName = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeUserData();
    _setupWebView();
  }
  
  void _setupWebView() {
    try {
      // Create web view controller with proper initialization
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                
                // Delay JavaScript injection to ensure page is fully loaded
                Future.delayed(const Duration(milliseconds: 1000), () {
                  _injectSearchCapture();
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = 'Failed to load page: ${error.description}';
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow all navigation within the CAC domain
              if (request.url.contains('cac.gov.ng')) {
                return NavigationDecision.navigate;
              }
              // Block external navigation
              return NavigationDecision.prevent;
            },
          ),
        );

      // Add JavaScript channel after controller is created
      _webViewController!.addJavaScriptChannel(
        'CacSearchCapture',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted) {
            setState(() {
              _capturedBusinessName = message.message;
              _agencyNameController.text = message.message;
            });
          }
        },
      );

      // Load the URL
      _webViewController!.loadRequest(
        Uri.parse('https://search.cac.gov.ng/home'),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate, br',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
    } catch (e) {
      print('Error setting up WebView: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize WebView: $e';
        });
      }
    }
  }
  
  void _injectSearchCapture() {
    if (_webViewController == null) return;
    
    try {
      // JavaScript to monitor search input and button clicks
      _webViewController!.runJavaScript('''
        (function() {
          console.log('Injecting search capture script');
          
          function captureSearchInput() {
            try {
              // Try multiple selectors for the search input
              const searchInput = document.querySelector('input[name="searchTerm"]') || 
                                 document.querySelector('input[type="search"]') ||
                                 document.querySelector('input[placeholder*="search"]') ||
                                 document.querySelector('#searchTerm') ||
                                 document.querySelector('.search-input');
              
              if (searchInput) {
                console.log('Search input found');
                
                // Remove existing listeners to avoid duplicates
                searchInput.removeEventListener('input', handleInputChange);
                searchInput.removeEventListener('change', handleInputChange);
                
                // Add new listeners
                searchInput.addEventListener('input', handleInputChange);
                searchInput.addEventListener('change', handleInputChange);
                
                // Monitor form submission
                const searchForm = searchInput.closest('form');
                if (searchForm) {
                  searchForm.removeEventListener('submit', handleFormSubmit);
                  searchForm.addEventListener('submit', handleFormSubmit);
                }
                
                // Monitor search button clicks
                const searchButtons = document.querySelectorAll('button[type="submit"], .search-btn, .btn-search, input[type="submit"]');
                searchButtons.forEach(button => {
                  button.removeEventListener('click', handleButtonClick);
                  button.addEventListener('click', handleButtonClick);
                });
                
                return true;
              } else {
                console.log('Search input not found');
                return false;
              }
            } catch (error) {
              console.error('Error in captureSearchInput:', error);
              return false;
            }
          }
          
          function handleInputChange(event) {
            const value = event.target.value.trim();
            if (value) {
              console.log('Captured input:', value);
              if (window.CacSearchCapture) {
                window.CacSearchCapture.postMessage(value);
              }
            }
          }
          
          function handleFormSubmit(event) {
            const searchInput = event.target.querySelector('input[name="searchTerm"]') || 
                               event.target.querySelector('input[type="search"]');
            if (searchInput && searchInput.value.trim()) {
              console.log('Captured form submit:', searchInput.value.trim());
              if (window.CacSearchCapture) {
                window.CacSearchCapture.postMessage(searchInput.value.trim());
              }
            }
          }
          
          function handleButtonClick(event) {
            const form = event.target.closest('form');
            if (form) {
              const searchInput = form.querySelector('input[name="searchTerm"]') || 
                                 form.querySelector('input[type="search"]');
              if (searchInput && searchInput.value.trim()) {
                console.log('Captured button click:', searchInput.value.trim());
                if (window.CacSearchCapture) {
                  window.CacSearchCapture.postMessage(searchInput.value.trim());
                }
              }
            }
          }
          
          // Try to capture immediately
          if (!captureSearchInput()) {
            // If not found, try again after DOM mutations
            let retryCount = 0;
            const maxRetries = 10;
            
            const retryInterval = setInterval(function() {
              retryCount++;
              if (captureSearchInput() || retryCount >= maxRetries) {
                clearInterval(retryInterval);
              }
            }, 1000);
          }
          
          // Also listen for DOM changes
          if (typeof MutationObserver !== 'undefined') {
            const observer = new MutationObserver(function(mutations) {
              mutations.forEach(function(mutation) {
                if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                  captureSearchInput();
                }
              });
            });
            
            observer.observe(document.body, {
              childList: true,
              subtree: true
            });
          }
          
          console.log('Search capture script initialized');
        })();
      ''');
    } catch (e) {
      print('Error injecting JavaScript: $e');
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
  
  void _initializeUserData() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = onboardingProvider.user;
    
    if (user != null && user.agencyName != null) {
      _agencyNameController.text = user.agencyName!;
    }
  }
  
  void _reloadWebView() {
    if (_webViewController != null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      _webViewController!.reload();
    }
  }
  
  @override
  void dispose() {
    _agencyNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleContinue() {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final agencyName = _agencyNameController.text.trim().isNotEmpty 
      ? _agencyNameController.text.trim() 
      : _capturedBusinessName.trim();
    
    if (agencyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a business name to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Update agency details without verification 
    // (since users are using the official CAC website directly)
    onboardingProvider.updateAgencyDetailsLocally(
      agencyName: agencyName,
      // Mark as unverified since we're not calling the API
      agencyVerified: false,
    );
    
    // Move to next step
    onboardingProvider.nextStep();
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
              
              // WebView for CAC verification
              Expanded(
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info message about CAC verification
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
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
                                Expanded(
                                  child: Text(
                                    'CAC Verification',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (_hasError)
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _reloadWebView,
                                    tooltip: 'Reload',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please use the official CAC search portal below to check if your business is registered. You can search by your business name and view the registration details.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // WebView or Error display
                      Expanded(
                        child: Stack(
                          children: [
                            if (!_hasError && _webViewController != null)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: WebViewWidget(controller: _webViewController!),
                              ),
                            
                            // Error state
                            if (_hasError)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Unable to load CAC website',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _errorMessage.isNotEmpty ? _errorMessage : 'Please check your internet connection and try again',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: _reloadWebView,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: const Color(0xFFF39322),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Loading indicator
                            if (_isLoading && !_hasError)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Color(0xFFF39322),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Loading CAC website...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Captured business name field (optional)
                      if (_capturedBusinessName.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Captured Business Name:',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _capturedBusinessName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit button
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Edit Business Name'),
                                      content: TextField(
                                        controller: _agencyNameController,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter business name',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _capturedBusinessName = _agencyNameController.text;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Manual input option
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _agencyNameController,
                        decoration: InputDecoration(
                          labelText: 'Business Name *',
                          hintText: _capturedBusinessName.isEmpty 
                              ? 'Enter your business name manually' 
                              : 'Auto-captured or enter manually',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.business),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Error message if any
              if (onboardingProvider.error != null) ...[
                const SizedBox(height: 16),
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
                    onboardingProvider.error!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
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