import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Listen for incoming messages and trigger notifications
  Stream<DocumentSnapshot> listenForIncomingMessages() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.empty();
    }

    // Create a pseudo-stream that emits when new messages arrive
    return _firestore.collection('chat_rooms').snapshots().asyncExpand((
      chatRoomsSnapshot,
    ) {
      // For each chat room, check for unread messages
      return Stream.fromFuture(
        _firestore
            .collection('users')
            .doc(currentUserId)
            .get()
            .then((userDoc) => userDoc),
      );
    });
  }

  /// Get unread messages for a specific user
  Stream<List<Map<String, dynamic>>> getUnreadMessages(String userId) {
    return _firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: userId)
        .where('seenAt', isNull: true)
        .snapshots()
        .map((snapshot) {
          List<Map<String, dynamic>> unreadMessages = [];
          for (var doc in snapshot.docs) {
            var data = doc.data();
            unreadMessages.add({
              'messageId': doc.id,
              'senderId': data['senderId'],
              'message': data['message'],
              'timestamp': data['timestamp'],
              'type': data['type'] ?? 'text',
            });
          }
          // Sort by latest first
          unreadMessages.sort((a, b) {
            Timestamp tsA = a['timestamp'] as Timestamp;
            Timestamp tsB = b['timestamp'] as Timestamp;
            return tsB.compareTo(tsA);
          });
          return unreadMessages;
        });
  }

  /// Dismiss notification for a specific message
  Future<void> dismissNotification(String messageId) async {
    // Notification is dismissed by marking message as seen
    // This is handled in the ChatMethods.markMessageAsSeen()
  }
}
