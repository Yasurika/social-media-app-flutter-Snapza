import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_methods.dart';
import 'package:social_media_app/screens/comments_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/like_animation.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int commentLen = 0;
  bool isLikeAnimating = false;
  bool isFollowing = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    fetchCommentLen();
    checkFollowing();
    checkSaved();
  }

  Future<void> fetchCommentLen() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
    if (mounted) setState(() {});
  }

  Future<void> checkFollowing() async {
    var userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    List following = userSnap.data()!['following'];
    if (mounted) {
      setState(() {
        isFollowing = following.contains(widget.snap['uid']);
      });
    }
  }

  Future<void> checkSaved() async {
    var savedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('savedPosts')
        .doc(widget.snap['postId'])
        .get();
    if (mounted) {
      setState(() {
        isSaved = savedSnap.exists;
      });
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await FirestoreMethods().deletePost(postId);
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
  }

  Future<void> savePost(String postId) async {
    try {
      String res = await FirestoreMethods().savePost(
        postId,
        FirebaseAuth.instance.currentUser!.uid,
      );
      if (res == 'success') {
        setState(() {
          isSaved = !isSaved;
        });
        showSnackBar(isSaved ? 'Post saved' : 'Post unsaved', context);
      } else {
        showSnackBar(res, context);
      }
    } catch (err) {
      showSnackBar(err.toString(), context);
    }
  }

  Future<List<Map<String, dynamic>>> _getFollowerProfiles() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List<dynamic> followersIds =
        (userDoc.data()?['followers'] as List<dynamic>?) ?? [];

    final List<Map<String, dynamic>> results = [];
    for (var followerId in followersIds) {
      final followerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(followerId.toString())
          .get();
      if (followerDoc.exists) {
        results.add({
          'uid': followerId.toString(),
          'username': followerDoc.data()?['username'] ?? 'Unknown',
          'photoUrl': followerDoc.data()?['photoUrl'] ?? '',
        });
      }
    }

    return results;
  }

  void _sharePost(BuildContext context) {
    Set<String> selectedFollowerIds = {};
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Share Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search followers by name...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => searchQuery = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select followers to share',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getFollowerProfiles(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    'Failed to load followers',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                );
                              }
                              final followers = snapshot.data ?? [];
                              final filtered = followers
                                  .where(
                                    (f) => f['username']
                                        .toString()
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()),
                                  )
                                  .toList();

                              if (filtered.isEmpty) {
                                return Center(
                                  child: Text(
                                    searchQuery.isEmpty
                                        ? 'No followers yet'
                                        : 'No matches found',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(color: Colors.white24),
                                itemBuilder: (context, index) {
                                  final follower = filtered[index];
                                  final followerId = follower['uid'] as String;
                                  final isSelected = selectedFollowerIds
                                      .contains(followerId);

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          follower['photoUrl'] != ''
                                          ? NetworkImage(follower['photoUrl'])
                                          : null,
                                      backgroundColor: Colors.grey,
                                    ),
                                    title: Text(
                                      follower['username'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    trailing: Checkbox(
                                      value: isSelected,
                                      activeColor: Colors.blueAccent,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedFollowerIds.add(followerId);
                                          } else {
                                            selectedFollowerIds.remove(
                                              followerId,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedFollowerIds.remove(
                                            followerId,
                                          );
                                        } else {
                                          selectedFollowerIds.add(followerId);
                                        }
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedFollowerIds.isEmpty
                                  ? Colors.grey
                                  : Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: selectedFollowerIds.isEmpty
                                ? null
                                : () async {
                                    final user = Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    ).getUser;
                                    if (user == null) return;

                                    for (var toUid in selectedFollowerIds) {
                                      await FirestoreMethods().sharePostToUser(
                                        widget.snap['postId'].toString(),
                                        user.uid,
                                        toUid,
                                        postUrl: widget.snap['postUrl']
                                            .toString(),
                                      );
                                    }

                                    showSnackBar(
                                      'Post sent to ${selectedFollowerIds.length} follower(s)',
                                      context,
                                    );
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            icon: const Icon(Icons.send),
                            label: const Text('Share Post'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUser;

    if (user == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // HEADER SECTION
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(uid: widget.snap['uid']),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      widget.snap['profImage'].toString(),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProfileScreen(uid: widget.snap['uid']),
                                ),
                              ),
                              child: Text(
                                widget.snap['username'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Follow Button
                            if (widget.snap['uid'] != user.uid)
                              GestureDetector(
                                onTap: () async {
                                  await FirestoreMethods().followUser(
                                    user.uid,
                                    widget.snap['uid'],
                                  );
                                  setState(() {
                                    isFollowing = !isFollowing;
                                  });
                                },
                                child: Text(
                                  isFollowing ? '• Following' : '• Follow',
                                  style: TextStyle(
                                    color: isFollowing
                                        ? Colors.grey
                                        : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.snap['uid'] == user.uid)
                  IconButton(
                    onPressed: () {
                      showDialog(
                        useRootNavigator: false,
                        context: context,
                        builder: (context) => Dialog(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shrinkWrap: true,
                            children: ['Delete']
                                .map(
                                  (e) => InkWell(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      child: Text(e),
                                    ),
                                    onTap: () {
                                      deletePost(
                                        widget.snap['postId'].toString(),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ),
          // IMAGE SECTION
          GestureDetector(
            onDoubleTap: () {
              FirestoreMethods().likePost(
                widget.snap['postId'].toString(),
                user.uid,
                widget.snap['likes'],
              );
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: Image.network(
                    widget.snap['postUrl'].toString(),
                    fit: BoxFit.cover,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // LIKE, COMMENT SECTION
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user.uid),
                smallLike: true,
                child: IconButton(
                  icon: widget.snap['likes'].contains(user.uid)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border),
                  onPressed: () => FirestoreMethods().likePost(
                    widget.snap['postId'].toString(),
                    user.uid,
                    widget.snap['likes'],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(
                      postId: widget.snap['postId'].toString(),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sharePost(context),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () => savePost(widget.snap['postId'].toString()),
                  ),
                ),
              ),
            ],
          ),
          // DESCRIPTION
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800),
                  child: Text(
                    '${widget.snap['likes'].length} likes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: widget.snap['username'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${widget.snap['description']}'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'View all $commentLen comments',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(
                        postId: widget.snap['postId'].toString(),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    DateFormat.yMMMd().format(
                      widget.snap['datePublished'].toDate(),
                    ),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
