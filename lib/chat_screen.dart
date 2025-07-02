import 'package:flutter/material.dart';
import 'new_message_page.dart';
import 'chat_detail_page.dart';
import 'shared/bottom_navigation.dart';
import 'forum_topics_screen.dart';
import 'forum_detail_screen.dart';
import 'create_forum_screen.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String selectedChatType = 'direct'; // 'direct', 'group', or 'forum'

  // Sample chat items for direct messages
  final List<Map<String, dynamic>> directChatItems = [
    {
      'id': 1,
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'lastMessage': 'Hello, I\'m interested in your property listing.',
      'time': '10:30 AM',
      'unread': 2,
      'type': 'direct',
    },
    {
      'id': 2,
      'name': 'Michael Brown',
      'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'lastMessage': 'Is the price negotiable?',
      'time': 'Yesterday',
      'unread': 0,
      'type': 'direct',
    },
    {
      'id': 3,
      'name': 'Linda Martinez',
      'avatar': 'https://randomuser.me/api/portraits/women/62.jpg',
      'lastMessage': 'Thank you for the information.',
      'time': 'Monday',
      'unread': 0,
      'type': 'direct',
    },
    {
      'id': 4,
      'name': 'Daniel White',
      'avatar': 'https://randomuser.me/api/portraits/men/23.jpg',
      'lastMessage': 'I\'d like to schedule a viewing.',
      'time': 'Aug 15',
      'unread': 1,
      'type': 'direct',
    },
  ];

  // Sample chat items for group chats
  final List<Map<String, dynamic>> groupChatItems = [
    {
      'id': 5,
      'name': 'Property Investors Group',
      'avatar': 'assets/diverse-group-brainstorming.png',
      'lastMessage': 'New investment opportunity in Lekki!',
      'time': '2 hours ago',
      'unread': 3,
      'type': 'group',
    },
    {
      'id': 6,
      'name': 'First-time Home Buyers',
      'avatar': 'assets/cozy-living-room.png',
      'lastMessage': 'Tips for first-time home buyers?',
      'time': 'Yesterday',
      'unread': 5,
      'type': 'group',
    },
    {
      'id': 7,
      'name': 'Real Estate Agents Network',
      'avatar': 'assets/modern-building.png',
      'lastMessage': 'Market trends for Q3 2023',
      'time': '3 days ago',
      'unread': 0,
      'type': 'group',
    },
  ];

  // Forum topics with relevant icons and descriptions
  final List<Map<String, dynamic>> forumTopics = [
    {
      'id': 101,
      'name': 'Light Situation',
      'icon': Icons.lightbulb_outline,
      'color': Colors.amber,
      'description': 'Discuss electricity issues, power outages, and solutions',
      'members': 342,
      'posts': 128,
      'type': 'forum',
    },
    {
      'id': 102,
      'name': 'Drainage Situation',
      'icon': Icons.water_drop_outlined,
      'color': Colors.blue,
      'description': 'Share experiences and solutions for drainage problems',
      'members': 256,
      'posts': 87,
      'type': 'forum',
    },
    {
      'id': 103,
      'name': 'Landlord Wahala',
      'icon': Icons.person_outline,
      'color': Colors.red,
      'description': 'Discuss issues with landlords and how to resolve them',
      'members': 512,
      'posts': 203,
      'type': 'forum',
    },
    {
      'id': 104,
      'name': 'Tenant Wahala',
      'icon': Icons.people_outline,
      'color': Colors.purple,
      'description': 'Share experiences with tenants and get advice',
      'members': 423,
      'posts': 176,
      'type': 'forum',
    },
    {
      'id': 105,
      'name': 'House Groove',
      'icon': Icons.home_outlined,
      'color': Colors.green,
      'description': 'Tips and ideas for home improvement and decoration',
      'members': 678,
      'posts': 312,
      'type': 'forum',
    },
    {
      'id': 106,
      'name': 'Street Wahala',
      'icon': Icons.map_outlined,
      'color': Colors.orange,
      'description': 'Discuss neighborhood issues and community solutions',
      'members': 389,
      'posts': 145,
      'type': 'forum',
    },
    {
      'id': 107,
      'name': 'Security Matters',
      'icon': Icons.security_outlined,
      'color': Colors.indigo,
      'description': 'Share security tips and discuss safety concerns',
      'members': 521,
      'posts': 234,
      'type': 'forum',
    },
    {
      'id': 108,
      'name': 'Renovation Tips',
      'icon': Icons.construction_outlined,
      'color': Colors.brown,
      'description': 'Exchange ideas and advice for property renovations',
      'members': 432,
      'posts': 187,
      'type': 'forum',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Get items based on selected chat type
    List<Map<String, dynamic>> displayItems = [];
    
    if (selectedChatType == 'direct') {
      displayItems = directChatItems;
    } else if (selectedChatType == 'group') {
      displayItems = groupChatItems;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                // Add padding to account for fixed header
                const SliverPadding(
                  padding: EdgeInsets.only(top: 150),
                ),
                
                // Show forum topics grid or chat list based on selection
                selectedChatType == 'forum'
                    ? SliverToBoxAdapter(
                        child: _buildForumTopicsSection(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final chat = displayItems[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildChatItem(chat),
                              );
                            },
                            childCount: displayItems.length,
                          ),
                        ),
                      ),
                
                // Add padding at the bottom for the navigation bar
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 80),
                ),
              ],
            ),
            
            // Fixed header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and actions
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
                              ),
                            ),
                            Text(
                              selectedChatType == 'forum'
                                  ? '${forumTopics.length} forum topics'
                                  : '${displayItems.length} conversations',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Notification bell
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF000080),
                                size: 20,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF39322),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Profile image
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            image: const DecorationImage(
                              image: NetworkImage('https://randomuser.me/api/portraits/men/32.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
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
                              decoration: InputDecoration(
                                hintText: selectedChatType == 'forum'
                                    ? 'Search forum topics'
                                    : 'Search messages',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Chat Type Tabs
                    Row(
                      children: [
                        _buildChatTypeTab('direct', 'Direct'),
                        const SizedBox(width: 8),
                        _buildChatTypeTab('group', 'Group'),
                        const SizedBox(width: 8),
                        _buildChatTypeTab('forum', 'Forum'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SharedBottomNavigation(
                activeTab: "chat",
                onTabChange: (tab) {
                  SharedBottomNavigation.handleNavigation(context, tab);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        child: Icon(
          selectedChatType == 'forum'
              ? Icons.add_comment_outlined
              : Icons.chat_bubble_outline,
        ),
        onPressed: () {
          if (selectedChatType == 'forum') {
            // Navigate to create forum screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateForumScreen(),
              ),
            );
          } else {
            // Navigate to new message page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewMessagePage(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildForumTopicsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Popular Forum Topics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: forumTopics.length,
            itemBuilder: (context, index) {
              final topic = forumTopics[index];
              return _buildForumTopicCard(topic);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumTopicsScreen(forumTopics: forumTopics),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF000080),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF000080)),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('View All Forum Topics'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildForumTopicCard(Map<String, dynamic> topic) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForumDetailScreen(topic: topic),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: topic['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    topic['icon'],
                    color: topic['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    topic['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              topic['description'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${topic['members']} members',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  '${topic['posts']} posts',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTypeTab(String type, String label) {
    final isSelected = selectedChatType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChatType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000080) : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    return InkWell(
      onTap: () {
        // Navigate to chat detail page with the chat data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              chatId: chat['id'],
              chatType: chat['type'],
              chatName: chat['name'],
              avatar: chat['avatar'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Avatar with unread indicator
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: chat['avatar'].startsWith('http')
                          ? NetworkImage(chat['avatar'])
                          : AssetImage(chat['avatar']) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (chat['unread'] > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF39322),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${chat['unread']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Chat details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        chat['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateForumTopicDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateForumScreen(),
      ),
    );
  }
}
