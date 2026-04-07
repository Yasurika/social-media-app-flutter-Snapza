import 'package:flutter/material.dart';

class VideoCallScreen extends StatefulWidget {
  final String receiverName;
  final String receiverPic;

  const VideoCallScreen({
    super.key,
    required this.receiverName,
    required this.receiverPic,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _cameraOn = true;
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Video call with ${widget.receiverName}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(widget.receiverPic),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _cameraOn ? Icons.videocam : Icons.videocam_off,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _cameraOn = !_cameraOn),
                        iconSize: 32,
                      ),
                      const Text(
                        'Camera',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Icon(Icons.call_end),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          _muted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _muted = !_muted),
                        iconSize: 32,
                      ),
                      const Text(
                        'Mute',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
