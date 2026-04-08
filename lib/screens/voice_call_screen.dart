import 'package:flutter/material.dart';

class VoiceCallScreen extends StatefulWidget {
  final String receiverName;

  const VoiceCallScreen({super.key, required this.receiverName});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _muted = false;
  bool _speakerEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Calling ${widget.receiverName}'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 32),
            Text(
              widget.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Voice call in progress',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                    const Text('Mute', style: TextStyle(color: Colors.white70)),
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
                        _speakerEnabled ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _speakerEnabled = !_speakerEnabled),
                      iconSize: 32,
                    ),
                    const Text(
                      'Speaker',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
