import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';

class RoomScreen extends StatefulWidget {
  final String roomName;
  final String userName;

  const RoomScreen({
    super.key,
    required this.roomName,
    required this.userName,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  Room? _room;
  bool _connecting = true;
  bool _micOn = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      // Mikrofon izni iste (Android 6+ icin sart)
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Mikrofon izni verilmedi');
      }

      final uri = Uri.parse(AppConfig.tokenEndpoint).replace(
        queryParameters: {
          'room': widget.roomName,
          'identity': widget.userName,
        },
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Token alınamadı (HTTP ${res.statusCode})');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final room = Room();

      await room.connect(AppConfig.livekitUrl, data['token'] as String);
      await room.localParticipant?.setMicrophoneEnabled(true);
      room.addListener(_onRoomChanged);

      if (!mounted) return;
      setState(() {
        _room = room;
        _micOn = true;
        _connecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleMic() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final target = !_micOn;
    await lp.setMicrophoneEnabled(target);
    setState(() => _micOn = target);
  }

  Future<void> _leave() async {
    final room = _room;
    _room = null;
    if (room != null) {
      room.removeListener(_onRoomChanged);
      await room.disconnect();
      await room.dispose();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _room?.removeListener(_onRoomChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _leave,
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _room == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'mic',
                      backgroundColor:
                          _micOn ? Colors.green : Colors.redAccent,
                      onPressed: _toggleMic,
                      child: Icon(_micOn ? Icons.mic : Icons.mic_off),
                    ),
                    FloatingActionButton(
                      heroTag: 'leave',
                      backgroundColor: Colors.red,
                      onPressed: _leave,
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _connecting = true;
                    _error = null;
                  });
                  _connect();
                },
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final room = _room;
    if (room == null) return const SizedBox.shrink();

    final participants = <Participant>[
      if (room.localParticipant != null) room.localParticipant!,
      ...room.remoteParticipants.values,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${participants.length} kişi odada',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: participants.length <= 4 ? 2 : 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: participants
                .map((p) => _PersonTile(
                      label: p.identity,
                      speaking: p.isSpeaking,
                      isLocal: p == room.localParticipant,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  final String label;
  final bool speaking;
  final bool isLocal;

  const _PersonTile({
    required this.label,
    required this.speaking,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: speaking ? Colors.greenAccent : Colors.transparent,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: Colors.deepPurpleAccent.shade100,
            child: Text(
              label.isNotEmpty ? label[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isLocal ? '$label (sen)' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
