import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class HelpCenterPage extends StatefulWidget {
  final String language;
  const HelpCenterPage({super.key, required this.language});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  String t(String key) {
    if (widget.language == 'English') return key;
    final malay = {
      'Help and Support Center': 'Pusat Bantuan dan Sokongan',
      'Type your message...': 'Taip mesej anda...',
    };
    final chinese = {
      'Help and Support Center': '帮助与支持中心',
      'Type your message...': '输入您的消息...',
    };
    final spanish = {
      'Help and Support Center': 'Centro de Ayuda y Soporte',
      'Type your message...': 'Escribe tu mensaje...',
    };
    if (widget.language == 'Malay') return malay[key] ?? key;
    if (widget.language == 'Chinese') return chinese[key] ?? key;
    if (widget.language == 'Spanish') return spanish[key] ?? key;
    return key;
  }

  @override
  void initState() {
    super.initState();
    _messages.add({
      'sender': 'bot',
      'text': 'Welcome to BodyLog Support. How can we help you?'
    });
    _fetchHistory();
  }

  void _fetchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('support_center')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          // Keep the initial bot welcome message
          _messages.clear();
          _messages.add({
            'sender': 'bot',
            'text': 'Welcome to BodyLog Support. How can we help you?'
          });

          for (var item in response) {
            _messages.add({'sender': 'user', 'text': item['message'] ?? ''});
            
            // If the admin replied to this message, show it immediately after
            if (item['admin_reply'] != null && item['admin_reply'].toString().isNotEmpty) {
              _messages.add({'sender': 'bot', 'text': item['admin_reply']});
            }
          }
        });
      }
    } catch (e) {
      // Ignore fetch errors, just show the local basic list
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
    });
    _msgController.clear();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('support_center').insert({
          'user_id': user.id,
          'message': text,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e')),
          );
        }
      }
    }

    // Removed fake bot delay response now that we use real admin DB replies
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Help and Support Center')),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.deepPurple
                          : (isDarkMode ? Colors.grey[800] : Colors.white),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight:
                            isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft:
                            !isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser
                            ? Colors.white
                            : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF121212) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: t('Type your message...'),
                        hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
