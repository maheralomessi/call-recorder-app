import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recording_model.dart';
import '../services/storage_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.callrecorder/service');

  List<RecordingModel> _recordings = [];
  bool _autoRecord = true;
  bool _isLoading = true;
  String? _playingId;
  Duration _playPos = Duration.zero;
  Duration _playTotal = Duration.zero;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.onPositionChanged.listen((p) => setState(() => _playPos = p));
    _player.onDurationChanged.listen((d) => setState(() => _playTotal = d));
    _player.onPlayerComplete.listen((_) => setState(() { _playingId = null; _playPos = Duration.zero; }));
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _loadData();
    await _setupMethodChannel();
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.notification,
    ];
    await permissions.request();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recs = await StorageService.loadRecordings();
    final auto = await StorageService.getAutoRecord();
    setState(() {
      _recordings = recs;
      _autoRecord = auto;
      _isLoading = false;
    });
  }

  Future<void> _setupMethodChannel() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewRecording') {
        await _loadData();
      }
    });
  }

  Future<void> _toggleAutoRecord(bool value) async {
    await StorageService.setAutoRecord(value);
    try {
      await _channel.invokeMethod('setAutoRecord', {'enabled': value});
    } catch (_) {}
    setState(() => _autoRecord = value);
  }

  Future<void> _playPause(RecordingModel rec) async {
    if (_playingId == rec.id) {
      await _player.pause();
      setState(() => _playingId = null);
    } else {
      if (_playingId != null) await _player.stop();
      await _player.play(DeviceFileSource(rec.filePath));
      setState(() { _playingId = rec.id; _playPos = Duration.zero; });
    }
  }

  Future<void> _deleteRecording(RecordingModel rec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3A),
        title: const Text('حذف التسجيل', style: TextStyle(color: Colors.white)),
        content: const Text('هل تريد حذف هذا التسجيل نهائياً؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      if (_playingId == rec.id) { await _player.stop(); setState(() => _playingId = null); }
      await StorageService.deleteRecording(rec);
      await _loadData();
    }
  }

  Future<void> _shareRecording(RecordingModel rec) async {
    await Share.shareXFiles([XFile(rec.filePath)], text: 'تسجيل مكالمة - ${rec.phoneNumber}');
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy – HH:mm', 'ar').format(dt);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('مسجّل المكالمات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              await _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(child: _isLoading ? _buildLoading() : _recordings.isEmpty ? _buildEmpty() : _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('تحديث', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _autoRecord
              ? [const Color(0xFF0D3B0D), const Color(0xFF1A5C1A)]
              : [const Color(0xFF2A1A1A), const Color(0xFF3B2020)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _autoRecord ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _autoRecord ? Colors.greenAccent : Colors.redAccent,
              boxShadow: [BoxShadow(color: (_autoRecord ? Colors.green : Colors.red).withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _autoRecord ? 'التسجيل التلقائي مُفعَّل' : 'التسجيل التلقائي مُعطَّل',
              style: TextStyle(color: _autoRecord ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: _autoRecord,
            onChanged: _toggleAutoRecord,
            activeColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)));

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.voicemail, size: 80, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 16),
        Text('لا توجد تسجيلات بعد', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)),
        const SizedBox(height: 8),
        Text('ستظهر التسجيلات هنا تلقائياً', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
      ],
    ),
  );

  Widget _buildList() => ListView.builder(
    padding: const EdgeInsets.only(bottom: 80),
    itemCount: _recordings.length,
    itemBuilder: (_, i) => _buildRecordingCard(_recordings[i]),
  );

  Widget _buildRecordingCard(RecordingModel rec) {
    final isPlaying = _playingId == rec.id;
    return Dismissible(
      key: Key(rec.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteRecording(rec),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying ? const Color(0xFF1A73E8).withOpacity(0.5) : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: rec.callType == 'incoming'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                child: Icon(
                  rec.callType == 'incoming' ? Icons.call_received : Icons.call_made,
                  color: rec.callType == 'incoming' ? Colors.greenAccent : Colors.blueAccent,
                  size: 20,
                ),
              ),
              title: Text(rec.phoneNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(_formatDate(rec.dateTime), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(rec.formattedDuration, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.storage_outlined, size: 12, color: Colors.white38),
                    const SizedBox(width: 4),
                    Text(rec.formattedSize, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: const Color(0xFF1A73E8), size: 36),
                    onPressed: () => _playPause(rec),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white54, size: 20),
                    onPressed: () => _shareRecording(rec),
                  ),
                ],
              ),
            ),
            if (isPlaying) _buildProgressBar(rec),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(RecordingModel rec) {
    final total = _playTotal.inMilliseconds > 0 ? _playTotal.inMilliseconds : 1;
    final progress = _playPos.inMilliseconds / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) async {
                final pos = Duration(milliseconds: (v * total).toInt());
                await _player.seek(pos);
              },
              activeColor: const Color(0xFF1A73E8),
              inactiveColor: Colors.white12,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_playPos), style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(_formatDuration(_playTotal), style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
