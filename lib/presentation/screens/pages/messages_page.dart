// lib/presentation/screens/pages/messages_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/message_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/message_model.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  
  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMessageIds.contains(id)) {
        _selectedMessageIds.remove(id);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF141725), // Dark background
      appBar: _isSelectionMode 
        ? AppBar(
            backgroundColor: const Color(0xFF1E2235),
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _exitSelectionMode,
            ),
            title: Text(
              '${_selectedMessageIds.length} Selected',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.select_all, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedMessageIds.addAll(messageProvider.messages.map((m) => m.id!));
                    _isSelectionMode = true;
                  });
                },
                tooltip: 'Select All',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _showBatchDeleteOptions(context, messageProvider, authProvider),
              ),
            ],
          )
        : AppBar(
            title: const Text('Chat with Admin', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: const Color(0xFF141725),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: Consumer2<MessageProvider, AuthProvider>(
              builder: (context, messageProvider, authProvider, _) {
                if (messageProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4E95FF)));
                }

                if (messageProvider.error != null) {
                  return Center(child: Text('Error: ${messageProvider.error}', style: const TextStyle(color: Colors.red)));
                }

                final messages = messageProvider.messages;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet. Start a conversation!',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
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
                    final isSelected = _selectedMessageIds.contains(message.id);
                    
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

                    return ChatBubble(
                      message: message, 
                      isMe: isMe,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelection(message.id!);
                        }
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(message.id!);
                        }
                      },
                      onDeleteOptions: () => _showDeleteOptions(message, isMe),
                    );
                  },
                );
              },
            ),
          ),

          // Input Area (hidden during selection)
          if (!_isSelectionMode)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2235), // Dark Surface
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF141725), // Ultra dark input
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
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
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF4E95FF), // Brand Blue
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
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

  void _showDeleteOptions(Message message, bool isMe) {
    if (message.id == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final messageProvider = Provider.of<MessageProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Delete For Me Button
                _buildActionButton(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Delete for Me',
                  subtitle: 'This message will be removed for you only',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    messageProvider.deleteMessageForMe(message.id!, authProvider.userId!);
                  },
                ),
                
                const SizedBox(height: 12),
                
                if (isMe && !message.isDeletedForAll)
                  _buildActionButton(
                    icon: Icons.undo_rounded,
                    title: 'Delete for All',
                    subtitle: 'Unsend this message for everyone',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      messageProvider.deleteMessageForAll(message.id!);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade700, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBatchDeleteOptions(BuildContext context, MessageProvider provider, AuthProvider auth) {
    final selectedIds = _selectedMessageIds.toList();
    
    // Check if ALL selected messages are from "Me" to allow Batch "Delete for All"
    bool allFromMe = true;
    for (var id in selectedIds) {
      final msg = provider.messages.firstWhere((m) => m.id == id);
      if (msg.senderId != auth.userId || msg.isDeletedForAll) {
        allFromMe = false;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildActionButton(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Delete ${selectedIds.length} for Me',
                  subtitle: 'Remove these messages from your history',
                  color: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    provider.deleteMessagesForMe(selectedIds, auth.userId!);
                    _exitSelectionMode();
                  },
                ),
                
                if (allFromMe) ...[
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.undo_rounded,
                    title: 'Delete ${selectedIds.length} for All',
                    subtitle: 'Unsend these for everyone',
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      provider.deleteMessagesForAll(selectedIds);
                      _exitSelectionMode();
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onDeleteOptions;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onTap,
    this.onDeleteOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.isDeletedForAll;
    
    return GestureDetector(
      onLongPress: isSelectionMode ? null : onLongPress,
      onTap: isSelectionMode ? onTap : (isDeleted ? null : onDeleteOptions),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          left: isSelectionMode ? 52 : 16, 
          right: 16, 
          top: 6, 
          bottom: 6
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4E95FF).withOpacity(0.12) : Colors.transparent,
          border: isSelected ? Border(
            left: BorderSide(color: const Color(0xFF4E95FF), width: 4),
          ) : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isSelectionMode)
              Positioned(
                left: -36,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF4E95FF) : Colors.grey.shade700,
                    size: 24,
                  ),
                ),
              ),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDeleted 
                      ? Colors.transparent 
                      : (isMe ? const Color(0xFF4E95FF) : const Color(0xFF1E2235)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                  boxShadow: !isDeleted ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: isDeleted 
                  ? _buildDeletedBubble()
                  : _buildNormalBubble(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.message,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.grey.shade100,
            fontSize: 15,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('h:mm a').format(message.createdAt.toDate()),
              style: TextStyle(
                color: isMe 
                  ? Colors.white.withOpacity(0.7) 
                  : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message.read && isMe) ...[
              const SizedBox(width: 4),
              const Icon(Icons.done_all, color: Colors.white, size: 13),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDeletedBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.15), 
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'This message was deleted',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PositionPointer extends StatelessWidget {
  final bool isSelected;
  const PositionPointer({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -24,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              width: 1.5,
            ),
          ),
          child: isSelected 
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
        ),
      ),
    );
  }
}