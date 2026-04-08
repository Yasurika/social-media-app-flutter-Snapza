import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_media_app/models/post.dart';
import 'package:social_media_app/models/reel.dart';
import 'package:social_media_app/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Some error occurred";
    try {
      String photoUrl = await StorageMethods().uploadImageToStorage(
        'posts',
        file,
        true,
      );

      if (photoUrl.isEmpty) {
        return "Failed to upload image to storage";
      }

      String postId = const Uuid().v1();
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
      );
      await _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> uploadReel(
    String description,
    Uint8List file,
    String uid,
    String username,
    String profImage,
  ) async {
    String res = "Some error occurred";
    try {
      String reelUrl = await StorageMethods().uploadImageToStorage(
        'reels',
        file,
        true,
      );

      if (reelUrl.isEmpty) {
        return "Failed to upload video to storage. Check Cloudinary settings.";
      }

      String reelId = const Uuid().v1();
      Reel reel = Reel(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        reelId: reelId,
        datePublished: DateTime.now(),
        reelUrl: reelUrl,
        profImage: profImage,
      );
      await _firestore.collection('reels').doc(reelId).set(reel.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // ... rest of the methods
  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> saveReel(String reelId, String userId) async {
    String res = "Some error occurred";
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedReels')
          .doc(reelId)
          .set({'savedAt': DateTime.now()});
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> savePost(String postId, String userId) async {
    String res = "Some error occurred";
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .set({'savedAt': DateTime.now()});
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> shareReelToUser(
    String reelId,
    String fromUid,
    String toUid, {
    required String reelUrl,
  }) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('sharedReels').doc(const Uuid().v1()).set({
        'reelId': reelId,
        'reelUrl': reelUrl,
        'fromUid': fromUid,
        'toUid': toUid,
        'sharedAt': Timestamp.now(),
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> sharePostToUser(
    String postId,
    String fromUid,
    String toUid, {
    required String postUrl,
  }) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('sharedPosts').doc(const Uuid().v1()).set({
        'postId': postId,
        'postUrl': postUrl,
        'fromUid': fromUid,
        'toUid': toUid,
        'sharedAt': Timestamp.now(),
      });
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> postComment(
    String postId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
              'profilePic': profilePic,
              'name': name,
              'uid': uid,
              'text': text,
              'commentId': commentId,
              'datePublished': DateTime.now(),
            });
        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> deleteReel(String reelId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('reels').doc(reelId).delete();
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> likeReel(String reelId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('reels').doc(reelId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await _firestore.collection('reels').doc(reelId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> postReelComment(
    String reelId,
    String text,
    String uid,
    String name,
    String profilePic,
  ) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore
            .collection('reels')
            .doc(reelId)
            .collection('comments')
            .doc(commentId)
            .set({
              'profilePic': profilePic,
              'name': name,
              'uid': uid,
              'text': text,
              'commentId': commentId,
              'datePublished': DateTime.now(),
            });
        res = 'success';
      } else {
        res = 'Please enter text';
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid]),
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId]),
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid]),
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId]),
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
