## Overview
Implement user profiles, follow/unfollow system, and social graph management.

## Key Files & Line Numbers

### 1. *Profile Screen* - lib/screens/profile_screen.dart
*Responsibility*: User profile display and management

*Features*:
- User information (name, bio, profile picture)
- Statistics (posts count, followers, following)
- Follow/Unfollow button
- User's posts grid
- User's saved posts (if own profile)
- Edit profile button (if own profile)
- Sign out button (if own profile)
- Followers/Following lists

*UI Components*:
dart
// Header section:
// - Profile picture (large circle)
// - Username
// - Bio
// - Followers count
// - Following count  
// - Posts count

// Action buttons:
// - Follow/Unfollow button (if not own profile)
// - Edit Profile (if own profile)
// - Message button (if not own profile)

// Tabs:
// - Posts tab (grid of user's posts)
// - Saved posts tab (if own profile)
// - Media tab (if own profile)

// Grid display:
// - Staggered grid of post images
// - Tap to view post details


### 2. *Follow Button Widget* - lib/widgets/follow_button.dart
*Responsibility*: Reusable follow/unfollow button

*Features*:
dart
// Shows "Follow" button if not following
// Shows "Following" button if already following
// Tap button to toggle follow/unfollow
// Loading state during action
// Different styling for follow vs following state


### 3. *Firestore Methods - Social Part* - lib/resources/firestore_methods.dart

#### followUser() - Lines 292-320
dart
Future<void> followUser(String uid, String followId) async {
  try {
    // 1. Add followId to current user's following list
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
          'following': FieldValue.arrayUnion([followId]),
        });

    // 2. Add uid to followId's followers list
    await _firestore
        .collection('users')
        .doc(followId)
        .update({
          'followers': FieldValue.arrayUnion([uid]),
        });
  } catch (e) {
    print(e.toString());
  }
}


*Logic*:
- When User A follows User B:
  - Add B to A's following array
  - Add A to B's followers array
  - Both operations must succeed for consistency

#### Unfollow Pattern
dart
Future<void> unfollowUser(String uid, String unfollowId) async {
  try {
    // 1. Remove unfollowId from current user's following
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
          'following': FieldValue.arrayRemove([unfollowId]),
        });

    // 2. Remove uid from unfollowId's followers
    await _firestore
        .collection('users')
        .doc(unfollowId)
        .update({
          'followers': FieldValue.arrayRemove([uid]),
        });
  } catch (e) {
    print(e.toString());
  }
}


## Integration Points

### Check if Following
dart
// In profile screen to determine button text
bool isFollowing = _user.following.contains(targetUserId);


### Get Follower Count
dart
// In profile screen header
int followerCount = userData.followers.length;
int followingCount = userData.following.length;


### Filter User Posts
dart
// In friends feed (optional feature)
Stream<QuerySnapshot> getFriendsPost(List<String> following) {
  return _firestore
      .collection('posts')
      .where('uid', whereIn: following)
      .orderBy('datePublished', descending: true)
      .snapshots();
}


## Database Schema Updates

### Users Collection

users/
  {uid}/
    username: string
    email: string
    photoUrl: string
    bio: string
    followers: array[uids]      // Users following this user
    following: array[uids]      // Users this user follows
    savedPosts: array[postIds]  // Posts user saved
    savedReels: array[reelIds]  // Reels user saved


## Testing Checklist

### Profile Screen
- [ ] Profile picture displays correctly
- [ ] Username displays
- [ ] Bio displays
- [ ] Follower count shows correct number
- [ ] Following count shows correct number
- [ ] Posts count shows correct number
- [ ] Posts grid displays all user posts
- [ ] Can tap post to view details
- [ ] Follow button displays on other's profile
- [ ] Following button displays when already following
- [ ] Follow button works and updates UI
- [ ] Unfollow button works and updates UI
- [ ] Edit profile button shows for own profile
- [ ] Edit profile updates user data
- [ ] Sign out button shows for own profile
- [ ] Sign out clears session and routes to login
- [ ] Saved posts tab shows for own profile
- [ ] Followers list shows correct users
- [ ] Following list shows correct users

## Development Timeline
- *Day 1-2*: Profile screen UI
- *Day 3*: Follow/unfollow logic
- *Day 4*: Follow button widget
- *Day 5*: Followers/following lists
- *Day 6*: Integration with posts
- *Day 7*: Testing

---