import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import '../services/activity_service.dart';
import '../widgets/activity_marker_widget.dart';
import '../widgets/activity_detail_panel.dart';
import '../widgets/create_activity_dialog.dart';

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

      // 載入附近活動
      if (mounted) {
        await context.read<ActivityService>().loadNearbyActivities(
              position.latitude,
              position.longitude,
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
            );
        await _updateMarkers();
      }
    }
  }

  Future<void> _updateMarkers() async {
    final activities = context.read<ActivityService>().activities;
    final Set<Marker> newMarkers = {};

    for (final activity in activities) {
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
    }

    setState(() => _markers = newMarkers);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      print('無法取得位置: $e');
    }
  }

  void _showCreateActivityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateActivityDialog(
        initialPosition: _currentPosition,
        onActivityCreated: () async {
          await _updateMarkers();
        },
      ),
    );
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
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
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
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF00D0DD).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF00D0DD),
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
    return Center(
      child: Text('搜尋結果：$query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = ['咖啡廳讀書會', '籃球鬥牛', '夜市美食團'];
    final filteredSuggestions = suggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(filteredSuggestions[index]),
          onTap: () {
            query = filteredSuggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
