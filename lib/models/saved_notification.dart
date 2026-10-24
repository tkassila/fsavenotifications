class SavedNotification {
  final int id;
  final String key;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final DateTime postTime;
  final bool isRead;
  final DateTime? readAt;
  final bool isOngoing;

  const SavedNotification({
    required this.id,
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postTime,
    required this.isRead,
    this.readAt,
    this.isOngoing = false,
  });

  factory SavedNotification.fromMap(Map<dynamic, dynamic> map) {
    final postTimeMillis = (map['postTime'] as num?)?.toInt() ?? 0;
    final readAtMillis = (map['readAt'] as num?)?.toInt() ?? 0;

    return SavedNotification(
      id: (map['id'] as num?)?.toInt() ?? 0,
      key: map['key'] as String? ?? '',
      packageName: map['packageName'] as String? ?? 'tuntematon',
      appName: (map['appName'] as String?)?.isNotEmpty == true
          ? (map['appName'] as String)
          : (map['packageName'] as String? ?? 'Sovellus'),
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postTime: DateTime.fromMillisecondsSinceEpoch(postTimeMillis),
      isRead: map['isRead'] == true,
      readAt: readAtMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(readAtMillis)
          : null,
      isOngoing: map['isOngoing'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'packageName': packageName,
      'appName': appName,
      'title': title,
      'text': text,
      'postTime': postTime.millisecondsSinceEpoch,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch,
      'isOngoing': isOngoing,
    };
  }
}
