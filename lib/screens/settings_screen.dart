import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoRecord = true;
  String _quality = 'high';
  int _totalSize = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auto = await StorageService.getAutoRecord();
    final q = await StorageService.getQuality();
    final size = await StorageService.getTotalSize();
    setState(() { _autoRecord = auto; _quality = q; _totalSize = size; _loading = false; });
  }

  String get _sizeLabel {
    if (_totalSize < 1024 * 1024) return '${(_totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(_totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3A),
        title: const Text('حذف جميع التسجيلات', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم حذف كل التسجيلات المحفوظة نهائياً. هل أنت متأكد؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final dir = await StorageService.getRecordingsDir();
      await for (final f in dir.list()) { if (f is File) await f.delete(); }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('التسجيل', [
                  _switchTile(
                    icon: Icons.fiber_manual_record,
                    iconColor: Colors.redAccent,
                    title: 'التسجيل التلقائي',
                    subtitle: 'تسجيل جميع المكالمات تلقائياً',
                    value: _autoRecord,
                    onChanged: (v) async {
                      await StorageService.setAutoRecord(v);
                      setState(() => _autoRecord = v);
                    },
                  ),
                  _divider(),
                  _dropdownTile(
                    icon: Icons.high_quality,
                    iconColor: Colors.blueAccent,
                    title: 'جودة التسجيل',
                    value: _quality,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('منخفضة – 64 kbps', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'medium', child: Text('متوسطة – 96 kbps', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'high', child: Text('عالية – 128 kbps', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (v) async {
                      if (v != null) { await StorageService.setQuality(v); setState(() => _quality = v); }
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _section('التخزين', [
                  _infoTile(icon: Icons.folder_outlined, iconColor: Colors.orangeAccent,
                      title: 'حجم التسجيلات', value: _sizeLabel),
                  _divider(),
                  _actionTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: Colors.redAccent,
                    title: 'حذف جميع التسجيلات',
                    subtitle: 'مسح كل الملفات المحفوظة',
                    onTap: _clearAll,
                  ),
                ]),
                const SizedBox(height: 16),
                _section('حول التطبيق', [
                  _infoTile(icon: Icons.info_outline, iconColor: Colors.purpleAccent,
                      title: 'الإصدار', value: '1.0.0'),
                  _divider(),
                  _infoTile(icon: Icons.android, iconColor: Colors.greenAccent,
                      title: 'يدعم أندرويد', value: '8.0+'),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2840),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ملاحظة: قد تحتاج صلاحية "التراكب فوق التطبيقات" على بعض الأجهزة لضمان عمل التسجيل في الخلفية.',
                          style: TextStyle(color: Colors.yellow, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      ),
    ],
  );

  Widget _divider() => const Divider(color: Colors.white10, height: 1, indent: 56);

  Widget _switchTile({required IconData icon, required Color iconColor, required String title,
      required String subtitle, required bool value, required ValueChanged<bool> onChanged}) =>
      ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF1A73E8)),
      );

  Widget _dropdownTile<T>({required IconData icon, required Color iconColor, required String title,
      required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) =>
      ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1A2840),
          underline: const SizedBox(),
        ),
      );

  Widget _infoTile({required IconData icon, required Color iconColor,
      required String title, required String value}) =>
      ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(value, style: const TextStyle(color: Colors.white54)),
      );

  Widget _actionTile({required IconData icon, required Color iconColor, required String title,
      required String subtitle, required VoidCallback onTap}) =>
      ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      );
}
