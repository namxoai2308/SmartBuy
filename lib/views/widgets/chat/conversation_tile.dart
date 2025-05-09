import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/chat/conversation_model.dart';
import 'package:intl/intl.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String otherUserName;
  final String? otherUserAvatar;
  final VoidCallback onTap;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.onTap,
  }) : super(key: key);

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE').format(timestamp);
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodySmall?.color?.withOpacity(0.7);
    final timeColor = theme.textTheme.bodySmall?.color?.withOpacity(0.5);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (otherUserAvatar != null && otherUserAvatar!.isNotEmpty)
                  ? NetworkImage(otherUserAvatar!)
                  : null,
              child: (otherUserAvatar == null || otherUserAvatar!.isEmpty)
                  ? Text(
                      otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessageText,
                    style: theme.textTheme.bodyMedium?.copyWith(color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatTimestamp(conversation.lastMessageTimestamp.toDate()),
              style: theme.textTheme.bodySmall?.copyWith(color: timeColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
