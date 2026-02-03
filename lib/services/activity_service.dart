import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'api_service.dart';

class ActivityService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Activity> _activities = [];
  List<Activity> _hostedActivities = [];
  List<Activity> _joinedActivities = [];
  Activity? _selectedActivity;
  bool _isLoading = false;
  String? _errorMessage;

  List<Activity> get activities => _activities;
  List<Activity> get hostedActivities => _hostedActivities;
  List<Activity> get joinedActivities => _joinedActivities;
  Activity? get selectedActivity => _selectedActivity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ApiService get apiService => _apiService; // 公開 apiService

  // 設定認證 Token
  void setAuthToken(String token) {
    _apiService.setAuthToken(token);
  }

  // 載入附近活動
  Future<void> loadNearbyActivities(double latitude, double longitude, {int radiusMeters = 5000}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activities = await _apiService.getNearbyActivities(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    } catch (e) {
      _errorMessage = '載入活動失敗: $e';
      print(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // 選擇活動
  void selectActivity(Activity? activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  // 加入活動
  Future<bool> joinActivity(int activityId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.joinActivity(activityId);
    
    if (success) {
      // 重新載入活動資料
      notifyListeners();
    } else {
      _errorMessage = '加入活動失敗';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // 建立活動
  Future<Activity?> createActivity({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required int maxParticipants,
    required String activityType,
    required String region,      // 新增必填欄位：地區
    required String address,     // 新增必填欄位：詳細地址
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final activity = await _apiService.createActivity(
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      maxParticipants: maxParticipants,
      activityType: activityType,
      region: region,
      address: address,
    );

    if (activity != null) {
      _activities.add(activity);
    } else {
      _errorMessage = '建立活動失敗';
    }

    _isLoading = false;
    notifyListeners();
    return activity;
  }

  // 取得活動的加入請求（Host 專用）
  Future<List<Map<String, dynamic>>> getActivityRequests(int activityId) async {
    return await _apiService.getActivityRequests(activityId);
  }

  // 批准加入請求（Host 專用）
  Future<bool> approveJoinRequest(int requestId) async {
    final success = await _apiService.approveJoinRequest(requestId);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  // 評分活動
  Future<bool> rateActivity(int activityId, int score) async {
    return await _apiService.rateActivity(activityId, score);
  }

  // Boost 活動
  Future<bool> boostActivity(int activityId, {int days = 1}) async {
    final success = await _apiService.boostActivity(activityId, days: days);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  // 載入使用者主辦的活動
  Future<void> loadHostedActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _hostedActivities = await _apiService.getUserHostedActivities();
    } catch (e) {
      _errorMessage = '載入主辦活動失敗: $e';
      print(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // 載入使用者參加的活動
  Future<void> loadJoinedActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _joinedActivities = await _apiService.getUserJoinedActivities();
    } catch (e) {
      _errorMessage = '載入參加活動失敗: $e';
      print(_errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  // 清除錯誤訊息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
