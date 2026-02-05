import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // 新增：用於 MediaType
import 'package:geocoding/geocoding.dart';
import '../models/activity.dart';
import '../config/env_config.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;
  String? _authToken;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? EnvConfig.apiBaseUrl,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    // 使用環境變數中的開發 Token（如果有設定）
    _authToken = EnvConfig.devBearerToken.isNotEmpty 
        ? EnvConfig.devBearerToken 
        : '';
    
    // 設定攔截器，自動加入 Token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 如果有 Token 就加入 Authorization header
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_authToken';
          print('使用 Token: ${_authToken!.substring(0, 20)}...');
        } else {
          print('警告: 沒有設定 Token，API 可能會失敗');
        }
        // 加入 ngrok 需要的 header（如果使用 ngrok）
        options.headers['ngrok-skip-browser-warning'] = 'true';
        print('API 請求: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('API 回應: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('API 錯誤: ${error.message}');
        if (error.response != null) {
          print('狀態碼: ${error.response?.statusCode}');
          print('回應: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
  }

  // 設定認證 Token
  void setAuthToken(String token) {
    _authToken = token;
    print('Token 已設定: ${token.substring(0, 10)}...');
  }

  // 清除 Token
  void clearAuthToken() {
    _authToken = null;
    print('Token 已清除');
  }

  // 取得當前 Token
  String? get currentToken => _authToken;

  // 取得附近活動
  Future<List<Activity>> getNearbyActivities({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
  }) async {
    try {
      print('\n========== 取得附近活動 ==========');
      print('位置: ($latitude, $longitude)');
      print('範圍: $radiusMeters 公尺');
      
      final response = await _dio.get(
        '$baseUrl/activities/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius_meters': radiusMeters,
        },
      );

      print('附近活動回應狀態: ${response.statusCode}');
      print('附近活動回應資料: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('找到 ${data.length} 個附近活動');
        
        final activities = <Activity>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final activity = Activity.fromJson(data[i]);
            
            // 如果活動沒有地址，嘗試取得地址
            if (activity.address == null || activity.address!.isEmpty) {
              try {
                final placemarks = await placemarkFromCoordinates(
                  activity.latitude,
                  activity.longitude,
                );
                
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  String address = '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''}'.trim();
                  if (address.isEmpty) {
                    address = '${place.country ?? ''} ${place.administrativeArea ?? ''}'.trim();
                  }
                  
                  // 創建新的 Activity 實例包含地址
                  final enrichedActivity = Activity(
                    id: activity.id,
                    title: activity.title,
                    description: activity.description,
                    latitude: activity.latitude,
                    longitude: activity.longitude,
                    startTime: activity.startTime,
                    maxParticipants: activity.maxParticipants,
                    currentParticipants: activity.currentParticipants,
                    category: activity.category,
                    hostId: activity.hostId,
                    hostName: activity.hostName,
                    isBoosted: activity.isBoosted,
                    address: address,
                  );
                  activities.add(enrichedActivity);
                  print('  [$i] ${activity.title} at $address');
                  continue;
                }
              } catch (e) {
                print('  [$i] 取得地址失敗: $e');
              }
            }
            
            activities.add(activity);
            print('  [$i] ${activity.title} at (${activity.latitude}, ${activity.longitude})');
          } catch (e) {
            print('  [$i] 解析失敗: $e');
            print('  原始資料: ${data[i]}');
          }
        }
        
        print('成功解析 ${activities.length} 個活動');
        print('========== 取得完成 ==========\n');
        return activities;
      }
      return [];
    } catch (e) {
      print('❌ API 錯誤: $e');
      if (e is DioException && e.response != null) {
        print('錯誤回應: ${e.response?.data}');
      }
      print('使用 Mock 資料');
      print('========== 使用 Mock ==========\n');
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
    required int maxParticipants,
    required String activityType,
    required String region,
    required String address,
    required DateTime startTime,
    required DateTime endTime,
    DateTime? registrationDeadline,
    List<String>? imagePaths, // 新增：照片路徑列表（選填，最多 3 張）
  }) async {
    print('\n========== 建立活動開始 ==========');
    print('Token 狀態: ${_authToken != null && _authToken!.isNotEmpty ? "已設定" : "未設定"}');
    print('照片數量: ${imagePaths?.length ?? 0}');
    
    try {
      // 準備活動資料
      final activityData = {
        'title': title,
        'description': description,
        'lat': latitude,
        'lng': longitude,
        'max_slots': maxParticipants,
        'activity_type': activityType,
        'region': region,
        'address': address,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };
      
      if (registrationDeadline != null) {
        activityData['registration_deadline'] = registrationDeadline.toIso8601String();
      }

      print('建立活動 API 請求:');
      print('URL: $baseUrl/activities/');
      print('Activity Data: $activityData');
      
      // 使用 multipart/form-data 格式（根據 OpenAPI 規格）
      print('使用 multipart/form-data 格式');
      
      final formData = FormData();
      
      // 添加活動資料作為 JSON 字串
      final activityJson = jsonEncode(activityData);
      print('Activity JSON: $activityJson');
      
      // 嘗試使用 MultipartFile.fromString 來傳遞 JSON
      formData.files.add(MapEntry(
        'activity',
        MultipartFile.fromString(
          activityJson,
          contentType: MediaType('application', 'json'),
        ),
      ));
      
      // 添加照片檔案（如果有）
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (var i = 0; i < imagePaths.length && i < 3; i++) {
          final path = imagePaths[i];
          print('添加照片 ${i + 1}: $path');
          
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(
              path,
              filename: 'activity_image_$i.jpg',
            ),
          ));
        }
      }
      
      final response = await _dio.post(
        '$baseUrl/activities/',
        data: formData,
      );
      
      print('✅ 建立活動回應: ${response.statusCode}');
      print('回應資料: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final activity = Activity.fromJson(response.data);
        print('活動建立成功');
        print('========== 建立活動成功 ==========\n');
        return activity;
      }
      
      return null;
    } catch (e) {
      print('\n❌ 建立活動失敗: $e');
      if (e is DioException) {
        print('錯誤類型: ${e.type}');
        print('錯誤訊息: ${e.message}');
        if (e.response != null) {
          print('回應狀態碼: ${e.response?.statusCode}');
          print('回應資料: ${e.response?.data}');
        } else {
          print('⚠️ 沒有收到伺服器回應 - 可能是網路問題或 CORS 錯誤');
        }
      }
      print('========== 使用 Mock 資料 ==========\n');
      
      // API 失敗時，建立 Mock 活動
      return Activity(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        startTime: startTime,
        endTime: endTime,
        registrationDeadline: registrationDeadline,
        maxParticipants: maxParticipants,
        currentParticipants: 1,
        category: activityType,
        hostId: 'mock_user',
        hostName: '我',
        isBoosted: false,
        address: address,
        region: region,
      );
    }
  }

  // 搜尋活動
  Future<List<Activity>> searchActivities({
    String? query,
    String? region,          // 新增：地區篩選
    String? activityType,
    bool onlyAvailable = true,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('\n========== 搜尋活動 ==========');
      print('關鍵字: $query');
      print('地區: $region');
      print('類型: $activityType');
      print('只顯示可參加: $onlyAvailable');
      
      final response = await _dio.get(
        '$baseUrl/activities/search',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (region != null && region.isNotEmpty) 'region': region,
          if (activityType != null && activityType.isNotEmpty) 'activity_type': activityType,
          'only_available': onlyAvailable,
          'limit': limit,
          'offset': offset,
        },
      );

      print('搜尋回應狀態: ${response.statusCode}');
      print('搜尋回應資料: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('找到 ${data.length} 個活動');
        
        final activities = <Activity>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final activity = Activity.fromJson(data[i]);
            
            // 如果活動沒有地址，嘗試取得地址
            if (activity.address == null || activity.address!.isEmpty) {
              try {
                final placemarks = await placemarkFromCoordinates(
                  activity.latitude,
                  activity.longitude,
                );
                
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  String address = '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''}'.trim();
                  if (address.isEmpty) {
                    address = '${place.country ?? ''} ${place.administrativeArea ?? ''}'.trim();
                  }
                  
                  // 創建新的 Activity 實例包含地址
                  final enrichedActivity = Activity(
                    id: activity.id,
                    title: activity.title,
                    description: activity.description,
                    latitude: activity.latitude,
                    longitude: activity.longitude,
                    startTime: activity.startTime,
                    maxParticipants: activity.maxParticipants,
                    currentParticipants: activity.currentParticipants,
                    category: activity.category,
                    hostId: activity.hostId,
                    hostName: activity.hostName,
                    isBoosted: activity.isBoosted,
                    address: address,
                  );
                  activities.add(enrichedActivity);
                  print('  [$i] ${activity.title} - ${activity.category} at $address');
                  continue;
                }
              } catch (e) {
                print('  [$i] 取得地址失敗: $e');
              }
            }
            
            activities.add(activity);
            print('  [$i] ${activity.title} - ${activity.category}');
          } catch (e) {
            print('  [$i] 解析失敗: $e');
            print('  原始資料: ${data[i]}');
          }
        }
        
        print('成功解析 ${activities.length} 個活動');
        print('========== 搜尋完成 ==========\n');
        return activities;
      }
      return [];
    } catch (e) {
      print('❌ 搜尋活動失敗: $e');
      if (e is DioException && e.response != null) {
        print('錯誤回應: ${e.response?.data}');
      }
      print('========== 搜尋失敗 ==========\n');
      return [];
    }
  }
  // 申請加入活動
  Future<Map<String, dynamic>> joinActivity(String activityId) async {
    try {
      print('\n========== 申請加入活動 ==========');
      print('活動 ID: $activityId');
      print('Token: ${_authToken != null && _authToken!.isNotEmpty ? "已設定" : "未設定"}');
      
      final response = await _dio.post('$baseUrl/activities/$activityId/join');
      
      print('申請回應狀態: ${response.statusCode}');
      print('申請回應資料: ${response.data}');
      print('========== 申請完成 ==========\n');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? '申請成功',
          'data': response.data,
        };
      }
      
      return {
        'success': false,
        'message': '申請失敗',
      };
    } catch (e) {
      print('❌ 申請加入活動失敗: $e');
      if (e is DioException && e.response != null) {
        print('錯誤狀態碼: ${e.response?.statusCode}');
        print('錯誤回應: ${e.response?.data}');
        
        // 處理特定錯誤
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          return {
            'success': false,
            'message': errorData['detail'],
          };
        }
      }
      print('========== 申請失敗 ==========\n');
      
      return {
        'success': false,
        'message': '申請失敗，請稍後再試',
      };
    }
  }

  // 取得活動的加入請求（Host 專用）
  Future<List<Map<String, dynamic>>> getActivityRequests(int activityId) async {
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
  Future<bool> approveJoinRequest(int requestId) async {
    try {
      final response = await _dio.put('$baseUrl/activities/requests/$requestId/approve');
      return response.statusCode == 200;
    } catch (e) {
      print('批准請求失敗: $e');
      return false;
    }
  }

  // 評分活動（只需要 score，不需要 comment）
  Future<bool> rateActivity(int activityId, int score) async {
    try {
      final response = await _dio.post(
        '$baseUrl/activities/$activityId/rate',
        data: {
          'score': score,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('評分失敗: $e');
      return false;
    }
  }

  // Boost 活動
  Future<bool> boostActivity(int activityId, {int days = 1}) async {
    try {
      final response = await _dio.post(
        '$baseUrl/activities/$activityId/mock-boost',
        queryParameters: {
          'days': days,
        },
      );
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

  // 上傳活動照片（最多3張）
  Future<Map<String, dynamic>> uploadActivityImages(String activityId, List<String> imagePaths) async {
    try {
      print('\n========== 上傳活動照片 ==========');
      print('活動 ID: $activityId');
      print('照片數量: ${imagePaths.length}');
      
      if (imagePaths.isEmpty) {
        return {
          'success': false,
          'message': '請選擇至少一張照片',
        };
      }
      
      if (imagePaths.length > 3) {
        return {
          'success': false,
          'message': '最多只能上傳 3 張照片',
        };
      }
      
      // 將 String ID 轉換為 int（後端 API 要求 int 類型）
      final activityIdInt = int.tryParse(activityId);
      if (activityIdInt == null) {
        print('❌ 活動 ID 格式錯誤: $activityId');
        return {
          'success': false,
          'message': '活動 ID 格式錯誤',
        };
      }
      
      print('轉換後的活動 ID (int): $activityIdInt');
      
      // 準備 multipart 表單
      final formData = FormData();
      
      // Web 平台需要使用不同的方式處理檔案
      for (var i = 0; i < imagePaths.length; i++) {
        try {
          // 檢查是否為 Web 平台的 blob URL
          if (imagePaths[i].startsWith('blob:')) {
            print('檢測到 Web 平台 blob URL: ${imagePaths[i]}');
            return {
              'success': false,
              'message': 'Web 平台暫不支援照片上傳，請使用 App 版本',
            };
          }
          
          // 對於非 Web 平台，使用 fromFile
          final file = await MultipartFile.fromFile(
            imagePaths[i],
            filename: 'image_$i.jpg',
          );
          formData.files.add(MapEntry('files', file));
          print('添加照片 $i: ${imagePaths[i]}');
        } catch (e) {
          print('❌ 處理照片 $i 失敗: $e');
          return {
            'success': false,
            'message': 'Web 平台暫不支援照片上傳，請使用 App 版本',
          };
        }
      }
      
      final response = await _dio.post(
        '$baseUrl/activities/$activityIdInt/upload-images',
        data: formData,
      );
      
      print('上傳回應狀態: ${response.statusCode}');
      print('上傳回應資料: ${response.data}');
      print('========== 上傳完成 ==========\n');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? '照片上傳成功',
          'data': response.data,
        };
      }
      
      return {
        'success': false,
        'message': '上傳失敗',
      };
    } catch (e) {
      print('❌ 上傳活動照片失敗: $e');
      if (e is DioException && e.response != null) {
        print('錯誤狀態碼: ${e.response?.statusCode}');
        print('錯誤回應: ${e.response?.data}');
        
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          return {
            'success': false,
            'message': errorData['detail'],
          };
        }
      }
      print('========== 上傳失敗 ==========\n');
      
      return {
        'success': false,
        'message': 'Web 平台暫不支援照片上傳，請使用 App 版本',
      };
    }
  }

  // 上傳用戶大頭貼
  Future<Map<String, dynamic>> uploadAvatar(String imagePath) async {
    try {
      print('\n========== 上傳用戶大頭貼 ==========');
      print('照片路徑: $imagePath');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: 'avatar.jpg',
        ),
      });
      
      final response = await _dio.post(
        '$baseUrl/users/upload/avatar',
        data: formData,
      );
      
      print('上傳回應狀態: ${response.statusCode}');
      print('上傳回應資料: ${response.data}');
      print('========== 上傳完成 ==========\n');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '大頭貼上傳成功',
          'data': response.data,
        };
      }
      
      return {
        'success': false,
        'message': '上傳失敗',
      };
    } catch (e) {
      print('❌ 上傳大頭貼失敗: $e');
      if (e is DioException && e.response != null) {
        print('錯誤狀態碼: ${e.response?.statusCode}');
        print('錯誤回應: ${e.response?.data}');
        
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          return {
            'success': false,
            'message': errorData['detail'],
          };
        }
      }
      print('========== 上傳失敗 ==========\n');
      
      return {
        'success': false,
        'message': '上傳失敗，請稍後再試',
      };
    }
  }

  // Mock 資料（用於開發測試）
  List<Activity> _getMockActivities(double lat, double lng) {
    final now = DateTime.now();
    
    return [
      Activity(
        id: '1',
        title: '咖啡廳讀書會',
        description: '一起來咖啡廳讀書吧！歡迎帶自己的書',
        latitude: lat + 0.005,
        longitude: lng + 0.005,
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 4)),
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
        startTime: now.subtract(const Duration(minutes: 30)), // 30 分鐘前開始
        endTime: now.add(const Duration(hours: 1, minutes: 30)), // 還有 1.5 小時
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
        startTime: now.add(const Duration(hours: 3)),
        endTime: now.add(const Duration(hours: 5)),
        maxParticipants: 8,
        currentParticipants: 8,
        category: '美食',
        hostId: 'user3',
        hostName: '小華',
      ),
    ];
  }
}
