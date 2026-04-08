import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:social_media_app/resources/chat_methods.dart';
import 'package:social_media_app/resources/storage_methods.dart';
import 'package:social_media_app/screens/video_call_screen.dart';
import 'package:social_media_app/screens/voice_call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverPic;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Record _record = Record();
  String? _playingAudioUrl;
  final Set<String> _seenMessages = {};

  bool get _voiceRecordingSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    // Mark all messages as seen when entering the chat
    _markAllMessagesAsSeen();
  }

  Future<void> _markAllMessagesAsSeen() async {
    try {
      final messages = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_getChatRoomId())
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('seenAt', isNull: true)
          .get();

      for (var doc in messages.docs) {
        await ChatMethods().markMessageAsSeen(
          userId: currentUserId,
          otherUserId: widget.receiverId,
          messageId: doc.id,
        );
      }
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  String _getChatRoomId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await ChatMethods().sendMessage(
        senderId: currentUserId,
        receiverId: widget.receiverId,
        message: _messageController.text.trim(),
        type: 'text',
      );
      _messageController.clear();
    }
  }

  Future<void> _sendMissedCallMessage(String mode) async {
    final String label = mode == 'audio' ? 'Audio call' : 'Video call';
    await ChatMethods().sendMessage(
      senderId: currentUserId,
      receiverId: widget.receiverId,
      message: '$label received',
      type: 'call',
      callMode: mode,
      callStatus: 'missed',
      attachmentName: label,
    );
  }

  Future<void> _sendMediaMessage({
    required Uint8List bytes,
    required String type,
    required String extension,
    String attachmentName = '',
  }) async {
    CloudinaryResourceType resourceType;
    String childName;

    switch (type) {
      case 'image':
        resourceType = CloudinaryResourceType.Image;
        childName = 'chat_images';
        break;
      case 'video':
        resourceType = CloudinaryResourceType.Video;
        childName = 'chat_videos';
        break;
      case 'audio':
      case 'file':
        resourceType = CloudinaryResourceType.Raw;
        childName = type == 'audio' ? 'chat_audio' : 'chat_files';
        break;
      default:
        resourceType = CloudinaryResourceType.Auto;
        childName = 'chat_files';
    }

    String url = await StorageMethods().uploadImageToStorage(
      childName,
      bytes,
      false,
      resourceType: resourceType,
      extension: extension,
    );

    await ChatMethods().sendMessage(
      senderId: currentUserId,
      receiverId: widget.receiverId,
      message: url,
      type: type,
      attachmentName: attachmentName,
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _sendMediaMessage(
      bytes: bytes,
      type: 'image',
      extension: file.path.split('.').last,
    );
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _sendMediaMessage(
      bytes: bytes,
      type: 'video',
      extension: file.path.split('.').last,
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }
    if (bytes == null) return;
    final extension = picked.extension ?? picked.name.split('.').last;
    await _sendMediaMessage(
      bytes: bytes,
      type: 'file',
      extension: extension,
      attachmentName: picked.name,
    );
  }

  Future<void> _showStickerPicker() async {
    const stickers = ['😊', '😍', '😂', '🔥', '🥳', '👍', '🎉', '❤️'];

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: stickers.map((sticker) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  ChatMethods().sendMessage(
                    senderId: currentUserId,
                    receiverId: widget.receiverId,
                    message: sticker,
                    type: 'sticker',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(sticker, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showVoiceRecorder() async {
    if (!_voiceRecordingSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice recording is not supported on this platform.'),
          ),
        );
      }
      return;
    }

    String? recordedPath;
    bool recording = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recording
                        ? 'Recording voice message'
                        : 'Record voice message',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(recording ? Icons.stop : Icons.mic),
                    label: Text(recording ? 'Stop' : 'Record'),
                    onPressed: () async {
                      try {
                        if (!recording) {
                          if (await _record.hasPermission()) {
                            final directory = await getTemporaryDirectory();
                            recordedPath =
                                '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                            await _record.start(
                              path: recordedPath,
                              encoder: AudioEncoder.AAC,
                            );
                            setState(() => recording = true);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Microphone permission is required to record voice messages.',
                                  ),
                                ),
                              );
                            }
                          }
                        } else {
                          final isRecording = await _record.isRecording();
                          if (isRecording) {
                            await _record.stop();
                          }
                          setState(() => recording = false);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Voice recording failed: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!recording && recordedPath != null)
                    ElevatedButton(
                      onPressed: () async {
                        final file = File(recordedPath!);
                        if (!await file.exists()) return;
                        final bytes = await file.readAsBytes();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        await _sendMediaMessage(
                          bytes: bytes,
                          type: 'audio',
                          extension: 'm4a',
                          attachmentName: 'Voice message',
                        );
                      },
                      child: const Text('Send Voice Message'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_playingAudioUrl == url) {
        final playbackState = _audioPlayer.state;
        if (playbackState == PlayerState.playing) {
          await _audioPlayer.pause();
          setState(() => _playingAudioUrl = null);
        } else {
          await _audioPlayer.play(UrlSource(url));
          setState(() => _playingAudioUrl = url);
        }
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() => _playingAudioUrl = url);
      }
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _playingAudioUrl = null);
      });
    } catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReactionPicker(
    String messageId,
    Map<String, String> currentReactions,
  ) {
    const reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡', '🔥', '👏'];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add a reaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...reactionEmojis.map((emoji) {
                      final userHasReacted = currentReactions.values.contains(
                        emoji,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            if (userHasReacted) {
                              ChatMethods().removeReaction(
                                userId: currentUserId,
                                otherUserId: widget.receiverId,
                                messageId: messageId,
                              );
                            } else {
                              ChatMethods().addReaction(
                                userId: currentUserId,
                                otherUserId: widget.receiverId,
                                messageId: messageId,
                                emoji: emoji,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: userHasReacted
                                  ? Colors.blue
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
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
  }

  void _showDeleteConfirmDialog(String messageId, bool isOwnMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message?'),
          content: const Text(''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                ChatMethods().deleteMessageForMe(
                  userId: currentUserId,
                  otherUserId: widget.receiverId,
                  messageId: messageId,
                );
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete for me',
                style: TextStyle(color: Colors.green),
              ),
            ),
            if (isOwnMessage)
              TextButton(
                onPressed: () {
                  ChatMethods().deleteMessageForEveryone(
                    userId: currentUserId,
                    otherUserId: widget.receiverId,
                    messageId: messageId,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete for everyone',
                  style: TextStyle(color: Colors.green),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photo from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document / file'),
              onTap: () {
                Navigator.of(context).pop();
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions),
              title: const Text('Sticker'),
              onTap: () {
                Navigator.of(context).pop();
                _showStickerPicker();
              },
            ),
            if (_voiceRecordingSupported)
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showVoiceRecorder();
                },
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _audioPlayer.dispose();
    _record.dispose();
    super.dispose();
  }

  Widget _buildMessageContent(Map<String, dynamic> data) {
    final String type = data['type'] ?? 'text';
    final String message = data['message'] ?? '';
    final String attachmentName = data['attachmentName'] ?? '';

    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => _launchUrl(message),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'video':
        return GestureDetector(
          onTap: () => _launchUrl(message),
          child: Container(
            width: 200,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        );
      case 'audio':
        final isPlaying = _playingAudioUrl == message;
        return GestureDetector(
          onTap: () => _playAudio(message),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              const Text(
                'Voice message',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      case 'file':
        return GestureDetector(
          onTap: () => _launchUrl(message),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  attachmentName.isNotEmpty ? attachmentName : 'Document',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case 'sticker':
        return Text(message, style: const TextStyle(fontSize: 36));
      case 'call':
        final String callMode = data['callMode'] ?? '';
        final String callStatus = data['callStatus'] ?? '';
        final bool missed = callStatus == 'missed';
        final String modeLabel = callMode == 'video'
            ? 'Video call'
            : 'Audio call';
        final String statusLabel = missed
            ? 'Not answered'
            : callStatus == 'answered'
            ? 'Answered'
            : 'Call initiated';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              callMode == 'video' ? Icons.videocam : Icons.call,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        );
      default:
        return Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.receiverPic),
              radius: 16,
            ),
            const SizedBox(width: 10),
            Text(widget.receiverName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () async {
              final missed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      VoiceCallScreen(receiverName: widget.receiverName),
                ),
              );
              if (missed == false) {
                await _sendMissedCallMessage('audio');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () async {
              final missed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(
                    receiverName: widget.receiverName,
                    receiverPic: widget.receiverPic,
                  ),
                ),
              );
              if (missed == false) {
                await _sendMissedCallMessage('video');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: ChatMethods().getMessages(
                currentUserId,
                widget.receiverId,
              ),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as dynamic;
                    String messageId = snapshot.data!.docs[index].id;
                    bool isMe = data['senderId'] == currentUserId;
                    bool isDeleted = data['isDeleted'] ?? false;
                    List<String> deletedForUsers = List<String>.from(
                      data['deletedForUsers'] ?? [],
                    );
                    Map<String, String> reactions = Map<String, String>.from(
                      data['reactions'] ?? {},
                    );

                    // Hide message if deleted for current user
                    if (deletedForUsers.contains(currentUserId)) {
                      return const SizedBox.shrink();
                    }

                    // Mark as seen
                    if (!isMe && data['seenAt'] == null) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (!_seenMessages.contains(messageId)) {
                          _seenMessages.add(messageId);
                          ChatMethods().markMessageAsSeen(
                            userId: currentUserId,
                            otherUserId: widget.receiverId,
                            messageId: messageId,
                          );
                        }
                      });
                    }

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          _showDeleteConfirmDialog(messageId, isMe);
                        },
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDeleted
                                    ? Colors.grey[700]
                                    : (isMe ? Colors.blue : Colors.grey[800]),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: GestureDetector(
                                onLongPress: () {
                                  if (!isDeleted) {
                                    _showReactionPicker(messageId, reactions);
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (data['type'] == 'post')
                                      const Text(
                                        "[Shared Post]",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow,
                                        ),
                                      ),
                                    if (isDeleted)
                                      Text(
                                        'This message was deleted',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else
                                      _buildMessageContent(data),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat.jm().format(
                                            (data['timestamp'] as Timestamp)
                                                .toDate(),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe && data['seenAt'] != null)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.done_all,
                                              color: Colors.white70,
                                              size: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (reactions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: reactions.entries.map((entry) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: entry.key == currentUserId
                                              ? Colors.blue.withOpacity(0.7)
                                              : Colors.grey[700],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: _voiceRecordingSupported ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _voiceRecordingSupported
                      ? _showVoiceRecorder
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
