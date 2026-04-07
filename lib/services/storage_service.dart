import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording_model.dart';

class StorageService {
  static const _recordingsKey = 'recordings_list';

  static Future<Directory> getRecordingsDir() async {
    final external = await getExternalStorageDirectory();
    final dir = Directory('${external!.path}/CallRecordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<List<RecordingModel>> loadRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_recordingsKey) ?? [];
    final recordings = <RecordingModel>[];
    for (final json in jsonList) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final rec = RecordingModel.fromMap(map);
        if (await File(rec.filePath).exists()) recordings.add(rec);
      } catch (_) {}
    }
    recordings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return recordings;
  }

  static Future<void> saveRecording(RecordingModel rec) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_recordingsKey) ?? [];
    existing.add(jsonEncode(rec.toMap()));
    await prefs.setStringList(_recordingsKey, existing);
  }

  static Future<void> deleteRecording(RecordingModel rec) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_recordingsKey) ?? [];
    existing.removeWhere((j) {
      try {
        return (jsonDecode(j) as Map)['id'] == rec.id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_recordingsKey, existing);
    final file = File(rec.filePath);
    if (await file.exists()) await file.delete();
  }

  static Future<int> getTotalSize() async {
    final dir = await getRecordingsDir();
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  static Future<bool> getAutoRecord() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_record') ?? true;
  }

  static Future<void> setAutoRecord(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_record', value);
  }

  static Future<String> getQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('quality') ?? 'high';
  }

  static Future<void> setQuality(String q) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quality', q);
  }
}
