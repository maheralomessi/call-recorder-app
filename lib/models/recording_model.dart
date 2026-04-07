class RecordingModel {
  final String id;
  final String filePath;
  final String phoneNumber;
  final DateTime dateTime;
  final int durationSeconds;
  final int fileSizeBytes;
  final String callType; // 'incoming' | 'outgoing'

  RecordingModel({
    required this.id,
    required this.filePath,
    required this.phoneNumber,
    required this.dateTime,
    required this.durationSeconds,
    required this.fileSizeBytes,
    this.callType = 'unknown',
  });

  String get formattedDuration {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get formattedSize {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'filePath': filePath,
        'phoneNumber': phoneNumber,
        'dateTime': dateTime.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
        'fileSizeBytes': fileSizeBytes,
        'callType': callType,
      };

  factory RecordingModel.fromMap(Map<String, dynamic> map) => RecordingModel(
        id: map['id'],
        filePath: map['filePath'],
        phoneNumber: map['phoneNumber'],
        dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
        durationSeconds: map['durationSeconds'],
        fileSizeBytes: map['fileSizeBytes'] ?? 0,
        callType: map['callType'] ?? 'unknown',
      );
}
