import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime? endTime;              // 新增：活動結束時間
  final DateTime? registrationDeadline; // 新增：報名截止時間
  final DateTime? createdAt;            // 新增：建立時間
  final int maxParticipants;
  final int currentParticipants;
  final String category;
  final String hostId;
  final String hostName;
  final bool isBoosted;
  final String? address;
  final String? region;
  final String? status;
  final double? hostRating;             // 新增：主辦人評分
  final String? slotsInfo;              // 新增：名額資訊（例如："3/5"）
  final bool? canJoin;                  // 新增：是否可加入
  final List<String>? images;           // 新增：活動照片

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    this.endTime,
    this.registrationDeadline,
    this.createdAt,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.category,
    required this.hostId,
    required this.hostName,
    this.isBoosted = false,
    this.address,
    this.region,
    this.status,
    this.hostRating,
    this.slotsInfo,
    this.canJoin,
    this.images,
  });

  bool get isFull => currentParticipants >= maxParticipants;
  
  String get participantCount => '$currentParticipants/$maxParticipants';

  // 判斷活動是否進行中
  bool get isOngoing {
    final now = DateTime.now();
    if (endTime != null) {
      // 後端回傳的時間是 UTC 格式，但實際上是台灣本地時間（UTC+8）
      // 需要將後端時間減去 8 小時來得到真實的 UTC 時間，然後轉換為本地時間
      final startLocal = startTime.subtract(const Duration(hours: 8)).toLocal();
      final endLocal = endTime!.subtract(const Duration(hours: 8)).toLocal();
      final result = now.isAfter(startLocal) && now.isBefore(endLocal);
      print('[$title] isOngoing check: now=$now, start=$startLocal, end=$endLocal, result=$result');
      return result;
    }
    // 如果沒有結束時間，假設活動持續 3 小時
    final startLocal = startTime.subtract(const Duration(hours: 8)).toLocal();
    final estimatedEnd = startLocal.add(const Duration(hours: 3));
    final result = now.isAfter(startLocal) && now.isBefore(estimatedEnd);
    print('[$title] isOngoing check (no endTime): now=$now, start=$startLocal, estimatedEnd=$estimatedEnd, result=$result');
    return result;
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
    
    // 解析 slots_info 來取得當前參與人數（如果有的話）
    int currentParticipants = 1;
    if (json['slots_info'] != null && json['slots_info'].toString().contains('/')) {
      final parts = json['slots_info'].toString().split('/');
      if (parts.length == 2) {
        currentParticipants = int.tryParse(parts[0]) ?? 1;
      }
    } else if (json['current_participants'] != null) {
      currentParticipants = json['current_participants'] is int 
          ? json['current_participants'] as int 
          : int.tryParse(json['current_participants'].toString()) ?? 1;
    }
    
    return Activity(
      id: id?.toString() ?? 'unknown',
      title: json['title'] as String? ?? '未命名活動',
      description: json['description'] as String? ?? '',
      latitude: lat != null ? (lat as num).toDouble() : 0.0,
      longitude: lng != null ? (lng as num).toDouble() : 0.0,
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String)
          : null,
      registrationDeadline: json['registration_deadline'] != null 
          ? DateTime.parse(json['registration_deadline'] as String)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      maxParticipants: maxSlots is int ? maxSlots : (maxSlots != null ? int.tryParse(maxSlots.toString()) ?? 5 : 5),
      currentParticipants: currentParticipants,
      category: activityType as String? ?? '其他',
      hostId: json['host_id']?.toString() ?? 'unknown',
      hostName: json['host_username'] as String? ?? json['host_name'] as String? ?? '主辦人',
      isBoosted: json['is_boosted'] as bool? ?? false,
      address: json['address'] as String?,
      region: json['region'] as String?,
      status: json['status'] as String?,
      hostRating: json['host_rating'] != null ? (json['host_rating'] as num).toDouble() : null,
      slotsInfo: json['slots_info'] as String?,
      canJoin: json['can_join'] as bool?,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      if (registrationDeadline != null) 'registration_deadline': registrationDeadline!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'category': category,
      'hostId': hostId,
      'hostName': hostName,
      'isBoosted': isBoosted,
      if (address != null) 'address': address,
      if (region != null) 'region': region,
      if (status != null) 'status': status,
      if (hostRating != null) 'host_rating': hostRating,
      if (slotsInfo != null) 'slots_info': slotsInfo,
      if (canJoin != null) 'can_join': canJoin,
      if (images != null) 'images': images,
    };
  }
  
  // 取得簡短地址（用於顯示）
  String get shortAddress {
    if (address == null || address!.isEmpty) {
      return '載入地址中...';
    }
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
