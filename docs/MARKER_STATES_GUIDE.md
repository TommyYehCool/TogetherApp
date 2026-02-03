# 地圖標記狀態指南

## 概述

Together App 使用動態地圖標記系統，根據活動狀態自動調整視覺效果。

## 標記狀態類型

### 1. Normal（一般狀態）

**觸發條件**：
- 參與率 < 80%
- 活動尚未開始或已結束

**視覺效果**：
- **Compact 模式**：
  ```
  ( 🏃 1/5 )  ← 青色底 (#00D0DD)、白色邊框
  ```
- **Expanded 模式**：
  ```
  [ 🏃 爬101  1/5 ]  ← 白色底、青色邊框
        ▼
  ```

**設計規格**：
- 背景色：`#00D0DD`（品牌青色）
- 邊框：白色 2px
- 陰影：標準黑色陰影

---

### 2. Hot（熱門狀態）

**觸發條件**：
- 參與率 ≥ 80%（例如：4/5, 8/10）
- 活動即將額滿

**視覺效果**：
- **Compact 模式**：
  ```
  ( 🏃 🔥 9/10 )  ← 青色底、橘色邊框
  ```
- **Expanded 模式**：
  ```
  [ 🏃 爬101 🔥 9/10 ]  ← 白色底、橘色邊框
         ▼
  ```

**設計規格**：
- 背景色：`#00D0DD`（保持品牌色）
- 邊框：橘色 `#FF5722` 3px（強調熱門）
- 火焰 emoji：🔥
- 陰影：標準黑色陰影

**用途**：
- 提醒使用者「快滿了，趕快報名！」
- 增加緊迫感，提升轉換率

---

### 3. Live（進行中狀態）

**觸發條件**：
- 後端 `status == 'ongoing'`，或
- 當前時間 > 開始時間 且 < 開始時間 + 3 小時

**視覺效果**：
- **Compact 模式**：
  ```
    [🔴LIVE]     ← 紅色標籤（頂部浮動）
  ( 🏃 3/5 )     ← 深紅色底 (#D32F2F)
     ~~~         ← 紅色光暈效果
  ```
- **Expanded 模式**：
  ```
    [🔴LIVE]           ← 獨立紅色標籤
  [ 🏃 爬101  3/5 ]   ← 白色底、紅色邊框
         ▼
       ~~~             ← 紅色光暈效果
  ```

**設計規格**：
- 背景色：深紅色 `#D32F2F`
- 邊框：白色 2px（Compact）/ 紅色 3px（Expanded）
- 光暈：`Colors.redAccent.withOpacity(0.6)`
  - `blurRadius: 10`
  - `spreadRadius: 2`（關鍵：產生擴散效果）
- LIVE 標籤：
  - 紅色背景 `#D32F2F`
  - 白色邊框 1.5px
  - 白色圓點 + "LIVE" 文字

**用途**：
- 類似 YouTube 直播、新聞直播的視覺效果
- 吸引使用者注意「正在發生」的活動
- 提升即時參與感

---

### 4. Cluster（地區聚合）

**觸發條件**：
- 多個活動在同一區域重疊
- 地圖縮放等級較小時自動聚合

**視覺效果**：
```
  ⚪ 12   ← 白色圓形，顯示活動數量
```

**顏色分級**：
- **< 5 個活動**：灰色 `Colors.grey[300]`
  ```
  ⚪ 3   ← 灰色（預設）
  ```
- **5-10 個活動**：藍色 `#00D0DD`
  ```
  🔵 7   ← 藍色（中等密度）
  ```
- **> 10 個活動**：橘色 `#FF5722`
  ```
  🟠 15  ← 橘色（超熱門區域）
  ```

**設計規格**：
- 形狀：完美圓形（48x48）
- 邊框：3px，顏色與背景相同
- 文字：粗體 18px
- 陰影：標準黑色陰影

**用途**：
- 減少地圖雜亂
- 快速識別活動密集區域
- 點擊後展開顯示列表

---

## 狀態優先級

當多個條件同時滿足時，按以下優先級顯示：

1. **Live**（最高優先級）
2. **Hot**
3. **Normal**（預設）

範例：
- 活動進行中 + 參與率 90% → 顯示 **Live** 狀態
- 活動尚未開始 + 參與率 90% → 顯示 **Hot** 狀態
- 活動進行中 + 參與率 50% → 顯示 **Live** 狀態

---

## 技術實作

### 狀態判斷邏輯

```dart
ActivityStatus get _effectiveStatus {
  // 1. 優先檢查 Live 狀態
  if (status == ActivityStatus.live) return ActivityStatus.live;
  
  // 2. 檢查 Hot 狀態（80% 以上）
  if (currentCount / maxCount >= 0.8) return ActivityStatus.hot;
  
  // 3. 預設為 Normal
  return ActivityStatus.normal;
}
```

### 光暈效果實作

```dart
// Live 狀態的紅色光暈
BoxShadow(
  color: Colors.redAccent.withOpacity(0.6),
  blurRadius: 10,        // 模糊半徑
  spreadRadius: 2,       // 擴散半徑（關鍵！）
  offset: const Offset(0, 0),  // 中心擴散
)
```

### LIVE 標籤實作

```dart
// 使用 Stack + Positioned 實現頂部浮動
Stack(
  clipBehavior: Clip.none,
  children: [
    // 主標記內容
    Container(...),
    
    // LIVE 標籤（浮動在頂部）
    if (_effectiveStatus == ActivityStatus.live)
      Positioned(
        top: -8,  // 向上偏移
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            // LIVE 標籤樣式
            child: Row(
              children: [
                Icon(Icons.circle, size: 6),  // 白色圓點
                Text('LIVE'),
              ],
            ),
          ),
        ),
      ),
  ],
)
```

---

## 使用範例

### 建立一般活動標記

```dart
CompactActivityMarker(
  participantCount: '1/5',
  activityIcon: Icons.directions_run,
  status: ActivityStatus.normal,
  currentCount: 1,
  maxCount: 5,
)
```

### 建立熱門活動標記

```dart
CompactActivityMarker(
  participantCount: '9/10',
  activityIcon: Icons.restaurant,
  status: ActivityStatus.normal,  // 會自動判斷為 Hot
  currentCount: 9,
  maxCount: 10,
)
```

### 建立進行中活動標記

```dart
CompactActivityMarker(
  participantCount: '3/5',
  activityIcon: Icons.music_note,
  status: ActivityStatus.live,
  currentCount: 3,
  maxCount: 5,
)
```

### 建立聚合標記

```dart
ClusterActivityMarker(
  count: 12,  // 會自動顯示橘色（> 10）
)
```

---

## 設計原則

### 1. 視覺層次
- **Live** > **Hot** > **Normal**
- 使用顏色、邊框粗細、特效建立清晰層次

### 2. 品牌一致性
- 保持青色 `#00D0DD` 作為主色調
- 使用橘色 `#FF5722` 作為強調色
- 紅色 `#D32F2F` 僅用於 Live 狀態

### 3. 可讀性
- 所有文字使用白色，確保對比度
- 邊框增強標記與地圖的分離感
- 陰影提升立體感

### 4. 效能考量
- 光暈效果使用 BoxShadow（靜態）
- 避免使用動畫（Widget 轉 Bitmap 後無法動畫）
- 標記尺寸適中，避免過大影響地圖可讀性

---

## 常見問題

### Q: 為什麼 Live 標記不會閃爍？
A: 因為標記是將 Widget 轉換為靜態 Bitmap 圖片後貼到地圖上，無法實作動畫效果。如需動畫，需使用 CustomPainter 或 Canvas API。

### Q: 如何調整 Hot 狀態的觸發門檻？
A: 修改 `_effectiveStatus` 中的判斷條件：
```dart
if (currentCount / maxCount >= 0.7) return ActivityStatus.hot;  // 改為 70%
```

### Q: Cluster 標記何時顯示？
A: 目前 Cluster 標記已實作但尚未整合到地圖。未來會使用 `google_maps_cluster_manager` 套件自動聚合重疊標記。

### Q: 光暈效果在低階裝置會卡頓嗎？
A: BoxShadow 的 `spreadRadius` 在某些裝置可能影響效能。如遇到問題，可以：
1. 減少 `blurRadius` 和 `spreadRadius`
2. 移除光暈效果，僅保留顏色變化
3. 根據裝置效能動態調整

---

## 視覺對比表

| 狀態 | 背景色 | 邊框 | 特效 | 用途 |
|------|--------|------|------|------|
| Normal | 青色 #00D0DD | 白色 2px | 標準陰影 | 一般活動 |
| Hot | 青色 #00D0DD | 橘色 3px | 🔥 emoji | 快滿活動 |
| Live | 紅色 #D32F2F | 白色/紅色 | 紅色光暈 + LIVE 標籤 | 進行中 |
| Cluster | 灰/藍/橘 | 同色 3px | 數字顯示 | 多活動聚合 |

---

## 更新日誌

- **2026-02-03**：初版發布，實作 Normal、Hot、Live、Cluster 四種狀態
- 未來計畫：整合 Cluster Manager、加入動畫效果（可選）
