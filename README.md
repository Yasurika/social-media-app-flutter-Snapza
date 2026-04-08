<div align="center">

<img src="assets/Screenshot%202026-03-16%20192854.png" alt="Snapza Logo" width="140" />

# Snapza

Flutter + Firebase social media application with posts, reels, messaging, profiles, and responsive layouts.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Cloudinary](https://img.shields.io/badge/Cloudinary-Media-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

</div>

## Overview

Snapza is an Instagram-inspired social platform built with Flutter. The app combines a familiar social feed with short-form reels, profile management, comments, likes, saves, shares, direct messaging, and responsive mobile/web layouts.

This project uses Firebase for authentication and data storage, while media uploads are handled through Cloudinary.

## Highlights

| Area | Included in the project |
| --- | --- |
| Authentication | Sign up, log in, log out, persistent session via Firebase Auth |
| Social feed | Create posts, view feed, like posts, comment, delete posts |
| Reels | Upload reels, like reels, comment on reels, save and share reels |
| Profiles | User profile, bio, avatar, follower/following system |
| Messaging | One-to-one chat, reactions, seen state, delete message options |
| Discovery | Search screen and responsive navigation structure |
| Media | Image/video upload flow using Cloudinary |
| UI | Splash screen, mobile layout, web layout, dark theme base |

## Screens And Modules

- Splash screen with branded intro animation
- Login and signup flow
- Feed screen for posts
- Search screen for user/content discovery
- Add post screen
- Reels screen and reel detail flow
- Comments screens for posts and reels
- Profile screen with follow/unfollow
- Chat list and chat screen
- Voice call and video call UI screens
- Responsive mobile and web layouts

## Tech Stack

### Core

- Flutter
- Dart
- Provider

### Backend And Services

- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Storage package included in dependencies
- Cloudinary for media upload delivery

### Media And UI Packages

- image_picker
- video_player
- cached_network_image
- file_picker
- record
- audioplayers
- flutter_staggered_grid_view
- intl
- uuid

## Project Structure

```text
lib/
	main.dart
	models/           Data models for users, posts, reels, messages
	providers/        App state management
	resources/        Auth, Firestore, chat, and storage logic
	responsive/       Mobile and web layout handling
	screens/          Main UI screens
	services/         Notification-related services
	utils/            Shared constants and utility functions
	widgets/          Reusable widgets
assets/
	App branding and screenshots
android/
ios/
web/
windows/
linux/
macos/
test/
```

## Screenshot

<div align="center">
	<img src="assets/Screenshot%202026-03-16%20192854.png" alt="Snapza Preview" width="220" />
</div>

## Getting Started

### 1. Prerequisites

Make sure you have the following installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- A Firebase project
- A Cloudinary account for media uploads

Check your Flutter environment:

```bash
flutter doctor
```

### 2. Clone The Project

```bash
git clone https://github.com/your-username/social-media-app-flutter-Snapza.git
cd social-media-app-flutter-Snapza
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

This project initializes Firebase in `main.dart`, so you need valid Firebase configuration files for your own project.

- Android: place your `google-services.json` inside `android/app/`
- iOS: add your `GoogleService-Info.plist` to the Runner project
- Make sure Firebase Authentication and Cloud Firestore are enabled in the Firebase Console

### 5. Configure Cloudinary

Media uploads are handled in `lib/resources/storage_methods.dart`.

Update the Cloudinary values with your own account details if needed:

- Cloud name
- Upload preset
- Unsigned upload configuration

If uploads fail, verify that your preset is configured correctly for unsigned uploads.

### 6. Run The App

```bash
flutter run
```

For a specific device:

```bash
flutter run -d chrome
flutter run -d android
```

## Firebase Collections Used

The codebase currently works with collections such as:

- `users`
- `posts`
- `reels`
- `chat_rooms`
- `sharedPosts`
- `sharedReels`

Nested collections are used for comments, saved items, and chat messages.

## Current Notes

- The app already includes responsive layout support for mobile and web-sized screens.
- Voice call and video call screens are present as UI flows.
- The repository includes platform folders for Android, iOS, web, Windows, Linux, and macOS.
- The current theme uses a dark base with a branded splash experience.

## Why This Project Stands Out

- Clean separation between UI, providers, models, and backend logic
- Multiple social interactions in a single Flutter codebase
- Reels, chat, profile, and feed features combined in one app
- Good base project for extending into a full production-ready social platform

## Recommended Improvements

- Add real-time push notifications
- Add robust form validation and error states
- Add media compression and upload progress indicators
- Integrate real RTC for voice/video calling
- Add unit, widget, and integration tests
- Move secrets and environment-specific values into safer config handling

## Authoring Note

If you are using this repository for your portfolio or GitHub showcase, this README is structured to present the project clearly for recruiters, collaborators, and reviewers.
