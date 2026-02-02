class Activity {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final int maxParticipants;
  final int currentParticipants;
  final String category;
  final String hostId;
  final String hostName;
  final bool isBoosted;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.category,
    required this.hostId,
    required this.hostName,
    this.isBoosted = false,
  });

  bool get isFull => currentParticipants >= maxParticipants;
  
  String get participantCount => '$currentParticipants/$maxParticipants';

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      startTime: DateTime.parse(json['start_time'] as String),
      maxParticipants: json['max_participants'] as int,
      currentParticipants: json['current_participants'] as int? ?? 1,
      category: json['category'] as String? ?? '其他',
      hostId: json['host_id'] as String,
      hostName: json['host_name'] as String? ?? '主辦人',
      isBoosted: json['is_boosted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'startTime': startTime.toIso8601String(),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'category': category,
      'hostId': hostId,
      'hostName': hostName,
      'isBoosted': isBoosted,
    };
  }
}
