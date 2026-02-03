import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:math';
import '../services/activity_service.dart';
import '../models/activity.dart';
import '../widgets/activity_marker_widget.dart';
import '../widgets/activity_detail_panel.dart';
import '../widgets/create_activity_dialog.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final PanelController _panelController = PanelController();
  Set<Marker> _markers = {};
  LatLng _currentPosition = const LatLng(25.0330, 121.5654); // 台北市預設位置
  bool _isLoadingLocation = true;
  bool _isLoadingActivities = false;
  String? _selectedActivityId; // 追蹤選中的活動
  double _currentZoom = 17.0; // 追蹤當前地圖縮放等級
  bool _isMapGesturesEnabled = true; // 控制地圖手勢
  bool _isUpdatingMarkers = false; // 防止重複更新標記
  bool _isPanelOpen = false; // 追蹤面板是否打開
  
  // 防抖動計時器
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // 移動地圖到使用者位置，縮放等級 17（約 300 公尺範圍）
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 17),
      );

      // 載入附近活動（300 公尺範圍）
      if (mounted) {
        await context.read<ActivityService>().loadNearbyActivities(
              position.latitude,
              position.longitude,
              radiusMeters: 300,
            );
        await _updateMarkers();
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      // 使用預設位置載入活動
      if (mounted) {
        await context.read<ActivityService>().loadNearbyActivities(
              _currentPosition.latitude,
              _currentPosition.longitude,
              radiusMeters: 300,
            );
        await _updateMarkers();
      }
    }
  }

  Future<void> _updateMarkers() async {
    // 防止重複更新
    if (_isUpdatingMarkers) {
      print('⚠️ 標記更新中，跳過此次更新');
      return;
    }
    
    _isUpdatingMarkers = true;
    
    try {
      final activities = context.read<ActivityService>().activities;
      final selectedActivity = context.read<ActivityService>().selectedActivity;
      final Set<Marker> newMarkers = {};
      final Set<String> processedActivityIds = {};

      print('\n========== 更新地圖標記 ==========');
      print('活動數量: ${activities.length}');
      print('選中活動: ${selectedActivity?.id} - ${selectedActivity?.title}');
      
      // 列出所有活動
      for (var i = 0; i < activities.length; i++) {
        print('  [$i] ${activities[i].title} (${activities[i].id}) at (${activities[i].latitude}, ${activities[i].longitude})');
      }
    
    // 加入自訂使用者位置標記
    final userLocationIcon = await _createUserLocationMarker();
    newMarkers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentPosition,
        icon: userLocationIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 999,
      ),
    );
    print('✅ 已加入使用者位置標記: $_currentPosition');

    // 取得當前縮放等級的檢測半徑
    final detectionRadius = _calculateDetectionRadius(_currentZoom);
    print('當前縮放等級: $_currentZoom, 檢測半徑: ${detectionRadius.toStringAsFixed(0)}m');

    // 為所有活動建立標記
    for (final activity in activities) {
      if (processedActivityIds.contains(activity.id)) {
        print('  跳過已處理的活動: ${activity.title}');
        continue;
      }

      print('處理活動: ${activity.title} (${activity.id})');
      
      try {
        final isSelected = selectedActivity?.id == activity.id;
        
        // 🔥 關鍵邏輯：如果有活動被選中，只處理選中的活動，跳過所有其他活動
        if (selectedActivity != null && !isSelected) {
          print('  有活動被選中，跳過此活動');
          processedActivityIds.add(activity.id);
          continue;
        }
        
        // 如果是選中的活動，立即標記為已處理並創建選中標記
        if (isSelected) {
          processedActivityIds.add(activity.id);
          print('  這是選中的活動，直接創建選中標記');
          
          final markerIcon = await SelectedActivityMarker(
            activityIcon: _getActivityIcon(activity.category),
            title: activity.title,
            participantCount: activity.participantCount,
            isLive: activity.isOngoing,
            isNearlyFull: activity.currentParticipants / activity.maxParticipants >= 0.8,
            isFull: activity.isFull,
          ).toBitmapDescriptor(
            logicalSize: const Size(1000, 66), // 與普通標記一致
            imageSize: const Size(3000, 198), // 3x 高解析度
          );
          
          newMarkers.add(
            Marker(
              markerId: MarkerId(activity.id),
              position: LatLng(activity.latitude, activity.longitude),
              icon: markerIcon,
              anchor: const Offset(0.5, 0.85),
              zIndex: 100.0,
              onTap: () => _onMarkerTap(activity),
              consumeTapEvents: true,
            ),
          );
          print('  ✅ 選中標記已加入: ${activity.id}');
          continue; // 跳過後續處理
        }
        
        // 以下是沒有選中活動時的正常邏輯
        // 檢查是否有重疊活動
        final nearbyActivities = _findNearbyActivities(activity, radiusMeters: detectionRadius);
        
        // 過濾出未處理的附近活動
        final unprocessedNearby = nearbyActivities
            .where((a) => !processedActivityIds.contains(a.id))
            .toList();
        
        print('  附近活動數: ${nearbyActivities.length}, 未處理: ${unprocessedNearby.length}');
        
        // Cluster 條件：有多個未處理的活動重疊 (>= 2)
        final shouldCluster = unprocessedNearby.length >= 2;
        
        print('  shouldCluster: $shouldCluster');
        
        if (shouldCluster) {
          // 使用 Cluster 膠囊標記
          print('  ✅ 建立 Cluster: ${unprocessedNearby.length} 個活動');
          
          // 標記所有這些活動為已處理
          for (final nearbyActivity in unprocessedNearby) {
            processedActivityIds.add(nearbyActivity.id);
          }
          
          // 建立 Cluster 膠囊標記
          final clusterIcon = await ClusterPillMarker(
            count: unprocessedNearby.length,
          ).toBitmapDescriptor(
            logicalSize: const Size(100, 58),
            imageSize: const Size(300, 174), // 3x 高解析度
          );
          
          newMarkers.add(
            Marker(
              markerId: MarkerId('cluster_${activity.id}'),
              position: LatLng(activity.latitude, activity.longitude),
              icon: clusterIcon,
              anchor: const Offset(0.5, 0.85),
              zIndex: 50.0,
              onTap: () => _showNearbyActivitiesList(unprocessedNearby),
              consumeTapEvents: true, // 確保點擊事件被消費
            ),
          );
          print('  ✅ Cluster 標記已加入: cluster_${activity.id}');
        } else {
          // 單一活動標記
          processedActivityIds.add(activity.id);
          print('  建立單一活動標記');
          
          BitmapDescriptor markerIcon;
          final isNearlyFull = activity.currentParticipants / activity.maxParticipants >= 0.8;
          
          // 計算 zIndex
          double zIndex = 1.0;
          if (selectedActivity != null) {
            // 如果有選中的活動，檢查當前活動是否接近選中活動
            final distanceToSelected = _calculateDistance(
              activity.latitude,
              activity.longitude,
              selectedActivity.latitude,
              selectedActivity.longitude,
            );
            if (distanceToSelected < detectionRadius) {
              // 接近選中活動的其他活動，提高 zIndex 以確保可點擊
              zIndex = 80.0;
              print('  活動接近選中活動，提高 zIndex 到 $zIndex');
            }
          }
          
          // 預設狀態：活動膠囊
          markerIcon = await ActivityPillMarker(
            activityIcon: _getActivityIcon(activity.category),
            title: activity.title,
            participantCount: activity.participantCount,
            isLive: activity.isOngoing,
            isNearlyFull: isNearlyFull,
            isFull: activity.isFull,
            currentCount: activity.currentParticipants,
            maxCount: activity.maxParticipants,
          ).toBitmapDescriptor(
            logicalSize: const Size(1000, 58), // 提升到 1000px
            imageSize: const Size(3000, 174), // 3x 高解析度
          );
          print('  使用活動膠囊標記');

          newMarkers.add(
            Marker(
              markerId: MarkerId(activity.id),
              position: LatLng(activity.latitude, activity.longitude),
              icon: markerIcon,
              anchor: const Offset(0.5, 0.85),
              zIndex: zIndex,
              onTap: () => _onMarkerTap(activity),
              consumeTapEvents: true,
            ),
          );
          print('  ✅ 標記已加入: ${activity.id} (zIndex: $zIndex)');
        }
      } catch (e) {
        print('  ❌ 建立標記失敗: $e');
      }
    }

    print('總標記數: ${newMarkers.length}');
    print('標記列表:');
    for (final marker in newMarkers) {
      print('  - ${marker.markerId.value} at ${marker.position}, zIndex: ${marker.zIndex}');
    }
    print('========== 更新完成 ==========\n');
    
    // 直接替換標記（不需要延遲）
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  // 處理標記點擊事件
  void _onMarkerTap(Activity tappedActivity) async {
    // 直接顯示活動詳情（重疊檢測已在 _updateMarkers 中處理）
    setState(() {
      _selectedActivityId = tappedActivity.id;
    });
    context.read<ActivityService>().selectActivity(tappedActivity);
    _panelController.open();
    await _updateMarkers(); // 重新渲染標記以顯示選中狀態
  }

  // 根據地圖縮放等級計算檢測半徑（公尺）
  // 縮放等級對應關係：
  // zoom 21: ~10m (最近)
  // zoom 18: ~50m
  // zoom 17: ~100m
  // zoom 15: ~200m
  // zoom 13: ~500m (最遠)
  double _calculateDetectionRadius(double zoom) {
    // 使用指數函數計算，縮放等級越大，半徑越小
    // 公式：radius = 40000 / (2 ^ zoom)
    // 這樣可以確保在不同縮放等級下，螢幕上的檢測範圍大致相同
    const double baseRadius = 40000.0; // 基礎半徑（公尺）
    final double radius = baseRadius / pow(2, zoom);
    
    // 限制最小和最大值
    return radius.clamp(20.0, 500.0);
  }

  // 尋找附近的活動
  List<Activity> _findNearbyActivities(Activity centerActivity, {required double radiusMeters}) {
    final activities = context.read<ActivityService>().activities;
    final nearbyActivities = <Activity>[];
    
    for (final activity in activities) {
      final distance = _calculateDistance(
        centerActivity.latitude,
        centerActivity.longitude,
        activity.latitude,
        activity.longitude,
      );
      
      if (distance <= radiusMeters) {
        nearbyActivities.add(activity);
      }
    }
    
    return nearbyActivities;
  }

  // 計算兩點之間的距離（公尺）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 地球半徑（公尺）
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // 顯示附近活動列表
  void _showNearbyActivitiesList(List<Activity> activities) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 允許自訂高度
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // 初始高度 60%
        minChildSize: 0.3, // 最小高度 30%
        maxChildSize: 0.9, // 最大高度 90%
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖曳指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 標題
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF00D0DD)),
                    const SizedBox(width: 8),
                    Text(
                      '此區域有 ${activities.length} 個活動',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 活動列表（使用 scrollController）
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00D0DD).withAlpha(26),
                        child: Icon(
                          _getActivityIcon(activity.category),
                          color: const Color(0xFF00D0DD),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${activity.category} • ${activity.participantCount}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        // 保存選中的活動和必要的引用
                        final selectedActivity = activity;
                        final activityService = context.read<ActivityService>();
                        
                        print('📍 列表項目被點擊: ${selectedActivity.title}');
                        
                        // 關閉列表 bottom sheet
                        Navigator.pop(context);
                        
                        // 立即設定選中的活動（在 context 還有效時）
                        setState(() {
                          _selectedActivityId = selectedActivity.id;
                        });
                        activityService.selectActivity(selectedActivity);
                        
                        // 立即更新標記（在關閉列表後）
                        print('✅ 立即更新標記以反映新選中的活動...');
                        await _updateMarkers();
                        
                        // 使用 Future 來延遲打開面板，避免動畫衝突
                        Future.delayed(const Duration(milliseconds: 300), () async {
                          if (!mounted) {
                            print('❌ Widget 已經 unmounted');
                            return;
                          }
                          
                          print('✅ 正在打開面板...');
                          print('✅ Panel 當前狀態: ${_panelController.isPanelOpen}');
                          
                          // 確保面板完全打開（即使已經打開也重新打開以觸發動畫）
                          if (_panelController.isPanelOpen) {
                            // 如果面板已經打開，先關閉再打開以觸發更新動畫
                            print('✅ 面板已打開，先關閉...');
                            await _panelController.close();
                            // 等待關閉動畫完成
                            await Future.delayed(const Duration(milliseconds: 200));
                            if (mounted) {
                              print('✅ 重新打開面板...');
                              await _panelController.open();
                            }
                          } else {
                            // 如果面板關閉，直接打開
                            print('✅ 面板已關閉，直接打開...');
                            await _panelController.open();
                          }
                          
                          print('✅ 完成！');
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 根據活動類別取得對應圖標
  IconData _getActivityIcon(String category) {
    switch (category) {
      case '運動':
        return Icons.directions_run;
      case '美食':
        return Icons.restaurant;
      case '學習':
        return Icons.school;
      case '旅遊':
        return Icons.flight;
      case '音樂':
        return Icons.music_note;
      case '藝術':
        return Icons.palette;
      case '社交':
        return Icons.people;
      default:
        return Icons.event;
    }
  }

  // 建立自訂使用者位置標記
  Future<BitmapDescriptor> _createUserLocationMarker() async {
    return await _UserLocationMarker().toBitmapDescriptor(
      logicalSize: const Size(60, 60),
      imageSize: const Size(120, 120),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // 當地圖移動時載入新的活動（加入防抖動）
  Future<void> _onCameraMove(CameraPosition position) async {
    // 更新當前縮放等級
    _currentZoom = position.zoom;
    // 取消之前的計時器
    _debounceTimer?.cancel();
  }

  // 當地圖停止移動時載入活動
  Future<void> _onCameraIdle() async {
    // 使用防抖動，避免過度頻繁的 API 呼叫
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_mapController != null && mounted) {
        setState(() => _isLoadingActivities = true);
        
        try {
          final center = await _mapController!.getVisibleRegion();
          final centerLat = (center.northeast.latitude + center.southwest.latitude) / 2;
          final centerLng = (center.northeast.longitude + center.southwest.longitude) / 2;
          
          print('\n========== 地圖移動，載入新區域活動 ==========');
          print('中心位置: ($centerLat, $centerLng)');
          
          // 載入該區域的活動（500 公尺範圍）
          await context.read<ActivityService>().loadNearbyActivities(
            centerLat,
            centerLng,
            radiusMeters: 500,
          );
          
          // 更新地圖標記
          await _updateMarkers();
        } catch (e) {
          print('載入活動失敗: $e');
        } finally {
          if (mounted) {
            setState(() => _isLoadingActivities = false);
          }
        }
      }
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          17, // 縮放等級 17（約 300 公尺範圍）
        ),
      );
      
      // 重新載入附近活動（300 公尺範圍）
      if (mounted) {
        await context.read<ActivityService>().loadNearbyActivities(
              position.latitude,
              position.longitude,
              radiusMeters: 300,
            );
        await _updateMarkers(); // 這會同時更新使用者位置標記和活動標記
      }
    } catch (e) {
      print('無法取得位置: $e');
    }
  }

  void _showCreateActivityDialog() async {
    // 禁用地圖手勢
    setState(() => _isMapGesturesEnabled = false);
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateActivityDialog(
        initialPosition: _currentPosition,
        onActivityCreated: () async {
          // 重新載入附近活動
          await context.read<ActivityService>().loadNearbyActivities(
            _currentPosition.latitude,
            _currentPosition.longitude,
            radiusMeters: 300,
          );
          // 更新地圖標記
          await _updateMarkers();
        },
      ),
    );
    
    // 恢復地圖手勢
    setState(() => _isMapGesturesEnabled = true);
    
    // 如果成功建立活動，重新載入地圖
    if (result == true && mounted) {
      await context.read<ActivityService>().loadNearbyActivities(
        _currentPosition.latitude,
        _currentPosition.longitude,
        radiusMeters: 300,
      );
      await _updateMarkers();
    }
  }

  // 移動地圖到活動位置（供搜尋使用）
  void _moveToActivity(BuildContext context, Activity activity) {
    // 移動地圖到活動位置
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(activity.latitude, activity.longitude),
        17,
      ),
    );
    
    // 選中該活動並開啟詳情面板
    context.read<ActivityService>().selectActivity(activity);
    _panelController.open();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 0,
        maxHeight: screenHeight * 0.45, // 改為 45%
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        panel: ActivityDetailPanel(
          onClose: () {
            // 關閉面板
            _panelController.close();
          },
        ),
        onPanelSlide: (position) {
          // 當面板滑動時，根據位置禁用/啟用地圖手勢和按鈕
          // position: 0.0 (關閉) ~ 1.0 (完全打開)
          if (position > 0.1) {
            if (_isMapGesturesEnabled) {
              setState(() => _isMapGesturesEnabled = false);
            }
            if (!_isPanelOpen) {
              setState(() => _isPanelOpen = true);
            }
          } else {
            if (!_isMapGesturesEnabled) {
              setState(() => _isMapGesturesEnabled = true);
            }
            if (_isPanelOpen) {
              setState(() => _isPanelOpen = false);
            }
          }
        },
        onPanelClosed: () {
          // 面板關閉時，清除選中狀態，恢復 cluster 顯示
          setState(() => _isPanelOpen = false);
          if (_selectedActivityId != null) {
            setState(() {
              _selectedActivityId = null;
            });
            context.read<ActivityService>().selectActivity(null);
            _updateMarkers(); // 重新渲染標記
          }
        },
        body: Stack(
          children: [
            // 地圖
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 17, // 縮放等級 17 約為 300 公尺範圍
              ),
              markers: _markers,
              myLocationEnabled: false, // 關閉預設藍點，使用自訂標記
              myLocationButtonEnabled: false, // 關閉預設定位按鈕
              zoomControlsEnabled: false, // 關閉縮放控制按鈕
              mapToolbarEnabled: false, // 關閉地圖工具列
              compassEnabled: false, // 關閉指南針
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              // 根據狀態控制地圖手勢
              scrollGesturesEnabled: _isMapGesturesEnabled,
              zoomGesturesEnabled: _isMapGesturesEnabled,
              tiltGesturesEnabled: _isMapGesturesEnabled,
              rotateGesturesEnabled: _isMapGesturesEnabled,
              // 攔截地圖點擊，防止 POI 彈窗
              onTap: (LatLng position) {
                print('地圖被點擊: $position');
                // 不做任何事，阻止 POI 彈窗
              },
            ),

            // 頂部搜尋列
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildTopBar(),
            ),

            // 載入活動指示器
            if (_isLoadingActivities)
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '載入活動中...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 我的位置按鈕（右下角）
            Positioned(
              bottom: 100,
              right: 16,
              child: IgnorePointer(
                ignoring: _isPanelOpen, // 面板打開時禁用按鈕
                child: FloatingActionButton(
                  heroTag: 'myLocation',
                  onPressed: _goToMyLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Color(0xFF00D0DD)),
                ),
              ),
            ),

            // 建立活動按鈕（右下角，在我的位置按鈕下方）
            Positioned(
              bottom: 24,
              right: 16,
              child: IgnorePointer(
                ignoring: _isPanelOpen, // 面板打開時禁用按鈕
                child: FloatingActionButton.extended(
                  heroTag: 'createActivity',
                  onPressed: _showCreateActivityDialog,
                  backgroundColor: const Color(0xFF00D0DD),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    '建立活動',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return GestureDetector(
      onTap: () {
        // 顯示搜尋對話框，傳遞當前 state
        showSearch(
          context: context,
          delegate: ActivitySearchDelegate(homeScreenState: this),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF2D3436)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '搜尋附近活動...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // 導航到個人頁面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00D0DD).withAlpha(26),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Color(0xFF00D0DD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 搜尋委派
class ActivitySearchDelegate extends SearchDelegate<String> {
  final _HomeScreenState homeScreenState;

  ActivitySearchDelegate({required this.homeScreenState});

  @override
  String get searchFieldLabel => '搜尋活動...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          close(context, '');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // 使用後端搜尋 API
    return FutureBuilder<List<Activity>>(
      future: context.read<ActivityService>().apiService.searchActivities(
        query: query,
        onlyAvailable: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00D0DD)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '搜尋失敗：${snapshot.error}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '找不到「$query」相關的活動',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final activity = results[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00D0DD).withAlpha(26),
                child: const Icon(Icons.event, color: Color(0xFF00D0DD)),
              ),
              title: Text(
                activity.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        activity.category,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        activity.participantCount,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.shortAddress,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 關閉搜尋畫面
                close(context, activity.title);
                // 移動到活動位置
                homeScreenState._moveToActivity(context, activity);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final service = context.read<ActivityService>();
    
    if (query.isEmpty) {
      // 顯示所有活動作為建議
      return ListView.builder(
        itemCount: service.activities.length,
        itemBuilder: (context, index) {
          final activity = service.activities[index];
          return ListTile(
            leading: const Icon(Icons.event, color: Color(0xFF00D0DD)),
            title: Text(activity.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.category,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.shortAddress,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              query = activity.title;
              showResults(context);
            },
          );
        },
      );
    }

    // 根據輸入過濾建議
    final suggestions = service.activities
        .where((activity) =>
            activity.title.toLowerCase().contains(query.toLowerCase()) ||
            activity.category.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final activity = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Color(0xFF00D0DD)),
          title: Text(activity.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.category,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.shortAddress,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            query = activity.title;
            showResults(context);
          },
        );
      },
    );
  }
}

// 自訂使用者位置標記（藍色脈衝效果）
class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外層脈衝圓圈
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D0DD).withOpacity(0.2),
          ),
        ),
        // 中層圓圈
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D0DD).withOpacity(0.4),
          ),
        ),
        // 內層實心圓點
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00D0DD),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
