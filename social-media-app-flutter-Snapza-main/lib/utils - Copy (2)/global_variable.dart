import 'package:flutter/material.dart';
import 'package:social_media_app/screens/feed_screen.dart';
import 'package:social_media_app/screens/search_screen.dart';
import 'package:social_media_app/screens/add_post_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/screens/reels_screen.dart';

const webScreenSize = 600;

List<Widget> homeScreenItems(String uid) => [
      const FeedScreen(),
      const SearchScreen(),
      const AddPostScreen(),
      const ReelsScreen(),
      ProfileScreen(
        uid: uid,
      ),
    ];
