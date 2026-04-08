import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media_app/models/message.dart';

class ChatMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String type = 'text',
    String attachmentName = '',
    String callMode = '',
    String callStatus = '',
  }) async {
    try {
      if (message.isNotEmpty) {
        Message newMessage = Message(
          id: '', // Firestore will generate ID
          senderId: senderId,
          receiverId: receiverId,
          message: message,
          timestamp: DateTime.now(),
          type: type,
          attachmentName: attachmentName,
          callMode: callMode,
          callStatus: callStatus,
        );

        // Chat room ID is a combination of both UIDs sorted alphabetically
        List<String> ids = [senderId, receiverId];
        ids.sort();
        String chatRoomId = ids.join("_");

        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .add(newMessage.toJson());
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteMessage({
    required String userId,
    required String otherUserId,
    required String messageId,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  /// Delete message for current user only
  Future<void> deleteMessageForMe({
    required String userId,
    required String otherUserId,
    required String messageId,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deletedForUsers': FieldValue.arrayUnion([userId]),
          });
    } catch (e) {
      print('Error deleting message for me: $e');
    }
  }

  /// Delete message for everyone
  Future<void> deleteMessageForEveryone({
    required String userId,
    required String otherUserId,
    required String messageId,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      print('Error deleting message for everyone: $e');
    }
  }

  Future<void> markMessageAsSeen({
    required String userId,
    required String otherUserId,
    required String messageId,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'seenAt': DateTime.now()});
    } catch (e) {
      print('Error marking message as seen: $e');
    }
  }

  Future<void> addReaction({
    required String userId,
    required String otherUserId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final messageRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      final doc = await messageRef.get();
      Map<String, dynamic> reactions = doc.data()?['reactions'] ?? {};

      reactions[userId] = emoji;

      await messageRef.update({'reactions': reactions});
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }

  Future<void> removeReaction({
    required String userId,
    required String otherUserId,
    required String messageId,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final messageRef = _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId);

      final doc = await messageRef.get();
      Map<String, dynamic> reactions = doc.data()?['reactions'] ?? {};

      reactions.remove(userId);

      await messageRef.update({'reactions': reactions});
    } catch (e) {
      print('Error removing reaction: $e');
    }
  }

  Future<int> getUnseenMessageCount({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final snapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('seenAt', isNull: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unseen message count: $e');
      return 0;
    }
  }
}
