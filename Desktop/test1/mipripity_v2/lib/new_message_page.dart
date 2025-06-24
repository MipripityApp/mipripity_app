import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

class NewMessagePage extends StatefulWidget {
  const NewMessagePage({Key? key}) : super(key: key);

  @override
  State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredContacts = [];
  String activeTab = 'chat';
  String _selectedChatType = 'direct'; // 'direct', 'group', or 'forum'
  final List<Map<String, dynamic>> _selectedContacts = [];

  // Sample contacts
  final List<Map<String, dynamic>> _contacts = [
    {
      'id': 1,
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'status': 'Property Agent',
      'lastSeen': 'Online',
    },
    {
      'id': 2,
      'name': 'Michael Brown',
      'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'status': 'Property Developer',
      'lastSeen': '2 hours ago',
    },
    {
      'id': 3,
      'name': 'Linda Martinez',
      'avatar': 'https://randomuser.me/api/portraits/women/62.jpg',
      'status': 'Investor',
      'lastSeen': '1 day ago',
    },
    {
      'id': 4,
      'name': 'Daniel White',
      'avatar': 'https://randomuser.me/api/portraits/men/23.jpg',
      'status': 'Property Owner',
      'lastSeen': 'Online',
    },
    {
      'id': 5,
      'name': 'Jennifer Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'status': 'Home Buyer',
      'lastSeen': '3 days ago',
    },
    {
      'id': 6,
      'name': 'Robert Wilson',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
      'status': 'Architect',
      'lastSeen': 'Online',
    },
    {
      'id': 7,
      'name': 'Emily Clark',
      'avatar': 'https://randomuser.me/api/portraits/women/33.jpg',
      'status': 'Interior Designer',
      'lastSeen': '5 hours ago',
    },
    {
      'id': 8,
      'name': 'James Taylor',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'status': 'Construction Manager',
      'lastSeen': 'Yesterday',
    },
  ];

  // Sample groups
  final List<Map<String, dynamic>> _groups = [
    {
      'id': 101,
      'name': 'Property Investors Group',
      'avatar': 'assets/diverse-group-brainstorming.png',
      'members': 24,
      'description': 'Discussion group for property investment opportunities',
    },
    {
      'id': 102,
      'name': 'First-time Home Buyers',
      'avatar': 'assets/cozy-living-room.png',
      'members': 42,
      'description': 'Support group for first-time home buyers',
    },
    {
      'id': 103,
      'name': 'Lagos Real Estate Network',
      'avatar': 'assets/modern-building.png',
      'members': 78,
      'description': 'Networking group for real estate professionals in Lagos',
    },
  ];

  // Sample forums
  final List<Map<String, dynamic>> _forums = [
    {
      'id': 201,
      'name': 'Real Estate Market Trends',
      'avatar': 'assets/market-trends.png',
      'members': 156,
      'description': 'Discuss current trends in the real estate market',
    },
    {
      'id': 202,
      'name': 'Property Investment Tips',
      'avatar': 'assets/investment-tips.png',
      'members': 89,
      'description': 'Share and learn investment strategies',
    },
    {
      'id': 203,
      'name': 'Home Renovation Ideas',
      'avatar': 'assets/renovation-ideas.png',
      'members': 112,
      'description': 'Exchange ideas for home renovation and improvement',
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredContacts = List.from(_contacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts
            .where((contact) => contact['name'].toLowerCase().contains(_searchQuery))
            .toList();
      }
    });
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

  void _createNewChat() {
    if (_selectedChatType == 'direct' && _selectedContacts.length == 1) {
      // Create direct chat
      final contact = _selectedContacts.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            chatId: contact['id'],
            chatType: 'direct',
            chatName: contact['name'],
            avatar: contact['avatar'],
          ),
        ),
      );
    } else if (_selectedChatType != 'direct' && _selectedContacts.isNotEmpty) {
      // Show dialog to create group or forum
      _showCreateChatDialog();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedChatType == 'direct'
                ? 'Please select a contact'
                : 'Please select at least one contact',
          ),
        ),
      );
    }
  }

  void _showCreateChatDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create ${StringExtension(_selectedChatType).capitalize()}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '${StringExtension(_selectedChatType).capitalize()} Name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '${StringExtension(_selectedChatType).capitalize()} Description',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Members (${_selectedContacts.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _selectedContacts[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(contact['avatar']),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    contact['name'].split(' ')[0],
                                    style: const TextStyle(fontSize: 10),
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
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Create new group or forum chat
                final newChatId = _selectedChatType == 'group' 
                    ? _groups.length + 101 
                    : _forums.length + 201;
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailPage(
                      chatId: newChatId,
                      chatType: _selectedChatType,
                      chatName: nameController.text.trim(),
                      avatar: _selectedChatType == 'group'
                          ? 'assets/diverse-group-brainstorming.png'
                          : 'assets/market-trends.png',
                    ),
                  ),
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${StringExtension(_selectedChatType).capitalize()} created successfully'),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void handleTabChange(String tab) {
    setState(() {
      activeTab = tab;
    });
    
    // Handle navigation based on tab
    switch (tab) {
      case 'home':
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 'invest':
        Navigator.pushReplacementNamed(context, '/invest');
        break;
      case 'add':
        Navigator.pushReplacementNamed(context, '/add');
        break;
      case 'chat':
        Navigator.pop(context); // Go back to chat list
        break;
      case 'explore':
        Navigator.pushReplacementNamed(context, '/explore');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF000080),
          ),
        ),
        actions: [
          if (_selectedContacts.isNotEmpty)
            TextButton.icon(
              onPressed: _createNewChat,
              icon: const Icon(Icons.check, color: Color(0xFF000080)),
              label: Text(
                'Next (${_selectedContacts.length})',
                style: const TextStyle(color: Color(0xFF000080)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat type selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select chat type:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildChatTypeSelector('direct', 'Direct Message', Icons.person),
                    const SizedBox(width: 12),
                    _buildChatTypeSelector('group', 'Group Chat', Icons.group),
                    const SizedBox(width: 12),
                    _buildChatTypeSelector('forum', 'Forum', Icons.forum),
                  ],
                ),
                const SizedBox(height: 16),
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
                          onChanged: _filterContacts,
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
              ],
            ),
          ),

          // Selected contacts
          if (_selectedContacts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _selectedContacts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
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
                                          size: 14,
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
            ),
            const Divider(height: 1),
          ],

          // Existing groups/forums
          if (_searchQuery.isEmpty && _selectedChatType != 'direct') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                'Existing ${StringExtension(_selectedChatType).capitalize()}s',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _selectedChatType == 'group' ? _groups.length : _forums.length,
                itemBuilder: (context, index) {
                  final item = _selectedChatType == 'group' ? _groups[index] : _forums[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailPage(
                            chatId: item['id'],
                            chatType: _selectedChatType,
                            chatName: item['name'],
                            avatar: item['avatar'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: item['avatar'].startsWith('http')
                                  ? DecorationImage(
                                      image: NetworkImage(item['avatar']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: item['avatar'].startsWith('assets')
                                ? Center(
                                    child: Icon(
                                      _selectedChatType == 'group' ? Icons.group : Icons.forum,
                                      size: 30,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['name'],
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
            ),
          ],

          // Contacts list
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contacts found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactItem(contact);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: handleTabChange,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF000080),
        child: const Icon(Icons.person_add),
        onPressed: () {
          // Show add contact dialog
          _showAddContactDialog(context);
        },
      ),
    );
  }

  Widget _buildChatTypeSelector(String type, String label, IconData icon) {
    final isSelected = _selectedChatType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChatType = type;
            // Clear selected contacts if switching to direct and more than one contact is selected
            if (type == 'direct' && _selectedContacts.length > 1) {
              _selectedContacts.clear();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF000080) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF000080) : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(Map<String, dynamic> contact) {
    final isSelected = _isContactSelected(contact['id']);
    
    return InkWell(
      onTap: () {
        if (_selectedChatType == 'direct' && _selectedContacts.isEmpty) {
          // For direct messages, navigate directly to chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                chatId: contact['id'],
                chatType: 'direct',
                chatName: contact['name'],
                avatar: contact['avatar'],
              ),
            ),
          );
        } else {
          // For group/forum or if already selecting contacts, toggle selection
          _toggleContactSelection(contact);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(contact['avatar']),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000080),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        contact['status'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        contact['lastSeen'],
                        style: TextStyle(
                          fontSize: 12,
                          color: contact['lastSeen'] == 'Online'
                              ? Colors.green[600]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_selectedChatType != 'direct' || _selectedContacts.isNotEmpty)
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleContactSelection(contact),
                activeColor: const Color(0xFF000080),
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.message_outlined,
                  color: Color(0xFF000080),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(
                        chatId: contact['id'],
                        chatType: 'direct',
                        chatName: contact['name'],
                        avatar: contact['avatar'],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Add new contact to list
                setState(() {
                  final newContact = {
                    'id': _contacts.length + 1,
                    'name': nameController.text.trim(),
                    'avatar': 'https://randomuser.me/api/portraits/men/${(_contacts.length + 1) % 100}.jpg',
                    'status': 'New Contact',
                    'lastSeen': 'Just added',
                  };
                  
                  _contacts.add(newContact);
                  _filteredContacts = List.from(_contacts);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact added successfully')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// BottomNavigation Widget
class BottomNavigation extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const BottomNavigation({
    Key? key,
    required this.activeTab,
    required this.onTabChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                'home',
                Icons.home,
                'Home',
              ),
              _buildNavItem(
                context,
                'invest',
                Icons.trending_up,
                'Invest',
              ),
              _buildAddButton(context),
              _buildNavItem(
                context,
                'chat',
                Icons.chat_bubble,
                'Chat',
              ),
              _buildNavItem(
                context,
                'explore',
                Icons.explore,
                'Explore',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String tab,
    IconData icon,
    String label,
  ) {
    final isActive = activeTab == tab;
    return GestureDetector(
      onTap: () => onTabChange(tab),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFF39322) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              color: isActive ? const Color(0xFFF39322) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onTabChange('add'),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF39322), Color(0xFF000080)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
