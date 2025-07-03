import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final int uid;

  const VoiceCallScreen({required this.channelName, required this.uid, Key? key}) : super(key: key);

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late final RtcEngine _engine;
  bool _isMuted = false; // لحالة كتم الصوت

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "b3d56b4643a84779bd9a126c4a3b010d"));

    await _engine.enableAudio();
    await _engine.joinChannel(
      token: "", // استخدم التوكن المناسب إذا كنت بحاجة إليه
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _engine.muteLocalAudioStream(_isMuted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ صورة المتصل
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage("https://images.ctfassets.net/ihx0a8chifpc/gPyHKDGI0md4NkRDjs4k8/36be1e73008a0181c1980f727f29d002/avatar-placeholder-generator-500x500.jpg?w=1920&q=60&fm=webp"), // استبدلها بصورة المتصل الفعلية
          ),
          SizedBox(height: 20),
          Text(
            "المكالمة جارية...",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 30),

          // ✅ أزرار التحكم بالمكالمة
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔇 زر كتم الصوت
              FloatingActionButton(
                heroTag: "mute",
                onPressed: _toggleMute,
                backgroundColor: _isMuted ? Colors.red : Colors.grey,
                child: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
              ),
              SizedBox(width: 20),

              // ❌ زر إنهاء المكالمة
              FloatingActionButton(
                heroTag: "endCall",
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.red,
                child: Icon(Icons.call_end, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
