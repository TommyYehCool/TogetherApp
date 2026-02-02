import 'package:dio/dio.dart';
import '../models/activity.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;
  String? _authToken;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? 'https://helpful-noticeably-bullfrog.ngrok-free.app',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    // 設定攔截器，自動加入 Token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
    ));
  }

  // 設定認證 Token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // 取得附近活動
  Future<List<Activity>> getNearbyActivities({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/activities/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radiusMeters,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Activity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('API 錯誤，使用 Mock 資料: $e');
      // API 未就緒時返回 Mock 資料
      return _getMockActivities(latitude, longitude);
    }
  }

  // 建立新活動
  Future<Activity?> createActivity({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required DateTime startTime,
    required int maxParticipants,
    required String category,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/activities/',
        data: {
          'title': title,
          'description': description,
          'start_time': startTime.toIso8601String(),
          'max_participants': maxParticipants,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Activity.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('建立活動失敗，使用 Mock 模式: $e');
      
      // API 失敗時，建立 Mock 活動
      return Activity(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        startTime: startTime,
        maxParticipants: maxParticipants,
        currentParticipants: 1,
        category: category,
        hostId: 'mock_user',
        hostName: '我',
        isBoosted: false,
      );
    }
  }

  // 加入活動
  Future<bool> joinActivity(String activityId) async {
    try {
      final response = await _dio.post('$baseUrl/activities/$activityId/join');
      return response.statusCode == 200;
    } catch (e) {
      print('加入活動失敗，使用 Mock 模式: $e');
      // Mock 模式下直接返回成功
      return true;
    }
  }

  // 取得活動的加入請求（Host 專用）
  Future<List<Map<String, dynamic>>> getActivityRequests(String activityId) async {
    try {
      final response = await _dio.get('$baseUrl/activities/$activityId/requests');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      print('取得請求失敗: $e');
      return [];
    }
  }

  // 批准加入請求（Host 專用）
  Future<bool> approveJoinRequest(String requestId) async {
    try {
      final response = await _dio.put('$baseUrl/activities/requests/$requestId/approve');
      return response.statusCode == 200;
    } catch (e) {
      print('批准請求失敗: $e');
      return false;
    }
  }

  // 評分活動
  Future<bool> rateActivity(String activityId, int score, String comment) async {
    try {
      final response = await _dio.post(
        '$baseUrl/activities/$activityId/rate',
        data: {
          'score': score,
          'comment': comment,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('評分失敗: $e');
      return false;
    }
  }

  // Boost 活動
  Future<bool> boostActivity(String activityId) async {
    try {
      final response = await _dio.post('$baseUrl/activities/$activityId/mock-boost');
      return response.statusCode == 200;
    } catch (e) {
      print('Boost 失敗: $e');
      return false;
    }
  }

  // 取得使用者主辦的活動
  Future<List<Activity>> getUserHostedActivities() async {
    try {
      final response = await _dio.get('$baseUrl/users/me/hosted');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Activity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('取得主辦活動失敗: $e');
      return [];
    }
  }

  // 取得使用者參加的活動
  Future<List<Activity>> getUserJoinedActivities() async {
    try {
      final response = await _dio.get('$baseUrl/users/me/joined');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Activity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('取得參加活動失敗: $e');
      return [];
    }
  }

  // Mock 資料（用於開發測試）
  List<Activity> _getMockActivities(double lat, double lng) {
    return [
      Activity(
        id: '1',
        title: '咖啡廳讀書會',
        description: '一起來咖啡廳讀書吧！歡迎帶自己的書',
        latitude: lat + 0.005,
        longitude: lng + 0.005,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        maxParticipants: 5,
        currentParticipants: 3,
        category: '學習',
        hostId: 'user1',
        hostName: '小明',
        isBoosted: true,
      ),
      Activity(
        id: '2',
        title: '籃球鬥牛',
        description: '缺 2 人打全場',
        latitude: lat - 0.008,
        longitude: lng + 0.003,
        startTime: DateTime.now().add(const Duration(hours: 1)),
        maxParticipants: 6,
        currentParticipants: 4,
        category: '運動',
        hostId: 'user2',
        hostName: '阿傑',
      ),
      Activity(
        id: '3',
        title: '夜市美食團',
        description: '一起逛夜市吃美食',
        latitude: lat + 0.003,
        longitude: lng - 0.007,
        startTime: DateTime.now().add(const Duration(hours: 3)),
        maxParticipants: 8,
        currentParticipants: 8,
        category: '美食',
        hostId: 'user3',
        hostName: '小華',
      ),
    ];
  }
}
