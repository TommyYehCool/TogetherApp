import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
    final activities = context.read<ActivityService>().activities;
    final Set<Marker> newMarkers = {};

    print('\n========== 更新地圖標記 ==========');
    print('活動數量: ${activities.length}');
    
    // 加入自訂使用者位置標記
    final userLocationIcon = await _createUserLocationMarker();
    newMarkers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentPosition,
        icon: userLocationIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 999, // 確保在最上層
      ),
    );
    print('✅ 已加入使用者位置標記: $_currentPosition');

    // 加入活動標記
    for (final activity in activities) {
      print('處理活動: ${activity.title}');
      print('  位置: (${activity.latitude}, ${activity.longitude})');
      print('  參與人數: ${activity.participantCount}');
      
      try {
        final markerIcon = await ActivityMarkerWidget(
          title: activity.title,
          participantCount: activity.participantCount,
          isFull: activity.isFull,
          isBoosted: activity.isBoosted,
        ).toBitmapDescriptor(
          logicalSize: const Size(200, 60),
          imageSize: const Size(400, 120),
        );

        newMarkers.add(
          Marker(
            markerId: MarkerId(activity.id),
            position: LatLng(activity.latitude, activity.longitude),
            icon: markerIcon,
            onTap: () {
              context.read<ActivityService>().selectActivity(activity);
              _panelController.open();
            },
          ),
        );
        print('  ✅ 標記已加入');
      } catch (e) {
        print('  ❌ 建立標記失敗: $e');
      }
    }

    print('總標記數: ${newMarkers.length}');
    print('========== 更新完成 ==========\n');
    
    setState(() => _markers = newMarkers);
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

  // 當地圖移動時載入新的活動
  Future<void> _onCameraMove(CameraPosition position) async {
    // 可以在這裡實作當地圖移動時自動載入新區域的活動
    // 為了避免過度頻繁的 API 呼叫，可以加入防抖動機制
  }

  // 當地圖停止移動時載入活動
  Future<void> _onCameraIdle() async {
    if (_mapController != null) {
      final center = await _mapController!.getVisibleRegion();
      final centerLat = (center.northeast.latitude + center.southwest.latitude) / 2;
      final centerLng = (center.northeast.longitude + center.southwest.longitude) / 2;
      
      // 可選：當地圖移動到新位置時，重新載入該區域的活動
      // await context.read<ActivityService>().loadNearbyActivities(
      //   centerLat,
      //   centerLng,
      //   radiusMeters: 300,
      // );
      // await _updateMarkers();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 0,
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        panel: const ActivityDetailPanel(),
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
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // 頂部搜尋列
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildTopBar(),
            ),

            // 我的位置按鈕
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'myLocation',
                onPressed: _goToMyLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Color(0xFF00D0DD)),
              ),
            ),

            // 建立活動按鈕
            Positioned(
              bottom: 24,
              right: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return GestureDetector(
      onTap: () {
        // 顯示搜尋對話框
        showSearch(
          context: context,
          delegate: ActivitySearchDelegate(),
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
  @override
  String get searchFieldLabel => '搜尋活動...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
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
              title: Text(activity.title),
              subtitle: Text(
                '${activity.category} • ${activity.participantCount}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // 關閉搜尋
                close(context, activity.title);
                
                // 移動地圖到活動位置並選中該活動
                _moveToActivity(context, activity);
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
            subtitle: Text(activity.category),
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
          subtitle: Text(activity.category),
          onTap: () {
            query = activity.title;
            showResults(context);
          },
        );
      },
    );
  }

  // 移動地圖到活動位置
  void _moveToActivity(BuildContext context, activity) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      // 移動地圖到活動位置
      homeScreenState._mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(activity.latitude, activity.longitude),
          17, // 縮放等級 17
        ),
      );
      
      // 選中該活動並開啟詳情面板
      context.read<ActivityService>().selectActivity(activity);
      homeScreenState._panelController.open();
    }
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
