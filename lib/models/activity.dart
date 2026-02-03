import 'package:flutter/material.dart';

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
  final String? address; // 詳細地址
  final String? region;  // 地區（例如：台北市、新北市）
  final String? status;  // 活動狀態（從後端取得）

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
    this.address,  // 可選的詳細地址欄位
    this.region,   // 可選的地區欄位
    this.status,   // 可選的狀態欄位
  });

  bool get isFull => currentParticipants >= maxParticipants;
  
  String get participantCount => '$currentParticipants/$maxParticipants';

  // 判斷活動是否進行中
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(startTime.add(const Duration(hours: 3)));
  }

  // 判斷活動是否熱門（80% 以上參與者）
  bool get isHot {
    return currentParticipants / maxParticipants >= 0.8;
  }

  // 判斷活動是否快滿（80% 以上但未滿）
  bool get isNearlyFull {
    return !isFull && (currentParticipants / maxParticipants >= 0.8);
  }

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
      address: json['address'] as String?,  // 從後端取得詳細地址
      region: json['region'] as String?,    // 從後端取得地區
      status: json['status'] as String?,    // 從後端取得狀態（ongoing, completed 等）
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
      'address': address,
      'region': region,
      'status': status,
    };
  }
  
  // 取得簡短地址（用於顯示）
  String get shortAddress {
    if (address == null || address!.isEmpty) {
      // 如果沒有地址，返回提示文字而非座標
      return '載入地址中...';
    }
    // 取地址的前 40 個字元
    return address!.length > 40 ? '${address!.substring(0, 40)}...' : address!;
  }
  
  // 取得完整地址
  String get fullAddress {
    if (address == null || address!.isEmpty) {
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
    return address!;
  }
}
