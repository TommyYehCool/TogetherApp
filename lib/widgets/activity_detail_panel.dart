import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class ActivityDetailPanel extends StatelessWidget {
  final VoidCallback? onClose; // 新增：關閉回調
  
  const ActivityDetailPanel({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityService>(
      builder: (context, service, child) {
        final activity = service.selectedActivity;
        
        if (activity == null) {
          return const SizedBox.shrink();
        }

        // 調試信息
        print('\n========== ActivityDetailPanel ==========');
        print('活動: ${activity.title}');
        print('開始時間: ${activity.startTime}');
        print('結束時間: ${activity.endTime}');
        print('isOngoing: ${activity.isOngoing}');
        print('========================================\n');

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 頂部列：拖曳指示器 + 關閉按鈕
              SizedBox(
                height: 48, // 給 Stack 一個固定高度
                child: Stack(
                  children: [
                    // 拖曳指示器（置中）
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // 關閉按鈕（右上角）
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        color: Colors.grey[600],
                        onPressed: onClose, // 使用回調
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 標題與類別
                      Row(
                        children: [
                          // LIVE 標籤（如果活動正在進行中）
                          if (activity.isOngoing) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D0DD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              activity.category,
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
                                color: Colors.amber.withOpacity(0.2),
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 活動標題（使用跑馬燈效果）
                      _buildMarqueeTitle(activity.title),

                      const SizedBox(height: 24),

                      // 1. 標題 + LIVE/類別 tag（已在上方）

                      // 2. 時間（開始/結束）
                      _buildInfoRow(
                        Icons.access_time,
                        '${DateFormat('MM/dd HH:mm').format(activity.startTime.subtract(const Duration(hours: 8)).toLocal())}',
                      ),
                      if (activity.endTime != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            '至 ${DateFormat('MM/dd HH:mm').format(activity.endTime!.subtract(const Duration(hours: 8)).toLocal())}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // 3. 地點（店名或地址，並顯示距離）
                      _buildInfoRow(
                        Icons.location_on,
                        activity.region != null && activity.region!.isNotEmpty
                            ? '${activity.region} ${activity.address ?? ''}'.trim()
                            : activity.fullAddress,
                      ),

                      const SizedBox(height: 12),

                      // 4. 人數進度（進度條或 0/5）
                      _buildParticipantProgress(activity),

                      const SizedBox(height: 24),

                      // 5. 活動簡介（2 行摘要）
                      const Text(
                        '活動簡介',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 16),

                      // 主辦人
                      _buildInfoRow(
                        Icons.person,
                        '主辦人：${activity.hostName}',
                      ),
                    ],
                  ),
                ),
              ),

              // 底部加入按鈕（固定在底部）
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: activity.isFull
                        ? null
                        : () => _joinActivity(context, activity.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D0DD),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      activity.isFull ? '已額滿' : '申請加入',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context, String activityId) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('評分活動'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('請為這個活動評分'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: '評論（選填）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final service = context.read<ActivityService>();
                // 將 String ID 轉換為 int
                final success = await service.rateActivity(
                  int.parse(activityId),
                  rating,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '評分成功！' : '評分失敗'),
                      backgroundColor: success ? const Color(0xFF00D0DD) : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D0DD),
              ),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarqueeTitle(String title) {
    // 如果標題不長，直接顯示
    if (title.length <= 15) {
      return Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3436),
        ),
      );
    }
    
    // 長標題使用跑馬燈效果
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00D0DD)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantProgress(Activity activity) {
    final progress = activity.currentParticipants / activity.maxParticipants;
    final isNearlyFull = progress >= 0.8;
    final isFull = activity.isFull;
    
    return Row(
      children: [
        const Icon(Icons.people, size: 20, color: Color(0xFF00D0DD)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${activity.currentParticipants}/${activity.maxParticipants} 人',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isFull 
                          ? Colors.grey[600] 
                          : isNearlyFull 
                              ? const Color(0xFFFF6B35) 
                              : const Color(0xFF2D3436),
                    ),
                  ),
                  if (isFull)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '已額滿',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    )
                  else if (isNearlyFull)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '即將額滿',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull 
                        ? Colors.grey[400]! 
                        : isNearlyFull 
                            ? const Color(0xFFFF6B35) 
                            : const Color(0xFF00D0DD),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _joinActivity(BuildContext context, String activityId) async {
    final service = context.read<ActivityService>();
    
    // 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D0DD)),
      ),
    );

    final success = await service.joinActivity(int.parse(activityId));
    
    if (context.mounted) {
      Navigator.pop(context); // 關閉載入對話框

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('成功加入活動！'),
            backgroundColor: Color(0xFF00D0DD),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加入活動失敗，請稍後再試'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
