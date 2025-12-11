import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/agri_pulse_models.dart';
import '../providers/mock_data_provider.dart';

class GeospatialChatScreen extends ConsumerStatefulWidget {
  final ServicePin? servicePin;

  const GeospatialChatScreen({Key? key, this.servicePin}) : super(key: key);

  @override
  ConsumerState<GeospatialChatScreen> createState() =>
      _GeospatialChatScreenState();
}

class _GeospatialChatScreenState extends ConsumerState<GeospatialChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = ref.watch(chatMessagesProvider);
    final smartChips = ref.watch(smartChipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.servicePin?.name ?? 'Vikram Singh'),
            Text(
              widget.servicePin?.title ?? 'Tractor Repair Mechanic',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling...')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location: ${widget.servicePin?.latitude}, ${widget.servicePin?.longitude}'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(context, message);
              },
            ),
          ),

          // Smart chips (AI suggestions)
          if (messages.isNotEmpty && !messages.last.isFromMe)
            _buildSmartChips(context, l10n, smartChips),

          // Message input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  color: Colors.green,
                  onPressed: () {
                    _showAttachmentMenu(context, l10n);
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: l10n.messageHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isFromMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isFromMe)
            CircleAvatar(
              child: Text(message.senderAvatar),
              backgroundColor: Colors.grey[200],
            ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isFromMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isFromMe)
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isFromMe
                        ? Colors.green[500]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isFromMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          if (message.isFromMe)
            CircleAvatar(
              child: Text(message.senderAvatar),
              backgroundColor: Colors.green[100],
            ),
        ],
      ),
    );
  }

  Widget _buildSmartChips(BuildContext context, AppLocalizations l10n,
      List<SmartChip> chips) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          top: BorderSide(color: Colors.blue[100]!),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Suggested Actions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: _buildActionChip(context, chip),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, SmartChip chip) {
    return Material(
      child: InkWell(
        onTap: () {
          _messageController.text = 'I accept your bid of ${chip.value}';
          _sendMessage();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue[300]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chip.action == 'accept_bid'
                    ? Icons.check_circle
                    : chip.action == 'share_location'
                        ? Icons.location_on
                        : Icons.local_offer,
                size: 14,
                color: Colors.blue[600],
              ),
              SizedBox(width: 6),
              Text(
                chip.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAttachmentOption('📷 Photo', Icons.camera_alt, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening camera...')),
              );
            }),
            SizedBox(height: 12),
            _buildAttachmentOption('📍 Location', Icons.location_on, () {
              Navigator.pop(context);
              _sendMessage(
                messageText: 'Shared location: 28.6139°N, 77.2090°E',
              );
            }),
            SizedBox(height: 12),
            _buildAttachmentOption('📎 File', Icons.attach_file, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening file picker...')),
              );
            }),
            SizedBox(height: 12),
            _buildAttachmentOption('💬 Quick Reply', Icons.message, () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage({String? messageText}) {
    final text = messageText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    // In a real app, this would add to the chat list and send to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message sent: $text'),
        duration: Duration(seconds: 2),
      ),
    );

    _messageController.clear();

    // Scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
