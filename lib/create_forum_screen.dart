import 'package:flutter/material.dart';
import 'shared/bottom_navigation.dart';
import 'forum_detail_screen.dart';

class CreateForumScreen extends StatefulWidget {
  const CreateForumScreen({Key? key}) : super(key: key);

  @override
  State<CreateForumScreen> createState() => _CreateForumScreenState();
}

class _CreateForumScreenState extends State<CreateForumScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCategory = 'General';
  bool _isPrivate = false;
  String _selectedIcon = 'forum';
  Color _selectedColor = Colors.blue;
  
  final List<Map<String, dynamic>> _selectedContacts = [];
  String _searchQuery = '';

  final List<String> _categories = [
    'General', 'Housing', 'Utilities', 'Community', 'Maintenance', 'Legal', 'Investment'
  ];

  final List<Map<String, String>> _iconOptions = [
    {'name': 'forum', 'icon': 'Icons.forum'},
    {'name': 'home', 'icon': 'Icons.home'},
    {'name': 'lightbulb', 'icon': 'Icons.lightbulb'},
    {'name': 'water_drop', 'icon': 'Icons.water_drop'},
    {'name': 'security', 'icon': 'Icons.security'},
    {'name': 'construction', 'icon': 'Icons.construction'},
    {'name': 'people', 'icon': 'Icons.people'},
    {'name': 'location_city', 'icon': 'Icons.location_city'},
  ];

  final List<Color> _colorOptions = [
    Colors.blue, Colors.green, Colors.orange, Colors.purple,
    Colors.red, Colors.teal, Colors.indigo, Colors.amber,
  ];

  // Sample chat contacts
  final List<Map<String, dynamic>> _chatContacts = [
    {
      'id': 1,
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'role': 'Property Agent',
      'lastSeen': 'Online',
      'location': 'Lekki Phase 1',
    },
    {
      'id': 2,
      'name': 'Michael Brown',
      'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'role': 'Property Developer',
      'lastSeen': '2 hours ago',
      'location': 'Victoria Island',
    },
    {
      'id': 3,
      'name': 'Linda Martinez',
      'avatar': 'https://randomuser.me/api/portraits/women/62.jpg',
      'role': 'Investor',
      'lastSeen': '1 day ago',
      'location': 'Ikoyi',
    },
  ];

  // Sample all contacts
  final List<Map<String, dynamic>> _allContacts = [
    {
      'id': 4,
      'name': 'Daniel White',
      'avatar': 'https://randomuser.me/api/portraits/men/23.jpg',
      'role': 'Property Owner',
      'lastSeen': 'Online',
      'location': 'Lekki Phase 2',
    },
    {
      'id': 5,
      'name': 'Jennifer Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'role': 'Home Buyer',
      'lastSeen': '3 days ago',
      'location': 'Ajah',
    },
    {
      'id': 6,
      'name': 'Robert Wilson',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
      'role': 'Architect',
      'lastSeen': 'Online',
      'location': 'Surulere',
    },
  ];

  // Sample suggested contacts (based on proximity)
  final List<Map<String, dynamic>> _suggestedContacts = [
    {
      'id': 7,
      'name': 'Emily Clark',
      'avatar': 'https://randomuser.me/api/portraits/women/33.jpg',
      'role': 'Interior Designer',
      'lastSeen': '5 hours ago',
      'location': 'Lekki Phase 1',
      'distance': '0.5 km away',
      'mutualConnections': 3,
    },
    {
      'id': 8,
      'name': 'James Taylor',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'role': 'Construction Manager',
      'lastSeen': 'Yesterday',
      'location': 'Lekki Phase 1',
      'distance': '1.2 km away',
      'mutualConnections': 5,
    },
    {
      'id': 9,
      'name': 'Maria Garcia',
      'avatar': 'https://randomuser.me/api/portraits/women/55.jpg',
      'role': 'Real Estate Agent',
      'lastSeen': '2 hours ago',
      'location': 'Lekki Phase 2',
      'distance': '2.1 km away',
      'mutualConnections': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> _getFilteredContacts(List<Map<String, dynamic>> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    return contacts.where((contact) {
      return contact['name'].toLowerCase().contains(_searchQuery) ||
             contact['role'].toLowerCase().contains(_searchQuery) ||
             contact['location'].toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _toggleContactSelection(Map<String, dynamic> contact) {
    setState(() {
      final index = _selectedContacts.indexWhere((c) => c['id'] == contact['id']);
      if (index >= 0) {
        _selectedContacts.removeAt(index);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  bool _isContactSelected(int id) {
    return _selectedContacts.any((contact) => contact['id'] == id);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'forum': return Icons.forum;
      case 'home': return Icons.home;
      case 'lightbulb': return Icons.lightbulb;
      case 'water_drop': return Icons.water_drop;
      case 'security': return Icons.security;
      case 'construction': return Icons.construction;
      case 'people': return Icons.people;
      case 'location_city': return Icons.location_city;
      default: return Icons.forum;
    }
  }

  void _createForum() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a forum name')),
      );
      return;
    }

    // Create new forum
    final newForum = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? 'A place to discuss ${_nameController.text.trim()}'
          : _descriptionController.text.trim(),
      'icon': _getIconData(_selectedIcon),
      'color': _selectedColor,
      'category': _selectedCategory,
      'isPrivate': _isPrivate,
      'members': _selectedContacts.length + 1, // +1 for creator
      'posts': 0,
      'type': 'forum',
      'creator': 'You',
      'createdAt': DateTime.now(),
      'invitedMembers': _selectedContacts,
    };

    // Navigate to the new forum
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ForumDetailScreen(topic: newForum),
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Forum "${_nameController.text.trim()}" created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create New Forum',
          style: TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _createForum,
            child: const Text(
              'Create',
              style: TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Forum Details Section
            _buildForumDetailsSection(),
            const SizedBox(height: 24),
            
            // Invite Members Section
            _buildInviteMembersSection(),
            const SizedBox(height: 24),
            
            // Selected Members Preview
            if (_selectedContacts.isNotEmpty) _buildSelectedMembersSection(),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomNavigation(
        activeTab: "chat",
        onTabChange: (tab) {
          SharedBottomNavigation.handleNavigation(context, tab);
        },
      ),
    );
  }

  Widget _buildForumDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forum Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          
          // Forum Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Forum Name *',
              border: OutlineInputBorder(),
              hintText: 'e.g., Lekki Phase 1 Residents',
            ),
          ),
          const SizedBox(height: 16),
          
          // Forum Description
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              hintText: 'Describe what this forum is about...',
            ),
          ),
          const SizedBox(height: 16),
          
          // Category Selection
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Icon Selection
          const Text(
            'Choose Icon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _iconOptions.length,
              itemBuilder: (context, index) {
                final icon = _iconOptions[index];
                final isSelected = _selectedIcon == icon['name'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon['name']!;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getIconData(icon['name']!),
                      color: isSelected ? _selectedColor : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Color Selection
          const Text(
            'Choose Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colorOptions.length,
              itemBuilder: (context, index) {
                final color = _colorOptions[index];
                final isSelected = _selectedColor == color;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Privacy Setting
          SwitchListTile(
            title: const Text('Private Forum'),
            subtitle: const Text('Only invited members can join'),
            value: _isPrivate,
            onChanged: (value) {
              setState(() {
                _isPrivate = value;
              });
            },
            activeColor: const Color(0xFF000080),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteMembersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Invite Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedContacts.length} selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search contacts',
                      hintStyle: TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tabs for different contact lists
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF000080),
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Recent Chats'),
                Tab(text: 'All Contacts'),
                Tab(text: 'Suggested'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Contact Lists
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContactList(_getFilteredContacts(_chatContacts)),
                _buildContactList(_getFilteredContacts(_allContacts)),
                _buildSuggestedContactList(_getFilteredContacts(_suggestedContacts)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(List<Map<String, dynamic>> contacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No contacts found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = _isContactSelected(contact['id']);
        
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(contact['avatar']),
              ),
              if (isSelected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF000080),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            contact['name'],
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact['role'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                contact['location'],
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleContactSelection(contact),
            activeColor: const Color(0xFF000080),
          ),
          onTap: () => _toggleContactSelection(contact),
        );
      },
    );
  }

  Widget _buildSuggestedContactList(List<Map<String, dynamic>> contacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No suggestions found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = _isContactSelected(contact['id']);
        
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(contact['avatar']),
              ),
              if (isSelected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF000080),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            contact['name'],
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact['role'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    contact['distance'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.people,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${contact['mutualConnections']} mutual',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleContactSelection(contact),
            activeColor: const Color(0xFF000080),
          ),
          onTap: () => _toggleContactSelection(contact),
        );
      },
    );
  }

  Widget _buildSelectedMembersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Selected Members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedContacts.clear();
                  });
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedContacts.length,
              itemBuilder: (context, index) {
                final contact = _selectedContacts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(contact['avatar']),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _toggleContactSelection(contact),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact['name'].split(' ')[0],
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
