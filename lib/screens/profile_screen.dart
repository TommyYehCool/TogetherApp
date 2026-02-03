import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/activity_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    final service = context.read<ActivityService>();
    await Future.wait([
      service.loadHostedActivities(),
      service.loadJoinedActivities(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        backgroundColor: const Color(0xFF00D0DD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '我主辦的'),
            Tab(text: '我參加的'),
          ],
        ),
      ),
      body: Consumer<ActivityService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D0DD),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildActivityList(service.hostedActivities, isHost: true),
              _buildActivityList(service.joinedActivities, isHost: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityList(List activities, {required bool isHost}) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHost ? Icons.event_busy : Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isHost ? '尚未主辦任何活動' : '尚未參加任何活動',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      color: const Color(0xFF00D0DD),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(activity, isHost: isHost);
        },
      ),
    );
  }

  Widget _buildActivityCard(activity, {required bool isHost}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (isHost) {
            _showHostOptions(activity);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D0DD).withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.category ?? '活動',
                      style: const TextStyle(
                        color: Color(0xFF00D0DD),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (activity.isBoosted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Boosted',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isHost)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showHostOptions(activity),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MM/dd HH:mm').format(activity.startTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.currentParticipants}/${activity.maxParticipants}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHostOptions(activity) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFF00D0DD)),
              title: const Text('查看加入請求'),
              onTap: () {
                Navigator.pop(context);
                _showJoinRequests(activity.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate, color: Color(0xFF00D0DD)),
              title: const Text('上傳活動照片'),
              onTap: () {
                Navigator.pop(context);
                _uploadActivityPhotos(activity.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Boost 活動'),
              onTap: () {
                Navigator.pop(context);
                _boostActivity(activity.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('刪除活動'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 實作刪除功能
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinRequests(String activityId) async {
    final service = context.read<ActivityService>();
    // 將 String ID 轉換為 int
    final requests = await service.getActivityRequests(int.parse(activityId));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('加入請求'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: requests.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('目前沒有加入請求'),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // 使用者頭像
                          CircleAvatar(
                            backgroundColor: const Color(0xFF00D0DD).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF00D0DD),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 使用者資訊
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request['user_name'] ?? '使用者',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request['requested_at'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 批准按鈕
                          ElevatedButton(
                            onPressed: () async {
                              final success = await service.approveJoinRequest(
                                request['request_id'],
                              );
                              if (success && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已批准加入'),
                                    backgroundColor: Color(0xFF00D0DD),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D0DD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '批准',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '關閉',
              style: TextStyle(
                color: Color(0xFF00D0DD),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadActivityPhotos(String activityId) async {
    final service = context.read<ActivityService>();
    final ImagePicker imagePicker = ImagePicker();
    
    // Web 平台提示
    if (mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('照片上傳'),
          content: const Text(
            '⚠️ Web 版本暫不支援照片上傳功能。\n\n'
            '如需上傳活動照片，請使用 Android 或 iOS App 版本。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D0DD),
                foregroundColor: Colors.white,
              ),
              child: const Text('仍要嘗試'),
            ),
          ],
        ),
      );
      
      if (shouldContinue != true) {
        return;
      }
    }
    
    try {
      // 選擇照片（最多3張）
      final List<XFile> images = await imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.isEmpty) {
        return;
      }
      
      if (images.length > 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('最多只能選擇 3 張照片'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // 顯示上傳中
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00D0DD)),
                SizedBox(height: 16),
                Text(
                  '正在上傳照片...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }
      
      // 上傳照片
      final imagePaths = images.map((img) => img.path).toList();
      final result = await service.uploadActivityImages(activityId, imagePaths);
      
      if (mounted) {
        Navigator.pop(context); // 關閉上傳對話框
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (result['success'] ? '照片上傳成功！' : '照片上傳失敗')),
            backgroundColor: result['success'] ? const Color(0xFF00D0DD) : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        if (result['success']) {
          _loadActivities(); // 重新載入活動列表
        }
      }
    } catch (e) {
      print('選擇照片失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('選擇照片失敗'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _boostActivity(String activityId) async {
    final service = context.read<ActivityService>();
    
    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Boost 活動'),
        content: const Text('確定要花費 NT\$30 提升此活動的曝光度嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D0DD),
            ),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await service.boostActivity(int.parse(activityId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Boost 成功！' : 'Boost 失敗'),
            backgroundColor: success ? const Color(0xFF00D0DD) : Colors.red,
          ),
        );
        if (success) {
          _loadActivities();
        }
      }
    }
  }
}
