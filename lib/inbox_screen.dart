import 'package:flutter/material.dart';
import 'shared/bottom_navigation.dart';
import 'dart:async';

// Message model
class Message {
  final int id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedListingId;
  final String? relatedListingTitle;
  final MessageType type;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.relatedListingId,
    this.relatedListingTitle,
    required this.type,
  });
}

enum MessageType {
  inquiry,
  bid,
  inspection,
  general,
  system,
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Message> _messages = [];
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Message> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _fetchMessages() {
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages = [
            Message(
              id: 1,
              senderId: 'user1',
              senderName: 'John Doe',
              senderAvatar: 'assets/images/lister2.jpg',
              content: 'I\'m interested in your property at Lagos Island. Is it still available?',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isRead: false,
              relatedListingId: 'mock-1',
              relatedListingTitle: 'Beautiful Land Property',
              type: MessageType.inquiry,
            ),
            Message(
              id: 2,
              senderId: 'user2',
              senderName: 'Jane Smith',
              senderAvatar: 'assets/images/lister4.jpg',
              content: 'I\'d like to place a bid of ₦230,000 for your land property.',
              timestamp: DateTime.now().subtract(const Duration(hours: 5)),
              isRead: true,
              relatedListingId: 'mock-1',
              relatedListingTitle: 'Beautiful Land Property',
              type: MessageType.bid,
            ),
            Message(
              id: 3,
              senderId: 'system',
              senderName: 'Mipripity',
              senderAvatar: 'assets/images/mipripity-logo.png',
              content: 'Your listing "Commercial Office Space" has received 5 new views today!',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              isRead: true,
              relatedListingId: 'mock-2',
              relatedListingTitle: 'Commercial Office Space',
              type: MessageType.system,
            ),
            Message(
              id: 4,
              senderId: 'user3',
              senderName: 'Robert Johnson',
              senderAvatar: 'assets/images/lister2.jpg',
              content: 'I would like to schedule an inspection for your property on Friday at 2 PM.',
              timestamp: DateTime.now().subtract(const Duration(days: 2)),
              isRead: false,
              relatedListingId: 'mock-3',
              relatedListingTitle: '3 Bedroom Apartment',
              type: MessageType.inspection,
            ),
            Message(
              id: 5,
              senderId: 'user4',
              senderName: 'Sarah Williams',
              senderAvatar: 'assets/images/lister4.jpg',
              content: 'Thank you for accepting my bid! When can we proceed with the paperwork?',
              timestamp: DateTime.now().subtract(const Duration(days: 3)),
              isRead: true,
              relatedListingId: 'mock-1',
              relatedListingTitle: 'Beautiful Land Property',
              type: MessageType.general,
            ),
          ];
          _filteredMessages = _messages; // Initialize filtered messages
          _isLoading = false;
        });
      }
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredMessages = _messages;
      } else {
        _filteredMessages = _messages.where((message) {
          return message.senderName.toLowerCase().contains(_searchQuery) ||
                 message.content.toLowerCase().contains(_searchQuery) ||
                 (message.relatedListingTitle != null && 
                  message.relatedListingTitle!.toLowerCase().contains(_searchQuery));
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _filteredMessages = _messages;
      } else {
        // Focus on search field when entering search mode
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _navigateToMessageDetail(Message message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailScreen(message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF000080)),
                ),
                style: const TextStyle(color: Color(0xFF000080)),
                onChanged: _handleSearch,
              )
            : const Text(
                'Inbox',
                style: TextStyle(
                  color: Color(0xFF000080),
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFF39322),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF39322),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'System'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF000080),
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF39322),
                  ),
                )
              : _isSearching
                  ? _buildMessageList(_filteredMessages) // Show search results directly
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // All Messages Tab
                        _buildMessageList(_messages),
                        
                        // Unread Messages Tab
                        _buildMessageList(_messages.where((msg) => !msg.isRead).toList()),
                        
                        // System Messages Tab
                        _buildMessageList(_messages.where((msg) => msg.type == MessageType.system).toList()),
                      ],
                    ),
          
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SharedBottomNavigation(
              activeTab: "chat", // Changed from "explore" to "chat" since this is the inbox/chat screen
              onTabChange: (tab) {
                SharedBottomNavigation.handleNavigation(context, tab);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages) {
    // When searching, use all filtered messages regardless of tab
    final displayMessages = _isSearching ? _filteredMessages : messages;
    
    if (displayMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No messages match your search' : 'No messages found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Add bottom padding to account for the bottom navigation
      ),
      itemCount: displayMessages.length,
      itemBuilder: (context, index) {
        final message = displayMessages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(Message message) {
    return GestureDetector(
      onTap: () => _navigateToMessageDetail(message),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: message.isRead
                ? Colors.transparent
                : const Color(0xFFF39322).withOpacity(0.5),
            width: message.isRead ? 0 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(message.senderAvatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF000080),
                          ),
                        ),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (message.relatedListingTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000080).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Re: ${message.relatedListingTitle}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Message Type Indicator
              if (!message.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF39322),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class MessageDetailScreen extends StatefulWidget {
  final Message message;

  const MessageDetailScreen({Key? key, required this.message}) : super(key: key);

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  List<Message> _conversation = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversation();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _fetchConversation() {
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _conversation = [
            widget.message,
            if (widget.message.type == MessageType.inquiry)
              Message(
                id: 101,
                senderId: 'current-user',
                senderName: 'You',
                senderAvatar: 'assets/images/chatbot.png',
                content: 'Yes, the property is still available. Would you like to schedule a viewing?',
                timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
                isRead: true,
                relatedListingId: widget.message.relatedListingId,
                relatedListingTitle: widget.message.relatedListingTitle,
                type: MessageType.inquiry,
              ),
            if (widget.message.type == MessageType.inquiry)
              Message(
                id: 102,
                senderId: widget.message.senderId,
                senderName: widget.message.senderName,
                senderAvatar: widget.message.senderAvatar,
                content: 'That would be great! How about this Saturday at 10 AM?',
                timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
                isRead: true,
                relatedListingId: widget.message.relatedListingId,
                relatedListingTitle: widget.message.relatedListingTitle,
                type: MessageType.inquiry,
              ),
          ];
          _isLoading = false;
        });
      }
    });
  }

  void _handleSendReply() {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _conversation.add(
        Message(
          id: _conversation.length + 100,
          senderId: 'current-user',
          senderName: 'You',
          senderAvatar: 'assets/images/chatbot.png',
          content: _replyController.text.trim(),
          timestamp: DateTime.now(),
          isRead: true,
          relatedListingId: widget.message.relatedListingId,
          relatedListingTitle: widget.message.relatedListingTitle,
          type: widget.message.type,
        ),
      );
      _replyController.clear();
    });

    // Simulate receiving a response
    if (widget.message.type != MessageType.system) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _conversation.add(
              Message(
                id: _conversation.length + 100,
                senderId: widget.message.senderId,
                senderName: widget.message.senderName,
                senderAvatar: widget.message.senderAvatar,
                content: 'Thanks for your response! I\'ll get back to you soon.',
                timestamp: DateTime.now(),
                isRead: true,
                relatedListingId: widget.message.relatedListingId,
                relatedListingTitle: widget.message.relatedListingTitle,
                type: widget.message.type,
              ),
            );
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(widget.message.senderAvatar),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Text(
              widget.message.senderName,
              style: const TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF000080),
            ),
            onPressed: () {
              // Show options menu
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildOptionsMenu(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Related Listing Info
          if (widget.message.relatedListingTitle != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF000080).withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF000080),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Regarding: ${widget.message.relatedListingTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to listing details
                      Navigator.pushNamed(
                        context,
                        '/property-details/${widget.message.relatedListingId}',
                      );
                    },
                    child: const Text(
                      'View Listing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF39322),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF39322),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversation.length,
                    itemBuilder: (context, index) {
                      final message = _conversation[index];
                      final isCurrentUser = message.senderId == 'current-user';
                      return _buildMessageBubble(message, isCurrentUser);
                    },
                  ),
          ),

          // Reply Input
          if (widget.message.type != MessageType.system)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: Color(0xFF000080),
                    ),
                    onPressed: () {
                      // Show attachment options
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleSendReply,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF39322), Color(0xFF000080)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? const Color(0xFF000080)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text('Delete Conversation'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Conversation'),
                  content: const Text(
                    'Are you sure you want to delete this conversation? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to inbox
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.message.type != MessageType.system)
            ListTile(
              leading: const Icon(
                Icons.block,
                color: Colors.orange,
              ),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Block User'),
                    content: Text(
                      'Are you sure you want to block ${widget.message.senderName}? You will no longer receive messages from this user.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to inbox
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${widget.message.senderName} has been blocked',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text(
                          'Block',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(
              Icons.report,
              color: Colors.amber,
            ),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              // Show report dialog
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}