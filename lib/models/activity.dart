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
    // 安全地處理可能為 null 的值
    final id = json['id'];
    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    final maxSlots = json['max_slots'] ?? json['max_participants'];
    final activityType = json['activity_type'] ?? json['category'];
    
    return Activity(
      id: id?.toString() ?? 'unknown',
      title: json['title'] as String? ?? '未命名活動',
      description: json['description'] as String? ?? '',
      latitude: lat != null ? (lat as num).toDouble() : 0.0,
      longitude: lng != null ? (lng as num).toDouble() : 0.0,
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      maxParticipants: maxSlots is int ? maxSlots : (maxSlots != null ? int.tryParse(maxSlots.toString()) ?? 5 : 5),
      currentParticipants: json['current_participants'] is int 
          ? json['current_participants'] as int 
          : (json['current_participants'] != null ? int.tryParse(json['current_participants'].toString()) ?? 1 : 1),
      category: activityType as String? ?? '其他',
      hostId: json['host_id']?.toString() ?? 'unknown',
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
