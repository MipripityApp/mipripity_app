import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ContactAgentScreen extends StatefulWidget {
  final Map<String, dynamic> propertyData;

  const ContactAgentScreen({
    super.key,
    required this.propertyData,
  });

  @override
  State<ContactAgentScreen> createState() => _ContactAgentScreenState();
}

class _ContactAgentScreenState extends State<ContactAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMessages = false;
  
  @override
  void initState() {
    super.initState();
    _fetchPreviousMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchPreviousMessages() async {
    if (widget.propertyData['property_id'] == null) return;
    
    setState(() {
      _isLoadingMessages = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('https://mipripity-api-1.onrender.com/property-messages?property_id=${widget.propertyData['property_id']}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data.map<Map<String, dynamic>>((m) => m as Map<String, dynamic>).toList();
          _isLoadingMessages = false;
        });
      } else {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }
  
  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Prepare message data
      final messageData = {
        'property_id': widget.propertyData['property_id'].toString(),
        'property_title': widget.propertyData['title'] ?? 'Unknown Property',
        'sender_name': _nameController.text,
        'sender_email': _emailController.text,
        'sender_phone': _phoneController.text,
        'message': _messageController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'lister_id': widget.propertyData['lister_id']?.toString() ?? '',
        'lister_email': widget.propertyData['lister_email'] ?? '',
        'lister_name': widget.propertyData['lister_name'] ?? 'Property Agent',
        'is_read': false
      };
      
      // Send to API
      final response = await http.post(
        Uri.parse('https://mipripity-api-1.onrender.com/property-messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(messageData),
      );
      
      setState(() {
        _isSubmitting = false;
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        
        // Add message to local list
        final newMessage = {...messageData, 'id': DateTime.now().millisecondsSinceEpoch.toString()};
        setState(() {
          _messages.add(newMessage);
          _messageController.clear();
        });
        
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final images = (widget.propertyData['images'] is List)
        ? List<String>.from(widget.propertyData['images'])
        : ['assets/images/residential1.jpg'];
    
    final imageUrl = images.isNotEmpty && images[0].startsWith('http')
        ? images[0]
        : 'assets/images/residential1.jpg';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Agent'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF000080),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Property and Agent Info
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property image and details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                imageUrl,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.propertyData['title'] ?? 'Untitled Property',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.propertyData['address'] ??
                                          widget.propertyData['location'] ??
                                          'Unknown Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Divider
                  const Divider(height: 1),
                  
                  // Agent details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF39322),
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: (widget.propertyData['lister_dp'] != null &&
                                      widget.propertyData['lister_dp']
                                          .toString()
                                          .startsWith('http'))
                                  ? NetworkImage(widget.propertyData['lister_dp'])
                                  : const AssetImage('assets/images/mipripity.png')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.propertyData['lister_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (widget.propertyData['lister_email'] != null)
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.propertyData['lister_email'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (widget.propertyData['lister_phone'] != null)
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.propertyData['lister_phone'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Previous messages
            Expanded(
              child: _isLoadingMessages
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFF39322)),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No previous messages. Start a conversation with the agent.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            final message = _messages[_messages.length - 1 - index];
                            final timestamp = DateTime.tryParse(message['timestamp'] ?? '');
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        message['sender_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF000080),
                                        ),
                                      ),
                                      if (timestamp != null)
                                        Text(
                                          DateFormat('MMM dd, yyyy • HH:mm').format(timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    message['message'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            
            // Message form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Only show contact info fields if no previous messages
                    if (_messages.isEmpty) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF000080)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF000080)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Invalid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.phone, color: Color(0xFF000080)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter phone';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type your message here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            maxLines: 3,
                            minLines: 1,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a message';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF000080),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                            onPressed: _isSubmitting ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}