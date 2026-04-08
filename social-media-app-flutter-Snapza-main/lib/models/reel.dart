import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String description;
  final String uid;
  final String username;
  final List likes;
  final String reelId;
  final DateTime datePublished;
  final String reelUrl;
  final String profImage;

  const Reel({
    required this.description,
    required this.uid,
    required this.username,
    required this.likes,
    required this.reelId,
    required this.datePublished,
    required this.reelUrl,
    required this.profImage,
  });

  static Reel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Reel(
      description: snapshot["description"],
      uid: snapshot["uid"],
      likes: snapshot["likes"],
      reelId: snapshot["reelId"],
      datePublished: (snapshot["datePublished"] as Timestamp).toDate(),
      username: snapshot["username"],
      reelUrl: snapshot['reelUrl'],
      profImage: snapshot['profImage'],
    );
  }

  Map<String, dynamic> toJson() => {
        "description": description,
        "uid": uid,
        "likes": likes,
        "username": username,
        "reelId": reelId,
        "datePublished": datePublished,
        "reelUrl": reelUrl,
        "profImage": profImage,
      };
}
