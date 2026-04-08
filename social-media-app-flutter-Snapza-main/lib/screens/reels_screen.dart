import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_methods.dart';
import 'package:social_media_app/screens/reel_comments_screen.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  void uploadReel(String uid, String username, String profImage) async {
    Uint8List? file = await pickVideo(ImageSource.gallery);

    if (file != null) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('New Reel', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Write a caption...',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => isLoading = true);

                showSnackBar("Uploading Reel... Please wait.", context);

                String res = await FirestoreMethods().uploadReel(
                  _descriptionController.text,
                  file,
                  uid,
                  username,
                  profImage,
                );

                if (mounted) {
                  setState(() => isLoading = false);
                  if (res == 'success') {
                    showSnackBar('Reel Posted!', context);
                    _descriptionController.clear();
                  } else {
                    showSnackBar(res, context);
                  }
                }
              },
              child: const Text(
                'Share',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Reels',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, size: 28),
            onPressed: () => uploadReel(user.uid, user.username, user.photoUrl),
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('reels')
                .orderBy('datePublished', descending: true)
                .snapshots(),
            builder:
                (
                  context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Reels Yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data();
                      return ReelVideoPlayer(
                        reelId: doc.id,
                        url: data['reelUrl'],
                        username: data['username'],
                        description: data['description'],
                        likes: List<String>.from(data['likes'] ?? []),
                        commentsCount:
                            (data['comments'] as List<dynamic>?)?.length ?? 0,
                      );
                    },
                  );
                },
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 10),
                    Text("Uploading...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final String reelId;
  final String url;
  final String username;
  final String description;
  final List<String> likes;
  final int commentsCount;

  const ReelVideoPlayer({
    super.key,
    required this.reelId,
    required this.url,
    required this.username,
    required this.description,
    required this.likes,
    required this.commentsCount,
  });

  @override
  _ReelVideoPlayerState createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likesCount = widget.likes.length;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {});
              _controller.play();
              _controller.setLooping(true);
            }
          })
          .catchError((error) {
            print("Video Player Error: $error");
            if (mounted) {
              setState(() => _isError = true);
            }
          });

    _checkSaveStatus();
  }

  Future<void> _checkSaveStatus() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).getUser;
      if (user == null) return;
      final savedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedReels')
          .doc(widget.reelId)
          .get();
      if (mounted) {
        setState(() {
          _isSaved = savedDoc.exists;
        });
      }
    } catch (_) {}
  }

  void _toggleLike() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return;

    await FirestoreMethods().likeReel(widget.reelId, user.uid, widget.likes);

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
  }

  void _saveReel() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return;

    String res = await FirestoreMethods().saveReel(widget.reelId, user.uid);
    if (res == 'success') {
      setState(() {
        _isSaved = true;
      });
      showSnackBar('Saved to your profile', context);
    } else {
      showSnackBar(res, context);
    }
  }

  void _shareReelToFollowers() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List followers =
        (userDoc.data()?['followers'] as List<dynamic>?) ?? [];
    if (followers.isEmpty) {
      showSnackBar('You have no followers to share with', context);
      return;
    }

    for (var toUid in followers) {
      await FirestoreMethods().shareReelToUser(
        widget.reelId,
        user.uid,
        toUid.toString(),
        reelUrl: widget.url,
      );
    }

    showSnackBar('Shared with followers', context);
  }

  void _commentReel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReelCommentsScreen(reelId: widget.reelId),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            Text("Error loading video", style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _controller.value.isInitialized
            ? GestureDetector(
                onTap: () {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                },
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 140,
          left: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${widget.username}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.description,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          right: 12,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 32,
                ),
                onPressed: _toggleLike,
              ),
              Text('$_likesCount', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _saveReel,
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white, size: 30),
                onPressed: _commentReel,
              ),
              Text(
                '${widget.commentsCount}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 30),
                onPressed: _shareReelToFollowers,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
