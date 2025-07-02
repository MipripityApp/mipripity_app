import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgentProfileScreen extends StatefulWidget {
  final String email;

  const AgentProfileScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? agentData;
  String? _error;
  late TabController _tabController;
  List<Map<String, dynamic>> agentProperties = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAgentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/users/${Uri.encodeComponent(widget.email)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          setState(() {
            agentData = data['user'];
            _isLoading = false;
          });
          _fetchAgentProperties();
        } else {
          setState(() {
            _error = 'Agent not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Agent not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching agent: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAgentProperties() async {
    try {
      // Check for user_id or id field in the agent data
      final userId = agentData?['user_id'] ?? agentData?['id'];
      if (userId == null) return;
      
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/properties?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          agentProperties = data
              .take(5)
              .map<Map<String, dynamic>>((p) => p as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching agent properties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agent Profile'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000080),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF39322),
          ),
        ),
      );
    }

    if (agentData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agent Profile'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000080),
          elevation: 0,
        ),
        body: Center(
          child: Text(_error ?? 'Agent not found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF000080), Color(0xFF0a0a5e)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF39322),
                                width: 3,
                              ),
                              image: DecorationImage(
                                image: (agentData?['profile_picture'] != null && 
                                       agentData!['profile_picture'].toString().startsWith('http'))
                                    ? NetworkImage(agentData!['profile_picture'])
                                    : (agentData?['avatar_url'] != null && 
                                       agentData!['avatar_url'].toString().startsWith('http'))
                                        ? NetworkImage(agentData!['avatar_url'])
                                        : const AssetImage('assets/images/mipripity.png')
                                            as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                agentData?['full_name'] ?? 
                                  (agentData?['first_name'] != null && agentData?['last_name'] != null
                                    ? "${agentData!['first_name']} ${agentData!['last_name']}"
                                    : (agentData?['firstName'] != null && agentData?['lastName'] != null
                                        ? "${agentData!['firstName']} ${agentData!['lastName']}"
                                        : 'Unknown')),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (agentData?['is_verified'] == true)
                                Padding(
                                  padding: const EdgeInsets.only(left: 5.0),
                                  child: Icon(
                                    Icons.verified,
                                    color: Colors.green[300],
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            agentData?['role'] ?? 'Real Estate Agent',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('Total Jobs', agentData?['total_jobs']?.toString() ?? '0'),
                      _buildStatCard('Customer Ratings', '${agentData?['rating'] ?? '0'}/5'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking service...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF00B0FF),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Book Service',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Viewing pricelist...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B0FF),
                      side: const BorderSide(color: Color(0xFF00B0FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('See Pricelist'),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF000080),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF000080),
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Photos'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(),
                        _buildPhotosTab(),
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                  if (agentProperties.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Properties',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: agentProperties.length,
                      itemBuilder: (context, index) {
                        final property = agentProperties[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: property['images'] != null && property['images'].isNotEmpty
                                  ? Image.network(
                                      property['images'][0],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/residential1.jpg',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/residential1.jpg',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            title: Text(
                              property['title'] ?? 'Unknown Property',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
                              ),
                            ),
                            subtitle: Text(
                              property['location'] ?? 'Unknown Location',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Text(
                              '₦${_formatPrice(property['price'])}',
                              style: const TextStyle(
                                color: Color(0xFFF39322),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              // Navigate to property details
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            agentData?['bio'] ??
                'Nandis Healing Spa is a premier wellness destination dedicated to offering a wide range of therapeutic and beauty services designed to rejuvenate the body, mind, and spirit. Our spa specializes in various massage therapies, skincare treatments, and holistic wellness practices, all delivered by experienced and highly trained professionals. With a focus on personalized care, we cater to individuals seeking relaxation, stress relief, and overall well-being.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          _buildSkills(),
        ],
      ),
    );
  }

  Widget _buildSkills() {
    List<String> skills = [];
    if (agentData?['skills'] != null) {
      if (agentData!['skills'] is List) {
        skills = List<String>.from(agentData!['skills']);
      } else if (agentData!['skills'] is String) {
        skills = agentData!['skills'].split(',').map((e) => e.trim()).toList();
      }
    }

    if (skills.isEmpty) {
      skills = ['Real Estate Consulting', 'Property Management', 'Investment Advisory'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: skills.map((skill) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          skill,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildPhotosTab() {
    List<String> photos = [];
    if (agentData?['portfolio'] != null) {
      if (agentData!['portfolio'] is List) {
        photos = List<String>.from(agentData!['portfolio']);
      }
    }

    if (photos.isEmpty) {
      // Default placeholder images
      photos = [
        'assets/images/residential1.jpg',
        'assets/images/residential2.jpg',
        'assets/images/residential3.jpg',
      ];
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: photo.startsWith('http')
              ? Image.network(
                  photo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/residential1.jpg',
                      fit: BoxFit.cover,
                    );
                  },
                )
              : Image.asset(
                  photo,
                  fit: BoxFit.cover,
                ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    List<Map<String, dynamic>> reviews = [];
    if (agentData?['reviews'] != null) {
      if (agentData!['reviews'] is List) {
        reviews = List<Map<String, dynamic>>.from(agentData!['reviews']);
      }
    }

    if (reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 20),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundImage: review['user_image'] != null
                          ? NetworkImage(review['user_image'])
                          : const AssetImage('assets/images/mipripity.png') as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      review['user_name'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _buildRatingStars(review['rating'] ?? 5),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review['comment'] ?? 'Great service!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 16,
        );
      }),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    
    if (price is num) {
      return price.toString();
    }
    
    return price.toString();
  }
}