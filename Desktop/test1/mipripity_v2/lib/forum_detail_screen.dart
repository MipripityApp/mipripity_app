import 'package:flutter/material.dart';
import 'shared/bottom_navigation.dart';
import 'package:intl/intl.dart';
import 'forum_members_screen.dart';

class ForumDetailScreen extends StatefulWidget {
  final Map<String, dynamic> topic;

  const ForumDetailScreen({
    Key? key,
    required this.topic,
  }) : super(key: key);

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isJoined = false;
  String _sortBy = 'recent'; // 'recent', 'popular', 'oldest'
  
  // Sample forum posts
  late List<Map<String, dynamic>> _posts;

  @override
  void initState() {
    super.initState();
    // Generate sample posts based on the topic
    _generateSamplePosts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generateSamplePosts() {
    // Sample users
    final List<Map<String, dynamic>> users = [
      {
        'id': 1,
        'name': 'Sarah Johnson',
        'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
        'role': 'Property Agent',
      },
      {
        'id': 2,
        'name': 'Michael Brown',
        'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
        'role': 'Property Developer',
      },
      {
        'id': 3,
        'name': 'Linda Martinez',
        'avatar': 'https://randomuser.me/api/portraits/women/62.jpg',
        'role': 'Investor',
      },
      {
        'id': 4,
        'name': 'Daniel White',
        'avatar': 'https://randomuser.me/api/portraits/men/23.jpg',
        'role': 'Property Owner',
      },
      {
        'id': 5,
        'name': 'Jennifer Adams',
        'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
        'role': 'Home Buyer',
      },
    ];

    // Generate posts based on topic
    final List<Map<String, dynamic>> posts = [];
    final topicName = widget.topic['name'].toLowerCase();
    final now = DateTime.now();
    
    // Generate different content based on topic
    if (topicName.contains('light')) {
      posts.addAll([
        _createPost(
          users[0],
          'Has anyone else experienced frequent power outages in Lekki Phase 1 lately?',
          now.subtract(const Duration(days: 2, hours: 5)),
          45,
          18,
        ),
        _createPost(
          users[2],
          'Yes! It\'s been terrible. We had no electricity for 3 days last week.',
          now.subtract(const Duration(days: 2, hours: 3)),
          32,
          12,
          parentId: 1,
        ),
        _createPost(
          users[3],
          'I invested in solar panels last month. Best decision ever made!',
          now.subtract(const Duration(days: 1, hours: 12)),
          67,
          8,
        ),
        _createPost(
          users[1],
          'Can anyone recommend a good generator technician? Mine keeps breaking down.',
          now.subtract(const Duration(hours: 8)),
          12,
          5,
        ),
      ]);
    } else if (topicName.contains('drainage')) {
      posts.addAll([
        _createPost(
          users[1],
          'The drainage system on my street is completely blocked. Who should I report this to?',
          now.subtract(const Duration(days: 3, hours: 7)),
          38,
          22,
        ),
        _createPost(
          users[4],
          'You should contact the local government environmental department. I had a similar issue last month.',
          now.subtract(const Duration(days: 3, hours: 5)),
          29,
          4,
          parentId: 1,
        ),
        _createPost(
          users[0],
          'Has anyone tried hiring private drainage cleaning services? Any recommendations?',
          now.subtract(const Duration(days: 1, hours: 9)),
          41,
          15,
        ),
      ]);
    } else if (topicName.contains('landlord')) {
      posts.addAll([
        _createPost(
          users[2],
          'My landlord is trying to increase rent by 50% with only one week\'s notice. Is this legal?',
          now.subtract(const Duration(days: 1, hours: 14)),
          72,
          31,
        ),
        _createPost(
          users[3],
          'No, that\'s not legal. The law requires at least 3 months notice for any rent increase.',
          now.subtract(const Duration(days: 1, hours: 12)),
          48,
          5,
          parentId: 1,
        ),
        _createPost(
          users[0],
          'I recommend getting legal advice. There\'s a tenant rights organization that offers free consultations.',
          now.subtract(const Duration(days: 1, hours: 10)),
          36,
          2,
          parentId: 1,
        ),
        _createPost(
          users[4],
          'My landlord refuses to fix the leaking roof. What are my options?',
          now.subtract(const Duration(hours: 6)),
          18,
          7,
        ),
      ]);
    } else if (topicName.contains('tenant')) {
      posts.addAll([
        _createPost(
          users[3],
          'My tenant has not paid rent for 3 months. What\'s the proper eviction process?',
          now.subtract(const Duration(days: 4, hours: 8)),
          56,
          27,
        ),
        _createPost(
          users[1],
          'First, send a formal notice giving them 7 days to pay or quit. Document everything.',
          now.subtract(const Duration(days: 4, hours: 6)),
          42,
          8,
          parentId: 1,
        ),
        _createPost(
          users[0],
          'I had a similar issue. Its important to follow the legal process to avoid complications.',
          now.subtract(const Duration(days: 4, hours: 5)),
          31,
          3,
          parentId: 1,
        ),
        _createPost(
          users[2],
          'How do you screen potential tenants? I have had bad experiences in the past.',
          now.subtract(const Duration(days: 1, hours: 3)),
          29,
          14,
        ),
      ]);
    } else if (topicName.contains('house') || topicName.contains('home')) {
      posts.addAll([
        _createPost(
          users[4],
          'What are some affordable ways to improve home security?',
          now.subtract(const Duration(days: 5, hours: 9)),
          63,
          24,
        ),
        _createPost(
          users[0],
          'Smart doorbells are relatively affordable and make a big difference. I installed one last month.',
          now.subtract(const Duration(days: 5, hours: 7)),
          47,
          6,
          parentId: 1,
        ),
        _createPost(
          users[2],
          'Anyone have recommendations for interior designers who won\'t break the bank?',
          now.subtract(const Duration(days: 2, hours: 11)),
          38,
          19,
        ),
      ]);
    } else if (topicName.contains('street')) {
      posts.addAll([
        _createPost(
          users[1],
          'Our street needs better lighting. How can we petition the local government?',
          now.subtract(const Duration(days: 6, hours: 10)),
          51,
          28,
        ),
        _createPost(
          users[3],
          'We organized a community petition last year. I can share the template we used.',
          now.subtract(const Duration(days: 6, hours: 8)),
          43,
          7,
          parentId: 1,
        ),
        _createPost(
          users[0],
          'Has anyone dealt with noisy neighbors? How did you resolve it?',
          now.subtract(const Duration(days: 3, hours: 5)),
          44,
          22,
        ),
      ]);
    } else {
      // Generic posts for other topics
      posts.addAll([
        _createPost(
          users[0],
          'What are your thoughts on this topic? I\'d love to hear everyone\'s experiences.',
          now.subtract(const Duration(days: 3, hours: 6)),
          42,
          19,
        ),
        _createPost(
          users[2],
          'I\'ve been dealing with this issue for months. Any advice would be appreciated.',
          now.subtract(const Duration(days: 2, hours: 8)),
          36,
          15,
        ),
        _createPost(
          users[4],
          'Has anyone found a good solution to this common problem?',
          now.subtract(const Duration(days: 1, hours: 4)),
          28,
          11,
        ),
      ]);
    }
    
    // Sort posts by timestamp (most recent first)
    posts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    setState(() {
      _posts = posts;
    });
  }

  Map<String, dynamic> _createPost(
    Map<String, dynamic> user,
    String content,
    DateTime timestamp,
    int likes,
    int comments, {
    int? parentId,
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch + _posts.length,
      'userId': user['id'],
      'userName': user['name'],
      'userAvatar': user['avatar'],
      'userRole': user['role'],
      'content': content,
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
      'parentId': parentId,
      'isLiked': false,
    };
  }

  void _sortPosts() {
    setState(() {
      switch (_sortBy) {
        case 'recent':
          _posts.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
          break;
        case 'popular':
          _posts.sort((a, b) => b['likes'].compareTo(a['likes']));
          break;
        case 'oldest':
          _posts.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
          break;
      }
    });
  }

  void _toggleJoin() {
    setState(() {
      _isJoined = !_isJoined;
      if (_isJoined) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You joined ${widget.topic['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You left ${widget.topic['name']}')),
        );
      }
    });
  }

  void _createNewPost() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      final newPost = _createPost(
        {
          'id': 0, // Current user
          'name': 'You',
          'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
          'role': 'Member',
        },
        _messageController.text.trim(),
        DateTime.now(),
        0,
        0,
      );
      
      _posts.insert(0, newPost);
      _messageController.clear();
    });

    // Scroll to the top to see the new post
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleLike(int index) {
    setState(() {
      final post = _posts[index];
      post['isLiked'] = !post['isLiked'];
      post['likes'] += post['isLiked'] ? 1 : -1;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(timestamp);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.topic['name'],
          style: const TextStyle(
            color: Color(0xFF000080),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF000080)),
            onPressed: () {
              _showOptionsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Topic info card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.topic['color'].withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.topic['icon'],
                        color: widget.topic['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.topic['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.topic['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.topic['members']} members',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.topic['posts']} posts',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _toggleJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isJoined ? Colors.grey[200] : const Color(0xFF000080),
                        foregroundColor: _isJoined ? Colors.black87 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(_isJoined ? 'Joined' : 'Join'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sort options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSortOption('recent', 'Recent'),
                const SizedBox(width: 8),
                _buildSortOption('popular', 'Popular'),
                const SizedBox(width: 8),
                _buildSortOption('oldest', 'Oldest'),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Posts list
          Expanded(
            child: _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to start a discussion',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      // Only show top-level posts in the main list
                      if (post['parentId'] == null) {
                        return _buildPostCard(post, index);
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Write a post...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF000080)),
                  onPressed: _createNewPost,
                ),
              ],
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

  Widget _buildSortOption(String value, String label) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _sortPosts();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(post['userAvatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post['userName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF000080).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              post['userRole'],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF000080),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(post['timestamp']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {
                    _showPostOptionsBottomSheet(context, post, index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post content
            Text(
              post['content'],
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(index),
                  child: Row(
                    children: [
                      Icon(
                        post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: post['isLiked'] ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['likes']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    _showCommentsBottomSheet(context, post);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post['comments']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    _sharePost(post);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Topic Info'),
                onTap: () {
                  Navigator.pop(context);
                  _showTopicInfo(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('View Members'),
                onTap: () {
                  Navigator.pop(context);
                  _showMembers(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notification Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _showNotificationSettings(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Report Topic'),
                onTap: () {
                  Navigator.pop(context);
                  _reportTopic(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPostOptionsBottomSheet(BuildContext context, Map<String, dynamic> post, int index) {
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
              if (post['userName'] == 'You') ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _editPost(context, post, index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(index);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.reply_outlined),
                  title: const Text('Reply to Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _replyToPost(context, post);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_outlined),
                  title: const Text('Report Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPost(context, post);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy Text'),
                onTap: () {
                  Navigator.pop(context);
                  _copyPostText(post);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentsBottomSheet(BuildContext context, Map<String, dynamic> post) {
    final TextEditingController commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comments (${post['comments']})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: 5, // Sample comments
                      itemBuilder: (context, index) {
                        return _buildCommentItem(index);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF000080)),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              // Add comment logic here
                              commentController.clear();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Comment added')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(int index) {
    final comments = [
      {
        'user': 'John Doe',
        'avatar': 'https://randomuser.me/api/portraits/men/1.jpg',
        'comment': 'Great point! I completely agree with your perspective.',
        'time': '2h ago',
      },
      {
        'user': 'Jane Smith',
        'avatar': 'https://randomuser.me/api/portraits/women/1.jpg',
        'comment': 'Thanks for sharing this. Very helpful information.',
        'time': '4h ago',
      },
      {
        'user': 'Mike Johnson',
        'avatar': 'https://randomuser.me/api/portraits/men/2.jpg',
        'comment': 'I had a similar experience. Here\'s what worked for me...',
        'time': '6h ago',
      },
      {
        'user': 'Sarah Wilson',
        'avatar': 'https://randomuser.me/api/portraits/women/2.jpg',
        'comment': 'Could you provide more details about this?',
        'time': '8h ago',
      },
      {
        'user': 'David Brown',
        'avatar': 'https://randomuser.me/api/portraits/men/3.jpg',
        'comment': 'This is exactly what I was looking for. Thank you!',
        'time': '1d ago',
      },
    ];

    if (index >= comments.length) return const SizedBox.shrink();
    
    final comment = comments[index];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment['avatar']!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['user']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment['time']!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['comment']!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTopicInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.topic['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${widget.topic['description']}'),
              const SizedBox(height: 8),
              Text('Members: ${widget.topic['members']}'),
              const SizedBox(height: 8),
              Text('Posts: ${widget.topic['posts']}'),
              const SizedBox(height: 8),
              Text('Created: ${DateFormat('MMM d, yyyy').format(DateTime.now().subtract(const Duration(days: 30)))}'),
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

  void _showMembers(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ForumMembersScreen(topic: widget.topic),
    ),
  );
}

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('New Posts'),
                subtitle: Text('Get notified of new posts in this topic'),
                value: true,
                onChanged: null,
              ),
              SwitchListTile(
                title: Text('Replies to My Posts'),
                subtitle: Text('Get notified when someone replies to your posts'),
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

  void _reportTopic(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Topic'),
          content: const Text('Are you sure you want to report this topic for inappropriate content?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Topic reported successfully')),
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _editPost(BuildContext context, Map<String, dynamic> post, int index) {
    final TextEditingController editController = TextEditingController(text: post['content']);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: editController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Edit your post...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _posts[index]['content'] = editController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deletePost(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _posts.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _replyToPost(BuildContext context, Map<String, dynamic> post) {
    final TextEditingController replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reply to ${post['userName']}'),
          content: TextField(
            controller: replyController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Write your reply...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (replyController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply posted')),
                  );
                }
              },
              child: const Text('Reply'),
            ),
          ],
        );
      },
    );
  }

  void _reportPost(BuildContext context, Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Post'),
          content: const Text('Are you sure you want to report this post for inappropriate content?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported successfully')),
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _copyPostText(Map<String, dynamic> post) {
    // In a real app, you would use Clipboard.setData()
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post text copied to clipboard')),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    // In a real app, you would use the share package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post shared successfully')),
    );
  }
}
