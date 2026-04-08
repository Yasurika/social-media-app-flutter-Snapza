import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/resources/auth_methods.dart';
import 'package:social_media_app/resources/firestore_methods.dart';
import 'package:social_media_app/resources/storage_methods.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:social_media_app/screens/reel_detail_screen.dart';
import 'package:social_media_app/utils/utils.dart';
import 'package:social_media_app/widgets/follow_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int reelLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;
  int _selectedTab = 0; // 0=posts,1=reels,2=shared,3=saved

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      var postSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();

      var reelSnap = await FirebaseFirestore.instance
          .collection('reels')
          .where('uid', isEqualTo: widget.uid)
          .get();

      postLen = postSnap.docs.length;
      reelLen = reelSnap.docs.length;
      userData = userSnap.data()!;
      followers = userSnap.data()!['followers'].length;
      following = userSnap.data()!['following'].length;
      isFollowing = userSnap.data()!['followers'].contains(
        FirebaseAuth.instance.currentUser!.uid,
      );
      setState(() {});
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
    setState(() {
      isLoading = false;
    });
  }

  void editProfileImage() async {
    Uint8List? im = await pickImage(ImageSource.gallery);
    if (im != null) {
      setState(() {
        isLoading = true;
      });
      String photoUrl = await StorageMethods().uploadImageToStorage(
        'profilePics',
        im,
        false,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'photoUrl': photoUrl});

      getData(); // Refresh data
    }
  }

  void editProfile() {
    final TextEditingController usernameController = TextEditingController(
      text: userData['username'] ?? '',
    );
    final TextEditingController bioController = TextEditingController(
      text: userData['bio'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({
                    'username': usernameController.text.trim(),
                    'bio': bioController.text.trim(),
                  });
              Navigator.pop(context);
              getData(); // Refresh data
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(userData['username'] ?? ''),
              centerTitle: false,
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey,
                                backgroundImage: NetworkImage(
                                  userData['photoUrl'] ??
                                      'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg',
                                ),
                                radius: 40,
                              ),
                              if (FirebaseAuth.instance.currentUser!.uid ==
                                  widget.uid)
                                Positioned(
                                  bottom: -10,
                                  left: 45,
                                  child: IconButton(
                                    onPressed: editProfileImage,
                                    icon: const Icon(
                                      Icons.add_a_photo,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Flexible(
                                      child: buildStatColumn(postLen, "posts"),
                                    ),
                                    Flexible(
                                      child: buildStatColumn(reelLen, "reels"),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showUserList('followers'),
                                      child: Flexible(
                                        child: buildStatColumn(
                                          followers,
                                          "followers",
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showUserList('following'),
                                      child: Flexible(
                                        child: buildStatColumn(
                                          following,
                                          "following",
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid ==
                                        widget.uid) ...[
                                      Flexible(
                                        child: FollowButton(
                                          text: 'Edit profile',
                                          backgroundColor: Colors.white,
                                          textColor: Colors.black,
                                          borderColor: Colors.grey,
                                          function: () {
                                            editProfile();
                                          },
                                        ),
                                      ),
                                      Flexible(
                                        child: FollowButton(
                                          text: 'Share profile',
                                          backgroundColor: Colors.white,
                                          textColor: Colors.black,
                                          borderColor: Colors.grey,
                                          function: () {
                                            // profile share is app-specific; placeholder
                                            showSnackBar(
                                              'Share profile link copied',
                                              context,
                                            );
                                          },
                                        ),
                                      ),
                                      Flexible(
                                        child: FollowButton(
                                          text: 'Sign out',
                                          backgroundColor: Colors.red,
                                          textColor: Colors.white,
                                          borderColor: Colors.red,
                                          function: () async {
                                            await AuthMethods().signOut();
                                            if (!mounted) return;
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ] else if (isFollowing) ...[
                                      Flexible(
                                        child: FollowButton(
                                          text: 'Unfollow',
                                          backgroundColor: Colors.white,
                                          textColor: Colors.black,
                                          borderColor: Colors.grey,
                                          function: () async {
                                            await FirestoreMethods().followUser(
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid,
                                              userData['uid'],
                                            );
                                            setState(() {
                                              isFollowing = false;
                                              followers--;
                                            });
                                          },
                                        ),
                                      ),
                                    ] else ...[
                                      Flexible(
                                        child: FollowButton(
                                          text: 'Follow',
                                          backgroundColor: Colors.blue,
                                          textColor: Colors.white,
                                          borderColor: Colors.blue,
                                          function: () async {
                                            await FirestoreMethods().followUser(
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid,
                                              userData['uid'],
                                            );
                                            setState(() {
                                              isFollowing = true;
                                              followers++;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 15),
                        child: Text(
                          userData['username'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(userData['bio'] ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.grid_on,
                        color: _selectedTab == 0 ? Colors.black : Colors.grey,
                      ),
                      onPressed: () => setState(() => _selectedTab = 0),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.play_circle_outline,
                        color: _selectedTab == 1 ? Colors.black : Colors.grey,
                      ),
                      onPressed: () => setState(() => _selectedTab = 1),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.sync_alt,
                        color: _selectedTab == 2 ? Colors.black : Colors.grey,
                      ),
                      onPressed: () => setState(() => _selectedTab = 2),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.bookmark_border,
                        color: _selectedTab == 3 ? Colors.black : Colors.grey,
                      ),
                      onPressed: () => setState(() => _selectedTab = 3),
                    ),
                  ],
                ),
                const Divider(),
                buildTabContent(),
              ],
            ),
          );
  }

  // helper for tab content is below

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Future<List<DocumentSnapshot>> _fetchUsersByIds(List<dynamic> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    final users = await Future.wait(
      ids.map((id) async {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id.toString())
            .get();
        return doc;
      }),
    );
    return users.where((doc) => doc.exists).toList();
  }

  void _showUserList(String listType) {
    final List<dynamic> ids = userData[listType] ?? [];
    final String title = listType == 'followers' ? 'Followers' : 'Following';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (ids.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No $title yet',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ] else ...[
                  FutureBuilder<List<DocumentSnapshot>>(
                    future: _fetchUsersByIds(ids),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final users = snapshot.data!;
                      if (users.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No $title found',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final userDoc = users[index];
                          final userId = userDoc.id;
                          return ListTile(
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProfileScreen(uid: userId),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                userDoc['photoUrl'] ??
                                    'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg',
                              ),
                            ),
                            title: Text(userDoc['username'] ?? 'Unknown'),
                            subtitle: Text(userDoc['bio'] ?? ''),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPostsTab();
      case 1:
        return _buildReelsTab();
      case 2:
        return _buildSharedTab();
      case 3:
        return _buildSavedTab();
      default:
        return _buildPostsTab();
    }
  }

  Widget _buildPostsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Posts', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('posts')
              .where('uid', isEqualTo: widget.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = (snapshot.data! as dynamic).docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No Posts Yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 1.5,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                var snap = docs[index];
                return Image.network(snap['postUrl'], fit: BoxFit.cover);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReelsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Reels', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('reels')
              .where('uid', isEqualTo: widget.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = (snapshot.data! as dynamic).docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No Reels Yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 1.5,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final snap = docs[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => ReelDetailScreen(
                              reelId: snap.id,
                              snap: snap.data() as Map<String, dynamic>,
                            ),
                          ),
                        )
                        .then((_) => getData());
                  },
                  child: Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSharedTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Shared Reels',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('sharedReels')
              .where('fromUid', isEqualTo: widget.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = (snapshot.data! as dynamic).docs;
            docs.sort((a, b) {
              final aTimestamp = a['sharedAt'] as Timestamp?;
              final bTimestamp = b['sharedAt'] as Timestamp?;
              if (aTimestamp == null || bTimestamp == null) {
                return 0;
              }
              return bTimestamp.compareTo(aTimestamp);
            });

            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No shared videos yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 1.5,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final reelId = doc['reelId'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('reels')
                      .doc(reelId)
                      .get(),
                  builder: (context, reelSnapshot) {
                    if (reelSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container(
                        color: Colors.black,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!reelSnapshot.hasData || !reelSnapshot.data!.exists) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      );
                    }

                    final reelData =
                        reelSnapshot.data!.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) => ReelDetailScreen(
                                  reelId: reelId,
                                  snap: reelData,
                                ),
                              ),
                            )
                            .then((_) => getData());
                      },
                      child: Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saved Posts Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Saved Posts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.uid)
                .collection('savedPosts')
                .orderBy('savedAt', descending: true)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final savedPosts = (snapshot.data! as dynamic).docs;
              if (savedPosts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No Saved Posts',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: savedPosts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final savedPost = savedPosts[index];
                  final postId = savedPost.id;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(postId)
                        .get(),
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      }

                      final postData =
                          postSnapshot.data!.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          // Navigate to post detail if needed
                        },
                        child: Container(
                          color: Colors.grey[300],
                          child: Image.network(
                            postData['postUrl'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          // Saved Reels Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Saved Reels',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.uid)
                .collection('savedReels')
                .orderBy('savedAt', descending: true)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final savedDocs = (snapshot.data! as dynamic).docs;
              if (savedDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No Saved Reels',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: savedDocs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final savedDoc = savedDocs[index];
                  final reelId = savedDoc.id;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('reels')
                        .doc(reelId)
                        .get(),
                    builder: (context, reelSnapshot) {
                      if (reelSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!reelSnapshot.hasData || !reelSnapshot.data!.exists) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      }

                      final reelData =
                          reelSnapshot.data!.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => ReelDetailScreen(
                                    reelId: reelId,
                                    snap: reelData,
                                  ),
                                ),
                              )
                              .then((_) => getData());
                        },
                        child: Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(
                              Icons.bookmark,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
