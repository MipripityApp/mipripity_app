import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final int chatId;
  final String chatType;
  final String chatName;
  final String? avatar;

  const ChatDetailPage({
    Key? key,
    required this.chatId,
    required this.chatType,
    required this.chatName,
    this.avatar,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentMenuOpen = false;
  bool _isTyping = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String activeTab = 'chat';

  // Sample group members
  final List<Map<String, dynamic>> _groupMembers = [
    {
      'id': 1,
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'role': 'Admin',
      'status': 'Online',
    },
    {
      'id': 2,
      'name': 'Michael Brown',
      'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'role': 'Member',
      'status': '2 hours ago',
    },
    {
      'id': 3,
      'name': 'Linda Martinez',
      'avatar': 'https://randomuser.me/api/portraits/women/62.jpg',
      'role': 'Member',
      'status': '1 day ago',
    },
    {
      'id': 4,
      'name': 'Daniel White',
      'avatar': 'https://randomuser.me/api/portraits/men/23.jpg',
      'role': 'Member',
      'status': 'Online',
    },
    {
      'id': 5,
      'name': 'Jennifer Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'role': 'Member',
      'status': '3 days ago',
    },
  ];

  // Sample messages for demonstration
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'senderId': 2, // Other person
      'senderName': 'Michael Brown',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'text': 'Hello, I\'m interested in your property listing.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      'status': 'read',
    },
    {
      'id': 2,
      'senderId': 1, // Current user
      'senderName': 'You',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'text': 'Hi there! Which property are you interested in?',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 45)),
      'status': 'read',
    },
    {
      'id': 3,
      'senderId': 2,
      'senderName': 'Michael Brown',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'text': 'The 3-bedroom apartment in Lekki Phase 1.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 30)),
      'status': 'read',
    },
    {
      'id': 4,
      'senderId': 1,
      'senderName': 'You',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'text': 'Great choice! It\'s a beautiful property with modern amenities.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      'status': 'read',
    },
    {
      'id': 5,
      'senderId': 3,
      'senderName': 'Linda Martinez',
      'senderAvatar': 'https://randomuser.me/api/portraits/women/62.jpg',
      'text': 'What\'s the current price? And is it negotiable?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'read',
    },
    {
      'id': 6,
      'senderId': 1,
      'senderName': 'You',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'text': 'The listing price is ₦75,000,000. There might be some room for negotiation depending on the terms.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
      'status': 'read',
    },
    {
      'id': 7,
      'senderId': 2,
      'senderName': 'Michael Brown',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'text': 'That sounds reasonable. Is it possible to schedule a viewing this weekend?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'status': 'read',
    },
    {
      'id': 8,
      'senderId': 1,
      'senderName': 'You',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'text': 'We have slots available on Saturday morning and Sunday afternoon. Which would work better for you?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'status': 'read',
    },
    {
      'id': 9,
      'senderId': 4,
      'senderName': 'Daniel White',
      'senderAvatar': 'https://randomuser.me/api/portraits/men/23.jpg',
      'text': 'Sunday afternoon would be perfect. Around 2 PM?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 45)),
      'status': 'delivered',
    },
  ];

  // Filtered messages for search
  List<Map<String, dynamic>> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    // Initialize messages based on chat type
    if (widget.chatType != 'direct') {
      // For group and forum chats, use messages with sender info
      _filteredMessages = List.from(_messages);
    } else {
      // For direct chats, filter messages to only show between the two users
      _filteredMessages = _messages.where((msg) => msg['senderId'] == 1 || msg['senderId'] == widget.chatId).toList();
    }
    
    // Scroll to bottom after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'id': _messages.length + 1,
        'senderId': 1, // Current user
        'senderName': 'You',
        'senderAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
        'text': _messageController.text.trim(),
        'timestamp': DateTime.now(),
        'status': 'sent',
      });
      _messageController.clear();
      _isTyping = false;
      
      // Update filtered messages if search is active
      if (_isSearching) {
        _filterMessages(_searchQuery);
      } else {
        if (widget.chatType != 'direct') {
          _filteredMessages = List.from(_messages);
        } else {
          _filteredMessages = _messages.where((msg) => msg['senderId'] == 1 || msg['senderId'] == widget.chatId).toList();
        }
      }
    });

    // Scroll to the bottom to show the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        if (widget.chatType != 'direct') {
          _filteredMessages = List.from(_messages);
        } else {
          _filteredMessages = _messages.where((msg) => msg['senderId'] == 1 || msg['senderId'] == widget.chatId).toList();
        }
      }
    });
  }

  void _filterMessages(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        if (widget.chatType != 'direct') {
          _filteredMessages = List.from(_messages);
        } else {
          _filteredMessages = _messages.where((msg) => msg['senderId'] == 1 || msg['senderId'] == widget.chatId).toList();
        }
      } else {
        _filteredMessages = _messages
            .where((message) => 
                (message['text'].toLowerCase().contains(_searchQuery)) &&
                (widget.chatType != 'direct' || message['senderId'] == 1 || message['senderId'] == widget.chatId))
            .toList();
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to chat list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _initiateVoiceCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.chatType == 'direct' ? 'Voice Call' : 'Group Voice Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: widget.avatar != null && widget.avatar!.startsWith('http')
                  ? NetworkImage(widget.avatar!)
                  : widget.avatar != null
                      ? AssetImage(widget.avatar!) as ImageProvider
                      : const NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
            ),
            const SizedBox(height: 16),
            Text(
              widget.chatType == 'direct'
                  ? 'Calling ${widget.chatName}...'
                  : 'Starting ${widget.chatType} call with ${widget.chatName}...',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  void _initiateVideoCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.chatType == 'direct' ? 'Video Call' : 'Group Video Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: widget.avatar != null && widget.avatar!.startsWith('http')
                          ? NetworkImage(widget.avatar!)
                          : widget.avatar != null
                              ? AssetImage(widget.avatar!) as ImageProvider
                              : const NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.chatType == 'direct'
                          ? 'Connecting to ${widget.chatName}...'
                          : 'Starting ${widget.chatType} video with ${widget.chatName}...',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }

  void _viewProfile() {
    if (widget.chatType == 'direct') {
      _showDirectProfileBottomSheet();
    } else {
      _showGroupProfileBottomSheet();
    }
  }

  void _showDirectProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 60,
                backgroundImage: widget.avatar != null && widget.avatar!.startsWith('http')
                    ? NetworkImage(widget.avatar!)
                    : widget.avatar != null
                        ? AssetImage(widget.avatar!) as ImageProvider
                        : const NetworkImage('https://randomuser.me/api/portraits/women/44.jpg'),
              ),
              const SizedBox(height: 16),
              Text(
                widget.chatName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              Text(
                'Property Agent',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProfileAction(Icons.call, 'Call', _initiateVoiceCall),
                  _buildProfileAction(Icons.videocam, 'Video', _initiateVideoCall),
                  _buildProfileAction(Icons.message, 'Message', () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildProfileInfoItem(Icons.phone, '+234 812 345 6789'),
              _buildProfileInfoItem(Icons.email, 'contact@${widget.chatName.toLowerCase().replaceAll(' ', '')}.com'),
              _buildProfileInfoItem(Icons.location_on, 'Lagos, Nigeria'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text('Delete Conversation'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGroupProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 60,
                backgroundImage: widget.avatar != null && widget.avatar!.startsWith('http')
                    ? NetworkImage(widget.avatar!)
                    : widget.avatar != null
                        ? AssetImage(widget.avatar!) as ImageProvider
                        : null,
                child: widget.avatar == null || (!widget.avatar!.startsWith('http') && !widget.avatar!.startsWith('assets'))
                    ? Icon(
                        widget.chatType == 'group' ? Icons.group : Icons.forum,
                        size: 60,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.chatName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              Text(
                '${widget.chatType.capitalize()} • ${_groupMembers.length} members',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.chatType == 'group'
                      ? 'Discussion group for property investment opportunities in Lagos'
                      : 'Forum for discussing real estate market trends and opportunities',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProfileAction(Icons.call, 'Call', _initiateVoiceCall),
                  _buildProfileAction(Icons.videocam, 'Video', _initiateVideoCall),
                  _buildProfileAction(Icons.person_add, 'Add', _showAddMembersDialog),
                  _buildProfileAction(Icons.edit, 'Edit', _showEditGroupDialog),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddMembersDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF000080),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _groupMembers.length,
                  itemBuilder: (context, index) {
                    final member = _groupMembers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(member['avatar']),
                      ),
                      title: Text(member['name']),
                      subtitle: Text(member['role']),
                      trailing: member['role'] == 'Admin'
                          ? null
                          : PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'make_admin',
                                  child: Text('Make Admin'),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove from Group'),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'make_admin') {
                                  setState(() {
                                    _groupMembers[index]['role'] = 'Admin';
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${member['name']} is now an admin')),
                                  );
                                } else if (value == 'remove') {
                                  setState(() {
                                    _groupMembers.removeAt(index);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${member['name']} removed from group')),
                                  );
                                }
                              },
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You left the group')),
                        );
                        Navigator.pop(context); // Go back to chat list
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Leave Group'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete Group'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMembersDialog() {
    final List<Map<String, dynamic>> availableContacts = [
      {
        'id': 6,
        'name': 'Robert Wilson',
        'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
        'status': 'Architect',
        'selected': false,
      },
      {
        'id': 7,
        'name': 'Emily Clark',
        'avatar': 'https://randomuser.me/api/portraits/women/33.jpg',
        'status': 'Interior Designer',
        'selected': false,
      },
      {
        'id': 8,
        'name': 'James Taylor',
        'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
        'status': 'Construction Manager',
        'selected': false,
      },
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Members'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableContacts.length,
                  itemBuilder: (context, index) {
                    final contact = availableContacts[index];
                    return CheckboxListTile(
                      value: contact['selected'],
                      onChanged: (value) {
                        setState(() {
                          contact['selected'] = value;
                        });
                      },
                      title: Text(contact['name']),
                      subtitle: Text(contact['status']),
                      secondary: CircleAvatar(
                        backgroundImage: NetworkImage(contact['avatar']),
                      ),
                    );
                  },
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
                    final selectedContacts = availableContacts
                        .where((contact) => contact['selected'] == true)
                        .toList();
                    
                    if (selectedContacts.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one contact')),
                      );
                      return;
                    }
                    
                    // Add selected contacts to group members
                    for (var contact in selectedContacts) {
                      _groupMembers.add({
                        'id': contact['id'],
                        'name': contact['name'],
                        'avatar': contact['avatar'],
                        'role': 'Member',
                        'status': 'Just added',
                      });
                    }
                    
                    Navigator.pop(context);
                    Navigator.pop(context); // Close profile sheet
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added ${selectedContacts.length} ${selectedContacts.length == 1 ? 'member' : 'members'} to the group'
                        ),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGroupDialog() {
    final TextEditingController nameController = TextEditingController(text: widget.chatName);
    final TextEditingController descriptionController = TextEditingController(
      text: widget.chatType == 'group'
          ? 'Discussion group for property investment opportunities in Lagos'
          : 'Forum for discussing real estate market trends and opportunities',
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${widget.chatType.capitalize()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '${widget.chatType.capitalize()} Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '${widget.chatType.capitalize()} Description',
                  border: const OutlineInputBorder(),
                ),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                Navigator.pop(context); // Close profile sheet
                
                // Update group name in UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group information updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF000080).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF000080),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF000080),
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
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
      case 'bid':
        Navigator.pushReplacementNamed(context, '/my-bids');
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
      appBar: _isSearching
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
                onPressed: _toggleSearch,
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in conversation',
                  border: InputBorder.none,
                ),
                onChanged: _filterMessages,
              ),
              actions: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF000080)),
                    onPressed: () {
                      _searchController.clear();
                      _filterMessages('');
                    },
                  ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: widget.avatar != null && widget.avatar!.startsWith('http')
                        ? NetworkImage(widget.avatar!)
                        : widget.avatar != null
                            ? AssetImage(widget.avatar!) as ImageProvider
                            : null,
                    child: widget.avatar == null || (!widget.avatar!.startsWith('http') && !widget.avatar!.startsWith('assets'))
                        ? Icon(
                            widget.chatType == 'direct' 
                                ? Icons.person 
                                : widget.chatType == 'group' 
                                    ? Icons.group 
                                    : Icons.forum,
                            size: 16,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      Text(
                        widget.chatType == 'direct' 
                            ? 'Online' 
                            : '${widget.chatType.capitalize()} • ${_groupMembers.length} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (widget.chatType == 'direct')
                  IconButton(
                    icon: const Icon(Icons.videocam_outlined, color: Color(0xFF000080)),
                    onPressed: _initiateVideoCall,
                  ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined, color: Color(0xFF000080)),
                  onPressed: _initiateVoiceCall,
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF000080)),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF000080)),
                  onPressed: () {
                    // Show more options
                    _showOptionsBottomSheet(context);
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _filteredMessages.isEmpty
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
                          'No messages found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      final isCurrentUser = message['senderId'] == 1;
                      final showTimestamp = index == 0 ||
                          _filteredMessages[index]['timestamp'].difference(_filteredMessages[index - 1]['timestamp']).inHours >= 1;
                      final showSenderName = widget.chatType != 'direct' && !isCurrentUser;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showTimestamp)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatTimestamp(message['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (showSenderName)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                                    child: Text(
                                      message['senderName'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser ? const Color(0xFF000080) : Colors.white,
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isCurrentUser ? const Radius.circular(0) : null,
                                      bottomLeft: !isCurrentUser ? const Radius.circular(0) : null,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['text'],
                                        style: TextStyle(
                                          color: isCurrentUser ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            DateFormat('h:mm a').format(message['timestamp']),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                                            ),
                                          ),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              message['status'] == 'sent'
                                                  ? Icons.check
                                                  : message['status'] == 'delivered'
                                                      ? Icons.done_all
                                                      : Icons.done_all,
                                              size: 12,
                                              color: message['status'] == 'read'
                                                  ? Colors.blue[300]
                                                  : Colors.white.withOpacity(0.7),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Attachment menu
          if (_isAttachmentMenuOpen)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(Icons.image, Colors.purple, 'Image'),
                  _buildAttachmentOption(Icons.camera_alt, Colors.pink, 'Camera'),
                  _buildAttachmentOption(Icons.insert_drive_file, Colors.blue, 'Document'),
                  _buildAttachmentOption(Icons.location_on, Colors.green, 'Location'),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isAttachmentMenuOpen ? Icons.close : Icons.attach_file,
                      color: const Color(0xFF000080),
                    ),
                    onPressed: _toggleAttachmentMenu,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (value) {
                          setState(() {
                            _isTyping = value.trim().isNotEmpty;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isTyping
                      ? IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF000080),
                          ),
                          onPressed: _sendMessage,
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.mic,
                            color: Color(0xFF000080),
                          ),
                          onPressed: () {
                            // Handle voice recording
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voice recording coming soon')),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        activeTab: activeTab,
        onTabChange: handleTabChange,
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, Color color, String label) {
    return InkWell(
      onTap: () {
        // Handle attachment option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label attachment coming soon')),
        );
        setState(() {
          _isAttachmentMenuOpen = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildOptionItem(Icons.person, 'View Profile', () {
                Navigator.pop(context);
                _viewProfile();
              }),
              _buildOptionItem(Icons.search, 'Search in Conversation', () {
                Navigator.pop(context);
                _toggleSearch();
              }),
              _buildOptionItem(Icons.notifications_off, 'Mute Notifications', () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications muted')),
                );
              }),
              _buildOptionItem(Icons.delete, 'Delete Conversation', () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              }, isDestructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF000080),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
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
                'bid',
                Icons.chat_bubble,
                'Bid',
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
