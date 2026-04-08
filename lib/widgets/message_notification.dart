import 'package:flutter/material.dart';

/// Notification widget for displaying incoming messages
class MessageNotification extends StatefulWidget {
  final String senderId;
  final String senderName;
  final String messagePreview;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final String senderPic;

  const MessageNotification({
    super.key,
    required this.senderId,
    required this.senderName,
    required this.messagePreview,
    required this.onDismiss,
    this.onTap,
    this.senderPic = '',
  });

  @override
  State<MessageNotification> createState() => _MessageNotificationState();
}

class _MessageNotificationState extends State<MessageNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissNotification();
      }
    });
  }

  void _dismissNotification() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
          _dismissNotification();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Sender Avatar
              if (widget.senderPic.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(widget.senderPic),
                    backgroundColor: Colors.grey[800],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.senderName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.messagePreview,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[300],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Close Button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                onPressed: () {
                  _dismissNotification();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
