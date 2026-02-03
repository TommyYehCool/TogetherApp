import 'package:flutter/material.dart';

/// 活動標記系統 - 純陰影浮起設計（無邊框）
/// 
/// 設計理念：
/// 1. 完全不要邊框/描邊/螢光外框
/// 2. 活動 marker 風格與「2 活動」cluster 一致：白底卡片 + 柔和陰影
/// 3. 選取狀態用「微放大 + 陰影加深」，不要外框
/// 4. LIVE chip 是唯一的重點色

// ============================================================
// 1. 活動膠囊標記（主要標記）- 無邊框版本
// ============================================================

/// 活動膠囊標記 - 純陰影浮起設計
/// 
/// 規格：
/// - height: 36px (縮小)
/// - radius: 18px (完全圓角)
/// - bg: rgba(255,255,255,0.96)
/// - border: none（完全移除）
/// - shadow: 雙層陰影
///   - 0 10 24 rgba(0,0,0,0.14)
///   - 0 3 8 rgba(0,0,0,0.10)
/// - anchor dot: 8px（讓 marker 有位置指向）
class ActivityPillMarker extends StatelessWidget {
  final IconData activityIcon;
  final String title; // 新增：活動標題
  final String participantCount;
  final bool isLive;
  final bool isNearlyFull; // >= 80%
  final bool isFull;
  final int currentCount;
  final int maxCount;

  const ActivityPillMarker({
    super.key,
    required this.activityIcon,
    required this.title,
    required this.participantCount,
    this.isLive = false,
    this.isNearlyFull = false,
    this.isFull = false,
    required this.currentCount,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    // 根據標題長度和是否有 LIVE 標籤動態調整顯示
    // LIVE 標籤會占用額外空間，所以要減少標題字元數
    String displayTitle;
    int maxChars = isLive ? 10 : 12; // LIVE 時顯示 10 個字，否則 12 個字
    
    if (title.length <= maxChars) {
      displayTitle = title;
    } else {
      displayTitle = '${title.substring(0, maxChars)}...';
    }
    
    return SizedBox(
      width: 1000, // 提升到 1000px
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Anchor dot（底部定位點）
          Positioned(
            bottom: 0,
            child: _buildAnchorDot(),
          ),
          
          // 主膠囊（使用 PhysicalModel 產生陰影）
          Positioned(
            top: 6,
            child: _buildPillContent(displayTitle),
          ),
        ],
      ),
    );
  }

  /// 建立膠囊內容（純陰影，無邊框）
  Widget _buildPillContent(String displayTitle) {
    return PhysicalModel(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(18),
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.14),
      child: Container(
        height: 36,
        constraints: const BoxConstraints(
          minWidth: 120,
          maxWidth: 1000, // 提升到 1000px
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LIVE 標籤
            if (isLive) ...[
              _buildLiveChip(),
              const SizedBox(width: 6),
            ],
            
            // 活動圖標
            SizedBox(
              width: 16,
              child: Icon(
                activityIcon,
                size: 16,
                color: const Color(0xFF00D0DD),
              ),
            ),
            const SizedBox(width: 6),
            
            // 活動標題
            Flexible(
              child: Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                  height: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            
            // 人數顯示
            Text(
              participantCount,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getParticipantColor(),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// LIVE 標籤 - 紅底白字（唯一重點色）
  Widget _buildLiveChip() {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4F),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.0,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Anchor dot（定位點）- 8px，無 ripple 光圈
  Widget _buildAnchorDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436), // 深色
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  /// 取得人數文字顏色
  /// 預設深灰；>=80% 才轉橘紅
  Color _getParticipantColor() {
    if (isFull) {
      return Colors.grey[500]!; // 已滿：灰色
    } else if (isNearlyFull) {
      return const Color(0xFFFF6B35); // 快滿（>=80%）：橘紅色
    } else {
      return const Color(0xFF2D3436); // 正常：深灰
    }
  }
}

// ============================================================
// 2. Cluster 標記（多活動重疊）- 與活動標記同款
// ============================================================

/// Cluster 膠囊標記 - 與活動標記完全一致的風格
class ClusterPillMarker extends StatelessWidget {
  final int count;

  const ClusterPillMarker({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Anchor dot
          Positioned(
            bottom: 0,
            child: _buildAnchorDot(),
          ),
          
          // 膠囊內容
          Positioned(
            top: 6,
            child: _buildPillContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPillContent() {
    return PhysicalModel(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(18),
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.14),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          // 無邊框
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 堆疊圖標
            Icon(
              Icons.layers,
              size: 15,
              color: const Color(0xFF00D0DD),
            ),
            const SizedBox(width: 6),
            // 文字
            Text(
              '$count 個活動',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchorDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. 選中狀態標記 - 微放大 + 陰影加深（無外框）
// ============================================================

/// 選中狀態的活動標記
/// scale: 1.04
/// shadow: 加深（0 14 30 rgba(0,0,0,0.18) + 0 4 12 rgba(0,0,0,0.12)）
/// 不加任何外框、不加任何 halo、不加青色效果
class SelectedActivityMarker extends StatelessWidget {
  final IconData activityIcon;
  final String title;
  final String participantCount;
  final bool isLive;
  final bool isNearlyFull;
  final bool isFull;

  const SelectedActivityMarker({
    super.key,
    required this.activityIcon,
    required this.title,
    required this.participantCount,
    this.isLive = false,
    this.isNearlyFull = false,
    this.isFull = false,
  });

  @override
  Widget build(BuildContext context) {
    // 根據標題長度和是否有 LIVE 標籤動態調整顯示
    String displayTitle;
    int maxChars = isLive ? 10 : 12;
    
    if (title.length <= maxChars) {
      displayTitle = title;
    } else {
      displayTitle = '${title.substring(0, maxChars)}...';
    }
    
    return SizedBox(
      width: 1000, // 與普通標記一致
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Anchor dot（稍微放大）
          Positioned(
            bottom: 0,
            child: _buildAnchorDot(),
          ),
          
          // 膠囊內容（放大 1.04 倍）
          Positioned(
            top: 5,
            child: Transform.scale(
              scale: 1.04,
              child: _buildPillContent(displayTitle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillContent(String displayTitle) {
    return PhysicalModel(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(22),
      elevation: 14, // 加深陰影：0 14 30 rgba(0,0,0,0.18)
      shadowColor: Colors.black.withOpacity(0.18),
      child: Container(
        height: 44,
        constraints: const BoxConstraints(
          minWidth: 120,
          maxWidth: 1000, // 與普通標記一致
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // 完全無邊框、無 halo、無青色效果
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LIVE 標籤
            if (isLive) ...[
              _buildLiveChip(),
              const SizedBox(width: 6),
            ],
            
            // 活動圖標
            Icon(
              activityIcon,
              size: 18,
              color: const Color(0xFF00D0DD),
            ),
            const SizedBox(width: 6),
            
            // 標題
            Flexible(
              child: Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            
            // 人數
            Text(
              participantCount,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getParticipantColor(),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChip() {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D4F),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'LIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.0,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAnchorDot() {
    return Container(
      width: 10, // 稍微放大
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3436),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }

  Color _getParticipantColor() {
    if (isFull) {
      return Colors.grey[500]!;
    } else if (isNearlyFull) {
      return const Color(0xFFFF6B35);
    } else {
      return const Color(0xFF2D3436);
    }
  }
}

// ============================================================
// 4. Spiderfy 展開標記（扇形展開時的小標記）
// ============================================================

/// Spiderfy 展開時的小膠囊標記
class SpiderfyMarker extends StatelessWidget {
  final IconData activityIcon;
  final String title;
  final String participantCount;

  const SpiderfyMarker({
    super.key,
    required this.activityIcon,
    required this.title,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.length > 10 ? '${title.substring(0, 10)}...' : title;
    
    return SizedBox(
      width: 140,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Anchor dot
          Positioned(
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3436),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          
          // 膠囊內容
          Positioned(
            top: 6,
            child: PhysicalModel(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(18),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.12),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  // 無邊框
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activityIcon,
                      size: 16,
                      color: const Color(0xFF00D0DD),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3436),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      participantCount,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00D0DD),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
