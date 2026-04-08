import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/models/user.dart' as model;
import 'package:social_media_app/providers/user_provider.dart';
import 'package:social_media_app/resources/firestore_methods.dart';
import 'package:social_media_app/screens/reel_comments_screen.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:video_player/video_player.dart';

class ReelDetailScreen extends StatefulWidget {
  final String reelId;
  final Map<String, dynamic> snap;

  const ReelDetailScreen({super.key, required this.reelId, required this.snap});

  @override
  State<ReelDetailScreen> createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends State<ReelDetailScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _isLiked = false;
  bool _isSaved = false;
  final Set<String> _selectedFollowerIds = {}; // selected follower ids in share sheet

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.snap['reelUrl']))
          ..initialize()
              .then((_) {
                if (mounted) {
                  setState(() {});
                  _controller.play();
                  _controller.setLooping(true);
                }
              })
              .catchError((error) {
                if (mounted) {
                  setState(() => _isError = true);
                }
              });

    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    _isLiked = widget.snap['likes']?.contains(user?.uid) ?? false;
    _loadSaved();
  }

  void _loadSaved() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return;
    final savedDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedReels')
        .doc(widget.reelId)
        .get();
    if (mounted) {
      setState(() => _isSaved = savedDoc.exists);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return;

    await FirestoreMethods().likeReel(
      widget.reelId,
      user.uid,
      widget.snap['likes'],
    );
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        widget.snap['likes'].add(user.uid);
      } else {
        widget.snap['likes'].remove(user.uid);
      }
    });
  }

  void _shareReel() async {
    await Clipboard.setData(ClipboardData(text: widget.snap['reelUrl']));
    showSnackBar('Reel URL copied to clipboard', context);
  }

  Future<void> _deleteReel() async {
    await FirestoreMethods().deleteReel(widget.reelId);
    if (mounted) {
      showSnackBar('Reel deleted', context);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveReel() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser;
    if (user == null) return;
    String res = await FirestoreMethods().saveReel(widget.reelId, user.uid);
    if (res == 'success') {
      setState(() => _isSaved = true);
      showSnackBar('Saved to your profile', context);
    } else {
      showSnackBar(res, context);
    }
  }

  Future<void> _shareReelToFollowers() async {
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
        reelUrl: widget.snap['reelUrl'],
      );
    }
    showSnackBar('Shared with followers', context);
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

  void _showShareSheet() {
    _selectedFollowerIds.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String searchQuery = '';

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
                            'Share',
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
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _shareOption(Icons.copy, 'Copy link', _shareReel),
                          _shareOption(Icons.sms, 'SMS', () {
                            _shareReel();
                            showSnackBar(
                              'SMS share not available; link copied',
                              context,
                            );
                          }),
                          _shareOption(Icons.share, 'WhatsApp', () {
                            _shareReel();
                            showSnackBar(
                              'WhatsApp share not available; link copied',
                              context,
                            );
                          }),
                          _shareOption(Icons.facebook, 'Facebook', () {
                            _shareReel();
                            showSnackBar(
                              'Facebook share not available; link copied',
                              context,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
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
                            List<Map<String, dynamic>> followers =
                                snapshot.data ?? [];

                            if (searchQuery.isNotEmpty) {
                              followers = followers
                                  .where(
                                    (f) => f['username']
                                        .toString()
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()),
                                  )
                                  .toList();
                            }

                            if (followers.isEmpty) {
                              return Center(
                                child: Text(
                                  searchQuery.isEmpty
                                      ? 'No followers yet'
                                      : 'No matches found',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            return ListView.separated(
                              controller: scrollController,
                              itemCount: followers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(color: Colors.white24),
                              itemBuilder: (context, index) {
                                final follower = followers[index];
                                final followerId = follower['uid'] as String;
                                final isSelected = _selectedFollowerIds
                                    .contains(followerId);

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundImage: follower['photoUrl'] != ''
                                        ? NetworkImage(follower['photoUrl'])
                                        : null,
                                    backgroundColor: Colors.grey,
                                  ),
                                  title: Text(
                                    follower['username'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    activeColor: Colors.blueAccent,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedFollowerIds.add(followerId);
                                        } else {
                                          _selectedFollowerIds.remove(
                                            followerId,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedFollowerIds.remove(followerId);
                                      } else {
                                        _selectedFollowerIds.add(followerId);
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
                            backgroundColor: _selectedFollowerIds.isEmpty
                                ? Colors.grey
                                : Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _selectedFollowerIds.isEmpty
                              ? null
                              : () async {
                                  final user = Provider.of<UserProvider>(
                                    context,
                                    listen: false,
                                  ).getUser;
                                  if (user == null) return;

                                  for (var toUid in _selectedFollowerIds) {
                                    await FirestoreMethods().shareReelToUser(
                                      widget.reelId,
                                      user.uid,
                                      toUid,
                                      reelUrl: widget.snap['reelUrl'],
                                    );
                                  }

                                  showSnackBar(
                                    'Reel sent to ${_selectedFollowerIds.length} follower(s)',
                                    context,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          icon: const Icon(Icons.send),
                          label: const Text('Share to selected followers'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _shareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blueGrey,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUser;
    final bool isOwner = user != null && user.uid == widget.snap['uid'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Video'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _showShareSheet),
          if (isOwner)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteReel),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isError
          ? const Center(
              child: Text(
                'Video load failed',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '@${widget.snap['username']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.white,
                            ),
                            onPressed: _toggleLike,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.snap['description'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(
                          (widget.snap['datePublished'] as Timestamp?)
                                  ?.toDate() ??
                              DateTime.now(),
                        ),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${(widget.snap['likes'] as List).length} likes',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${widget.snap['comments']?.length ?? 0} comments',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!_controller.value.isPlaying)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: _saveReel,
                              icon: Icon(
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isSaved ? 'Saved' : 'Save',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _shareReelToFollowers,
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: const Text(
                                'Share to followers',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReelCommentsScreen(reelId: widget.reelId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.comment),
                        label: const Text('Comments'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
