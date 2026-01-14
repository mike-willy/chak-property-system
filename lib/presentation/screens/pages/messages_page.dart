// lib/presentation/screens/pages/messages_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/message_model.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Reversed list, so 0 is bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Admin'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: Consumer2<MessageProvider, AuthProvider>(
              builder: (context, messageProvider, authProvider, _) {
                if (messageProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messageProvider.error != null) {
                  return Center(child: Text('Error: ${messageProvider.error}'));
                }

                final messages = messageProvider.messages;

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No messages yet. Start a conversation!'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Chat style: bottom-up
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == authProvider.userId;
                    
                    // Mark as read if it's from admin and not read
                    if (!isMe && !message.read && message.id != null) {
                       // Using addPostFrameCallback to avoid build-time state updates
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                          messageProvider.markAsRead(
                            message.id!,
                            message.recipientId,
                            message.recipientType,
                          );
                       });
                    }

                    return ChatBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final provider = Provider.of<MessageProvider>(context, listen: false);
      // We use a generic subject or empty for chat feeling
      await provider.sendMessageToAdmin(
        'Chat Message', 
        text,
      );
      
      _messageController.clear();
      _scrollToBottom();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }
}

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.createdAt.toDate()),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMe 
                  ? colorScheme.onPrimary.withOpacity(0.7) 
                  : colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}