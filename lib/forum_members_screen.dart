import 'package:flutter/material.dart';
import 'create_forum_screen.dart';
import 'shared/bottom_navigation.dart';

class ForumMembersScreen extends StatefulWidget {
  final Map<String, dynamic> topic;

  const ForumMembersScreen({
    Key? key,
    required this.topic,
  }) : super(key: key);

  @override
  State<ForumMembersScreen> createState() => _ForumMembersScreenState();
}

class _ForumMembersScreenState extends State<ForumMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Admins', 'Moderators', 'Members', 'Recent'];

  // Sample members data
  late List<Map<String, dynamic>> _members;

  @override
  void initState() {
    super.initState();
    _generateSampleMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateSampleMembers() {
    _members = [
      {
        'id': 1,
        'name': 'You',
        'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
        'role': 'Admin',
        'joinedDate': DateTime.now().subtract(const Duration(days: 30)),
        'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
        'posts': 45,
        'location': 'Lekki Phase 1',
        'isOnline': true,
        'isCreator': true,
      },
      {
        'id': 2,
        'name': 'Sarah Johnson',
        'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
        'role': 'Moderator',
        'joinedDate': DateTime.now().subtract(const Duration(days: 25)),
        'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
        'posts': 32,
        'location': 'Lekki Phase 1',
        'isOnline': true,
        'isCreator': false,
      },
      {
        'id': 3,
        'name': 'Michael Brown',
        'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
        'role': 'Member',
        'joinedDate': DateTime.now().subtract(const Duration(days: 20)),
        'lastActive': DateTime.now().subtract(const Duration(hours: 5)),
        'posts': 18,
        'location': 'Victoria Island',
        'isOnline': false,
        'isCreator': false,
      },
      {
        'id': 4,
        'name': 'Linda Martinez',
        'avatar': 'https://randomuser.me/api/portraits/women/62.jpg',
        'role': 'Member',
        'joinedDate': DateTime.now().subtract(const Duration(days: 15)),
        'lastActive': DateTime.now().subtract(const Duration(days: 1)),
        'posts': 12,
        'location': 'Ikoyi',
        'isOnline': false,
        'isCreator': false,
      },
      {
        'id': 5,
        'name': 'Daniel White',
        'avatar': 'https://randomuser.me/api/portraits/men/23.jpg',
        'role': 'Member',
        'joinedDate': DateTime.now().subtract(const Duration(days: 10)),
        'lastActive': DateTime.now().subtract(const Duration(hours: 12)),
        'posts': 8,
        'location': 'Lekki Phase 2',
        'isOnline': true,
        'isCreator': false,
      },
    ];
  }

  void _filterMembers() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> _getFilteredMembers() {
    List<Map<String, dynamic>> filtered = List.from(_members);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        return member['name'].toLowerCase().contains(_searchQuery) ||
               member['location'].toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply role filter
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Recent') {
        filtered.sort((a, b) => b['joinedDate'].compareTo(a['joinedDate']));
        filtered = filtered.take(10).toList();
      } else {
        filtered = filtered.where((member) {
          return member['role'].toLowerCase() == _selectedFilter.toLowerCase();
        }).toList();
      }
    }

    return filtered;
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatJoinedDate(DateTime joinedDate) {
    final now = DateTime.now();
    final difference = now.difference(joinedDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _getFilteredMembers();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.topic['name']} Members',
              style: const TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${_members.length} members',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF000080)),
            onPressed: () {
              _showInviteMembersDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF000080)),
            onPressed: () {
              _showMemberOptionsBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
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
                            hintText: 'Search members',
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
                const SizedBox(height: 12),
                
                // Filter Chips
                SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF000080).withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF000080) : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF000080) : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Members List
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No members found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      return _buildMemberCard(member);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SharedBottomNavigation(
        activeTab: "chat",
        onTabChange: (tab) {
          SharedBottomNavigation.handleNavigation(context, tab);
        },
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(member['avatar']),
            ),
            if (member['isOnline'])
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              member['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            if (member['isCreator'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Creator',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(member['role']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                member['role'],
                style: TextStyle(
                  fontSize: 10,
                  color: _getRoleColor(member['role']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  member['location'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${member['posts']} posts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  member['isOnline'] ? 'Online' : _formatLastActive(member['lastActive']),
                  style: TextStyle(
                    fontSize: 12,
                    color: member['isOnline'] ? Colors.green : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Joined ${_formatJoinedDate(member['joinedDate'])}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleMemberAction(value, member);
          },
          itemBuilder: (context) {
            List<PopupMenuEntry<String>> items = [];
            
            if (member['name'] != 'You') {
              items.addAll([
                const PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      Icon(Icons.message, size: 16),
                      SizedBox(width: 8),
                      Text('Send Message'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
              ]);
              
              if (member['role'] != 'Admin') {
                items.addAll([
                  const PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        SizedBox(width: 8),
                        Text('Promote'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ]);
              }
            }
            
            return items;
          },
        ),
      ),
    );
  }

  void _handleMemberAction(String action, Map<String, dynamic> member) {
    switch (action) {
      case 'message':
        _sendMessage(member);
        break;
      case 'profile':
        _viewProfile(member);
        break;
      case 'promote':
        _promoteMember(member);
        break;
      case 'remove':
        _removeMember(member);
        break;
    }
  }

  void _sendMessage(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening chat with ${member['name']}')),
    );
    // Navigate to chat screen
  }

  void _viewProfile(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(member['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(member['avatar']),
              ),
              const SizedBox(height: 16),
              Text('Role: ${member['role']}'),
              Text('Location: ${member['location']}'),
              Text('Posts: ${member['posts']}'),
              Text('Joined: ${_formatJoinedDate(member['joinedDate'])}'),
              Text('Last Active: ${member['isOnline'] ? 'Online' : _formatLastActive(member['lastActive'])}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _promoteMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Promote ${member['name']}'),
          content: Text('Promote ${member['name']} to Moderator?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = _members.indexWhere((m) => m['id'] == member['id']);
                  if (index != -1) {
                    _members[index]['role'] = 'Moderator';
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member['name']} promoted to Moderator')),
                );
              },
              child: const Text('Promote'),
            ),
          ],
        );
      },
    );
  }

  void _removeMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove ${member['name']}'),
          content: Text('Are you sure you want to remove ${member['name']} from this forum?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _members.removeWhere((m) => m['id'] == member['id']);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member['name']} removed from forum')),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showInviteMembersDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateForumScreen(),
      ),
    );
  }

  void _showMemberOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Invite Members'),
                onTap: () {
                  Navigator.pop(context);
                  _showInviteMembersDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Member List'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member list exported')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Member Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _showMemberSettings();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Member Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Allow members to invite others'),
                value: true,
                onChanged: null,
              ),
              SwitchListTile(
                title: Text('Require approval for new members'),
                value: false,
                onChanged: null,
              ),
              SwitchListTile(
                title: Text('Show member list to all'),
                value: true,
                onChanged: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
