import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'api_service.dart';

class ActivityService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Activity> _activities = [];
  Activity? _selectedActivity;
  bool _isLoading = false;

  List<Activity> get activities => _activities;
  Activity? get selectedActivity => _selectedActivity;
  bool get isLoading => _isLoading;

  Future<void> loadNearbyActivities(double latitude, double longitude) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _apiService.getNearbyActivities(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      print('載入活動失敗: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectActivity(Activity? activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  Future<bool> joinActivity(String activityId) async {
    final success = await _apiService.joinActivity(activityId);
    if (success) {
      // 更新本地資料
      final index = _activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        // 這裡應該重新載入活動資料，暫時先通知更新
        notifyListeners();
      }
    }
    return success;
  }

  Future<Activity?> createActivity({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required DateTime startTime,
    required int maxParticipants,
    required String category,
  }) async {
    final activity = await _apiService.createActivity(
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      startTime: startTime,
      maxParticipants: maxParticipants,
      category: category,
    );

    if (activity != null) {
      _activities.add(activity);
      notifyListeners();
    }

    return activity;
  }
}
