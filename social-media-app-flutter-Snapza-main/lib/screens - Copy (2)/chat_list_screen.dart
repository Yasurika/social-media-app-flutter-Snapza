import 'dart:async'; // StreamSubscription ekata meka aniwaren oni
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/resources/chat_methods.dart';
import 'package:social_media_app/screens/chat_screen.dart';
import 'package:social_media_app/widgets/message_notification.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Map<String, dynamic>> _activeNotifications = [];
  late StreamSubscription<QuerySnapshot> _messageListener;

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    _messageListener = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('seenAt', isNull: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var messageData = change.doc.data() as Map<String, dynamic>;
              _showNotification(change.doc.id, messageData, currentUserId);
            }
          }
        });
  }

  Future<void> _showNotification(
    String messageId,
    Map<String, dynamic> messageData,
    String currentUserId,
  ) async {
    String senderId = messageData['senderId'];
    String messagePreview = messageData['message'] ?? '';

    DocumentSnapshot senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();

    String senderName = senderDoc['username'] ?? 'Unknown';
    String senderPic = senderDoc['photoUrl'] ?? '';

    if (messagePreview.length > 50) {
      messagePreview = '${messagePreview.substring(0, 50)}...';
    }

    if (!mounted) return;

    setState(() {
      _activeNotifications.add({
        'messageId': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPic': senderPic,
        'messagePreview': messagePreview,
      });
    });
  }

  void _removeNotification(String messageId) {
    setState(() {
      _activeNotifications.removeWhere((n) => n['messageId'] == messageId);
    });
  }

  void _navigateToChat(String senderId, String senderName, String senderPic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: senderId,
          receiverName: senderName,
          receiverPic: senderPic,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageListener.cancel();
    super.dispose();
  }

  // --- FIXED METHOD: _getSortedChats ---
  Future<List<Map<String, dynamic>>> _getSortedChats(
    String currentUserId,
    List following,
  ) async {
    List<Map<String, dynamic>> chatsWithTimestamp = [];

    for (String userId in following) {
      try {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        List<String> ids = [currentUserId, userId];
        ids.sort();
        String chatRoomId = ids.join("_");

        var lastMessage = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        DateTime lastMessageTime = DateTime(1970);
        if (lastMessage.docs.isNotEmpty) {
          lastMessageTime =
              (lastMessage.docs.first.data()['timestamp'] as Timestamp)
                  .toDate();
        }

        chatsWithTimestamp.add({
          'userId': userId,
          'userData': userDoc.data(),
          'lastMessageTime': lastMessageTime,
        });
      } catch (e) {
        debugPrint('Error fetching chat data: $e');
      }
    }

    chatsWithTimestamp.sort(
      (a, b) => (b['lastMessageTime'] as DateTime).compareTo(
        a['lastMessageTime'] as DateTime,
      ),
    );
    return chatsWithTimestamp;
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Messages'),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.data() == null) {
                return const Center(child: Text('No messages yet'));
              }

              List following =
                  (snapshot.data!.data() as dynamic)['following'] ?? [];

              if (following.isEmpty) {
                return const Center(
                  child: Text('Follow someone to start chatting!'),
                );
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getSortedChats(currentUserId, following),
                builder: (context, sortedSnapshot) {
                  if (sortedSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!sortedSnapshot.hasData || sortedSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No chats yet'));
                  }

                  List<Map<String, dynamic>> sortedChats = sortedSnapshot.data!;

                  return ListView.builder(
                    itemCount: sortedChats.length,
                    itemBuilder: (context, index) {
                      var chatData = sortedChats[index];
                      var userData = chatData['userData'] as dynamic;
                      var userId = chatData['userId'];

                      return FutureBuilder<int>(
                        future: ChatMethods().getUnseenMessageCount(
                          userId: currentUserId,
                          otherUserId: userId,
                        ),
                        builder: (context, countSnapshot) {
                          int unseenCount = countSnapshot.data ?? 0;

                          return ListTile(
                            onTap: () => _navigateToChat(
                              userId,
                              userData['username'],
                              userData['photoUrl'],
                            ),
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                userData['photoUrl'],
                              ),
                            ),
                            title: Text(userData['username']),
                            subtitle: Text(
                              unseenCount > 0
                                  ? '$unseenCount new message${unseenCount > 1 ? 's' : ''}'
                                  : 'Tap to chat',
                              style: TextStyle(
                                color: unseenCount > 0
                                    ? Colors.blue
                                    : Colors.white70,
                                fontWeight: unseenCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: unseenCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      unseenCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          // Notifications overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              child: Column(
                children: _activeNotifications
                    .map(
                      (notification) => MessageNotification(
                        senderId: notification['senderId'],
                        senderName: notification['senderName'],
                        messagePreview: notification['messagePreview'],
                        senderPic: notification['senderPic'],
                        onDismiss: () =>
                            _removeNotification(notification['messageId']),
                        onTap: () {
                          _removeNotification(notification['messageId']);
                          _navigateToChat(
                            notification['senderId'],
                            notification['senderName'],
                            notification['senderPic'],
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
