import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String type; // text, image, video, audio, file, sticker, post, call
  final String attachmentName;
  final String callMode; // audio, video
  final String callStatus; // missed, answered, initiated
  final bool isDeleted;
  final DateTime? seenAt;
  final Map<String, String> reactions; // userId -> emoji
  final List<String>
  deletedForUsers; // Users who deleted this message for themselves

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.type = 'text',
    this.attachmentName = '',
    this.callMode = '',
    this.callStatus = '',
    this.isDeleted = false,
    this.seenAt,
    this.reactions = const {},
    this.deletedForUsers = const [],
  });

  Map<String, dynamic> toJson() => {
    "senderId": senderId,
    "receiverId": receiverId,
    "message": message,
    "timestamp": timestamp,
    "type": type,
    "attachmentName": attachmentName,
    "callMode": callMode,
    "callStatus": callStatus,
    "isDeleted": isDeleted,
    "seenAt": seenAt,
    "reactions": reactions,
    "deletedForUsers": deletedForUsers,
  };

  static Message fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Message(
      id: snap.id,
      senderId: snapshot["senderId"],
      receiverId: snapshot["receiverId"],
      message: snapshot["message"],
      timestamp: (snapshot["timestamp"] as Timestamp).toDate(),
      type: snapshot["type"] ?? 'text',
      attachmentName: snapshot["attachmentName"] ?? '',
      callMode: snapshot["callMode"] ?? '',
      callStatus: snapshot["callStatus"] ?? '',
      isDeleted: snapshot["isDeleted"] ?? false,
      seenAt: snapshot["seenAt"] != null
          ? (snapshot["seenAt"] as Timestamp).toDate()
          : null,
      reactions: Map<String, String>.from(snapshot["reactions"] ?? {}),
      deletedForUsers: List<String>.from(snapshot["deletedForUsers"] ?? []),
    );
  }
}
