class LocalNotificationItem {
  final String uid;
  final int? orderId;
  final String? code;
  final String? status;
  final String? title;
  final String? body;
  final String source; // pusher / fcm
  final DateTime receivedAt;
  final Map<String, dynamic> raw;
  final bool isRead;

  LocalNotificationItem({
    required this.uid,
    required this.orderId,
    required this.code,
    required this.status,
    required this.title,
    required this.body,
    required this.source,
    required this.receivedAt,
    required this.raw,
    required this.isRead,
  });

  factory LocalNotificationItem.fromJson(Map<String, dynamic> json) {
    return LocalNotificationItem(
      uid: json['uid'] as String,
      orderId: json['orderId'] as int?,
      code: json['code'] as String?,
      status: json['status'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      source: json['source'] as String? ?? 'unknown',
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      raw: Map<String, dynamic>.from(json['raw'] as Map),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'orderId': orderId,
      'code': code,
      'status': status,
      'title': title,
      'body': body,
      'source': source,
      'receivedAt': receivedAt.toIso8601String(),
      'raw': raw,
      'isRead': isRead,
    };
  }

  LocalNotificationItem copyWith({
    bool? isRead,
  }) {
    return LocalNotificationItem(
      uid: uid,
      orderId: orderId,
      code: code,
      status: status,
      title: title,
      body: body,
      source: source,
      receivedAt: receivedAt,
      raw: raw,
      isRead: isRead ?? this.isRead,
    );
  }
}