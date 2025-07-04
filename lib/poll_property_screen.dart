import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

import 'api/poll_property_api.dart' as auth_api;
import 'api/home_poll_property_api.dart' as home_api;
import 'providers/user_provider.dart';

class PollPropertyScreen extends StatefulWidget {
  final String? pollPropertyId;
  final bool isUserLoggedIn;
  
  const PollPropertyScreen({
    Key? key,
    this.pollPropertyId,
    this.isUserLoggedIn = false,
  }) : super(key: key);

  @override
  State<PollPropertyScreen> createState() => _PollPropertyScreenState();
}

class _PollPropertyScreenState extends State<PollPropertyScreen> {
  // Fixed vote options
  final List<String> voteOptions = ['Rent', 'Buy', 'Lease', 'Develop', 'Partner'];
  bool _isLoading = true;
  String? _error;
  List<dynamic> _pollProperties = []; // Using dynamic to avoid type conflicts
  int _currentPageIndex = 0;
  String? _selectedSuggestion;
  bool _isVoting = false;
  bool _hasVoted = false;
  
  // PageController for horizontal swiping
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchPollProperties();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fetch all poll properties
  Future<void> _fetchPollProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fetch poll properties based on user login status
      final properties = widget.isUserLoggedIn 
          ? await auth_api.PollPropertyApi.getPollProperties()
          : await home_api.HomePollPropertyApi.getPollProperties();
      
      if (mounted) {
        if (properties.isEmpty) {
          setState(() {
            _error = 'No poll properties available';
            _isLoading = false;
          });
        } else {
          setState(() {
            _pollProperties = properties;
            _isLoading = false;
            
            // Set initial page if a specific ID was provided
            if (widget.pollPropertyId != null) {
              // Use dynamic casting to handle different property types
              final int initialIndex = properties.indexWhere((p) {
                // Cast to dynamic to allow runtime property access
                final dynamic dynamicProperty = p;
                return dynamicProperty.id == widget.pollPropertyId;
              });
              if (initialIndex != -1) {
                _currentPageIndex = initialIndex;
                // Animate to the correct page after the build cycle completes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pageController.jumpToPage(_currentPageIndex);
                });
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load poll properties: $e';
          _isLoading = false;
        });
      }
      print('Error in _fetchPollProperties: $e');
    }
  }

  // Navigate to the next poll property
  void _nextProperty() {
    if (_currentPageIndex < _pollProperties.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // Navigate to the previous poll property
  void _previousProperty() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Handle vote for a poll property suggestion
  Future<void> _handleVote(String suggestion) async {
    if (_pollProperties.isEmpty || _currentPageIndex >= _pollProperties.length) {
      return;
    }
    
    // First check if user is logged in based on widget flag
    if (!widget.isUserLoggedIn) {
      _showLoginPrompt();
      return;
    }
    
    // Then check if user is authenticated through provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isAuthenticated()) {
      _showLoginPrompt();
      return;
    }
    
    // Proceed with voting if authenticated
    setState(() {
      _isVoting = true;
      _selectedSuggestion = suggestion;
    });
    
    try {
      final currentProperty = _pollProperties[_currentPageIndex];
      final success = await auth_api.PollPropertyApi.voteForSuggestion(
        pollPropertyId: currentProperty.id,
        suggestion: suggestion,
      );
      
      if (success && mounted) {
        // Update the local state to reflect the vote
        setState(() {
          final suggestionIndex = _pollProperties[_currentPageIndex].suggestions
              .indexWhere((s) => s.suggestion == suggestion);
          if (suggestionIndex >= 0) {
            _pollProperties[_currentPageIndex].suggestions[suggestionIndex].votes++;
            _hasVoted = true;
          }
          _isVoting = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Add haptic feedback for better user experience
        HapticFeedback.mediumImpact();
      } else if (mounted) {
        setState(() {
          _isVoting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record your vote. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error voting for poll suggestion: $e');
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show login prompt when user is not authenticated
  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFF000080),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Authentication Required",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "You need to be logged in to vote on poll properties. Please login or create an account to continue.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/login');
                        HapticFeedback.mediumImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/register');
                        HapticFeedback.mediumImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39322),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Poll Property' : 
            _pollProperties.isEmpty ? 'Poll Property' : 
            '${_pollProperties[_currentPageIndex].title} (${_currentPageIndex + 1}/${_pollProperties.length})',
          style: const TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading && _pollProperties.isNotEmpty && _pollProperties.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Color(0xFF000080)),
              tooltip: 'Swipe left or right to view more properties',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Swipe left or right to navigate between poll properties'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF000080)),
            onPressed: () {
              // Share functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF000080)),
            onPressed: () {
              // Show info dialog about poll properties
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Poll Properties'),
                  content: const Text(
                    'Poll properties are properties that need community input on their best use. '
                    'You can vote on what you think the property should be used for. '
                    'Only one vote per user is allowed for each property.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : (_error != null ? _buildErrorState() : _buildContent()),
      floatingActionButton: !_isLoading && _pollProperties.length > 1 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32.0),
                  child: _currentPageIndex > 0 
                    ? FloatingActionButton(
                        heroTag: 'prev_btn',
                        onPressed: _previousProperty,
                        backgroundColor: const Color(0xFF000080),
                        mini: true,
                        child: const Icon(Icons.arrow_back_ios, size: 18),
                      )
                    : const SizedBox(width: 40), // placeholder when on first page
                ),
                _currentPageIndex < _pollProperties.length - 1
                  ? FloatingActionButton(
                      heroTag: 'next_btn',
                      onPressed: _nextProperty,
                      backgroundColor: const Color(0xFFF39322),
                      mini: true,
                      child: const Icon(Icons.arrow_forward_ios, size: 18),
                    )
                  : const SizedBox(width: 40), // placeholder when on last page
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Loading state with shimmer effect
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Location shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 16,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Suggestions title shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 20,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Suggestions shimmer
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchPollProperties,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Main content
  Widget _buildContent() {
    if (_pollProperties.isEmpty) {
      return _buildErrorState();
    }
    
    return Stack(
      children: [
        // PageView for swiping between properties
        PageView.builder(
          controller: _pageController,
          itemCount: _pollProperties.length,
          onPageChanged: (index) {
            // Reset voting state when changing pages
            setState(() {
              _currentPageIndex = index;
              _selectedSuggestion = null;
              _hasVoted = false;
            });
            // Add haptic feedback for better user experience
            HapticFeedback.selectionClick();
          },
          itemBuilder: (context, index) {
            final property = _pollProperties[index];
            
            // Calculate the total votes to show percentage
            final int totalVotes = property.suggestions.fold(
              0, (sum, suggestion) => sum + suggestion.votes);
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: property.imageUrl.startsWith('http')
                        ? Image.network(
                            property.imageUrl,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/residential1.jpg',
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            property.imageUrl,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Property details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFFF39322),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Poll suggestions section
                        const Text(
                          'What would you like this property to be?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                        if (_hasVoted)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Thanks for voting! Total votes: $totalVotes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        // Fixed vote options instead of dynamic suggestions
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: voteOptions.length,
                          itemBuilder: (context, i) {
                            final optionText = voteOptions[i];
                            // Find if this option exists in the property suggestions
                            final suggestionIndex = property.suggestions
                                .indexWhere((s) => s.suggestion.toLowerCase() == optionText.toLowerCase());
                            
                            // Use existing suggestion if found, otherwise create a placeholder
                            final suggestion = suggestionIndex >= 0
                                ? property.suggestions[suggestionIndex]
                                : (widget.isUserLoggedIn 
                                    ? auth_api.PollSuggestion(suggestion: optionText, votes: 0)
                                    : home_api.PollSuggestion(suggestion: optionText, votes: 0));
                                
                            final bool isSelected = _selectedSuggestion == optionText;
                            final double percentage = totalVotes > 0
                                ? (suggestion.votes / totalVotes) * 100
                                : 0;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF000080).withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF000080)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isVoting || _hasVoted
                                      ? null
                                      : () => _handleVote(optionText),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                optionText,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isSelected || _hasVoted
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? const Color(0xFF000080)
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF39322),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${suggestion.votes} ${suggestion.votes == 1 ? 'vote' : 'votes'}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_hasVoted) ...[
                                          const SizedBox(height: 8),
                                          // Progress bar showing vote percentage
                                          Stack(
                                            children: [
                                              Container(
                                                height: 8,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              Container(
                                                height: 8,
                                                width: (MediaQuery.of(context).size.width - 64) * percentage / 100,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF39322),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${percentage.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                        if (_isVoting && isSelected)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFF39322),
                                                  ),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Note about voting
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF000080),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _hasVoted
                                      ? 'Thank you for your vote! The results are updated in real-time.'
                                      : 'You can vote for only one option. Your vote helps determine the best use for this property.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Swipe navigation hint if more than one property
                        if (_pollProperties.length > 1) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_currentPageIndex > 0)
                                const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF000080)),
                              const Text(
                                'Swipe to view more poll properties',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              if (_currentPageIndex < _pollProperties.length - 1)
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF000080)),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Page indicators
        if (_pollProperties.length > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pollProperties.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPageIndex == index
                        ? const Color(0xFFF39322)
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}