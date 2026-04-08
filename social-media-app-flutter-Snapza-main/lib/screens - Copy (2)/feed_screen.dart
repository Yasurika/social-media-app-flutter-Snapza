import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_methods.dart';
import 'package:social_media_app/screens/chat_list_screen.dart';
import 'package:social_media_app/screens/reel_comments_screen.dart';
import 'package:social_media_app/screens/reel_detail_screen.dart';
import 'package:social_media_app/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Widget _buildReelAsPostCard(
    DocumentSnapshot<Map<String, dynamic>> reelDoc,
    model.User currentUser,
    List following,
  ) {
    final data = reelDoc.data() ?? {};
    final bool isOwner = currentUser.uid == data['uid'];
    final bool isFollowing = following.contains(data['uid']);
    final String username = data['username'] ?? '';
    final String description = data['description'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ReelDetailScreen(reelId: reelDoc.id, snap: data),
        ),
      ),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(data['profImage'] ?? ''),
                  radius: 16,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '@$username',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isOwner)
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isFollowing
                          ? Colors.transparent
                          : Colors.blue,
                      minimumSize: const Size(72, 28),
                    ),
                    onPressed: () async {
                      await FirestoreMethods().followUser(
                        currentUser.uid,
                        data['uid'],
                      );
                      setState(() {});
                    },
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing ? Colors.white60 : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    data['likes']?.contains(currentUser.uid) == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await FirestoreMethods().likeReel(
                      reelDoc.id,
                      currentUser.uid,
                      data['likes'] ?? [],
                    );
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ReelCommentsScreen(reelId: reelDoc.id),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () =>
                      _shareReelToFollowers(reelDoc.id, data['reelUrl'] ?? ''),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReelToFollowers(String reelId, String reelUrl) async {
    final model.User? currentUser = Provider.of<UserProvider>(
      context,
      listen: false,
    ).getUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final List followers =
        (userDoc.data()?['followers'] as List<dynamic>?) ?? [];
    if (followers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No followers to share with')),
      );
      return;
    }

    for (var toUid in followers) {
      await FirestoreMethods().shareReelToUser(
        reelId,
        currentUser.uid,
        toUid.toString(),
        reelUrl: reelUrl,
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Shared reel with followers')));
  }

  @override
  Widget build(BuildContext context) {
    final model.User? currentUser = Provider.of<UserProvider>(context).getUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFF2563EB),
                const Color(0xFF7C3AED),
                const Color(0xFFF59E0B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Snapza',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              const Color(0xFF2563EB),
              const Color(0xFF7C3AED),
              const Color(0xFFF59E0B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Snapza',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.messenger_outline, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final following =
              (userSnap.data?.data()?['following'] as List<dynamic>?) ?? [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reels')
                .orderBy('datePublished', descending: true)
                .snapshots(),
            builder: (context, reelSnapshot) {
              if (reelSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (reelSnapshot.hasError) {
                return Center(child: Text('Error: ${reelSnapshot.error}'));
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('datePublished', descending: true)
                    .snapshots(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (postSnapshot.hasError) {
                    return Center(child: Text('Error: ${postSnapshot.error}'));
                  }

                  final reels = reelSnapshot.data?.docs ?? [];
                  final posts = postSnapshot.data?.docs ?? [];
                  final combinedItems = <Widget>[];

                  for (var doc in reels) {
                    combinedItems.add(
                      _buildReelAsPostCard(doc, currentUser, following),
                    );
                  }
                  for (var doc in posts) {
                    combinedItems.add(PostCard(snap: doc.data()));
                  }

                  return ListView.separated(
                    itemCount: combinedItems.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.grey),
                    itemBuilder: (context, index) => combinedItems[index],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
