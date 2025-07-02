import 'package:flutter/material.dart';
import 'forum_detail_screen.dart';
import 'shared/bottom_navigation.dart';
import 'create_forum_screen.dart';

class ForumTopicsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> forumTopics;

  const ForumTopicsScreen({
    Key? key,
    required this.forumTopics,
  }) : super(key: key);

  @override
  State<ForumTopicsScreen> createState() => _ForumTopicsScreenState();
}

class _ForumTopicsScreenState extends State<ForumTopicsScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredTopics = [];

  final List<String> _categories = [
    'All',
    'Housing',
    'Utilities',
    'Community',
    'Maintenance',
    'Legal',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _filteredTopics = List.from(widget.forumTopics);
    _searchController.addListener(_filterTopics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTopics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty && _selectedCategory == 'All') {
        _filteredTopics = List.from(widget.forumTopics);
      } else {
        _filteredTopics = widget.forumTopics.where((topic) {
          final matchesQuery = query.isEmpty ||
              topic['name'].toLowerCase().contains(query) ||
              topic['description'].toLowerCase().contains(query);
          
          final matchesCategory = _selectedCategory == 'All' ||
              _getCategoryForTopic(topic['name']) == _selectedCategory;
          
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  String _getCategoryForTopic(String topicName) {
    final name = topicName.toLowerCase();
    if (name.contains('light') || name.contains('electricity') || name.contains('water') || name.contains('drainage')) {
      return 'Utilities';
    } else if (name.contains('landlord') || name.contains('tenant') || name.contains('rent')) {
      return 'Legal';
    } else if (name.contains('house') || name.contains('home') || name.contains('apartment')) {
      return 'Housing';
    } else if (name.contains('street') || name.contains('neighborhood') || name.contains('community')) {
      return 'Community';
    } else if (name.contains('renovation') || name.contains('repair') || name.contains('fix')) {
      return 'Maintenance';
    } else {
      return 'Others';
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Forum Topics',
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
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF000080)),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
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
                        hintText: 'Search forum topics',
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
          ),
          
          // Category chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    backgroundColor: Colors.grey[100],
                    selectedColor: const Color(0xFF000080).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF000080) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF000080) : Colors.transparent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // Topics list
          Expanded(
            child: _filteredTopics.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No forum topics found',
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
                    itemCount: _filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = _filteredTopics[index];
                      return _buildTopicCard(topic);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment_outlined),
        onPressed: () {
          _showCreateForumTopicDialog(context);
        },
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumDetailScreen(topic: topic),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: topic['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  topic['icon'],
                  color: topic['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic['members']} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic['posts']} posts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF000080),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Topics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: const Color(0xFF000080).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF000080) : Colors.grey[700],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filterTopics();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000080),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
