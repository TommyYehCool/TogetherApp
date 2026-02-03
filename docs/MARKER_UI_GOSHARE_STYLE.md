# Marker UI 設計規範 - GoShare 風格

## 問題定義與解決方案

### 原問題：圓角後仍出現方形 90° 陰影

**原因：**
- shadow 套在「外層矩形容器」但圓角只套在「內層」
- 使用 ClipRRect 只裁內容，陰影仍是矩形
- Material elevation 沒有指定 shape（預設矩形）
- marker 用 PNG/bitmap 且陰影已被烘焙或 padding 不夠造成裁切

**解決方案：**
✅ 使用 `PhysicalModel(borderRadius, elevation)` 確保陰影跟隨圓角
✅ 不在外層 Container 用 boxShadow + 內層 ClipRRect
✅ 輸出 bitmap 時留足透明 padding（至少 blurRadius * 2~3）
✅ 以 3x scale 輸出避免鋸齒

---

## 設計規範

### 1. 活動膠囊標記（ActivityPillMarker）

**規格：**
```
height: 44px
radius: 22px (完全圓角)
bg: rgba(255,255,255,0.95)
border: 1px rgba(0,0,0,0.05)
shadow: 雙層陰影（自然浮起效果）
  - elevation: 8
  - shadowColor: rgba(0,0,0,0.14)
```

**Anchor Dot（定位點）：**
```
size: 12x12
color: #00D0DD
border: 2px white
shadow: 0 4 10 rgba(0,0,0,0.18)
position: 底部中心
```

**人數文案顏色規則：**
- 正常：深灰 #2D3436
- 快滿（>=80%）：橘紅 #FF6B35
- 已滿：灰色 #9E9E9E

**LIVE Chip：**
```
height: 24px
radius: 12px
bg: #FF4D4F
text: white, 12px, semibold
paddingX: 10px
elevation: 2
```

---

### 2. Cluster 膠囊標記（ClusterPillMarker）

**設計理念：**
不再使用巨大數字泡泡（像資料提示），改用小膠囊顯示「2 活動」，統一視覺語言。

**規格：**
```
height: 44px
radius: 22px
bg: rgba(255,255,255,0.95)
border: 1px rgba(0,0,0,0.05)
shadow: elevation 8
icon: layers (堆疊圖標)
text: "N 活動"
```

**互動：**
點擊 cluster → 開 bottom sheet 列表

---

### 3. 選中狀態標記（SelectedActivityMarker）

**特點：**
- 高亮 + 發光圈效果
- 顯示完整資訊：圖標 + 標題 + 人數
- 更大的尺寸和更高的 elevation

**規格：**
```
height: 52px
radius: 26px
bg: white
border: 2px #00D0DD
shadow: elevation 12
glow: 發光圈（外層）
  - color: rgba(0,209,221,0.3)
  - blurRadius: 20
  - spreadRadius: 4
```

**Anchor Dot（放大版）：**
```
size: 14x14
border: 2.5px white
shadow: 0 4 12 rgba(0,0,0,0.2)
```

---

## 技術實作要點

### 1. 使用 PhysicalModel 產生正確的圓角陰影

```dart
PhysicalModel(
  color: Colors.white.withOpacity(0.95),
  borderRadius: BorderRadius.circular(22),
  elevation: 8,
  shadowColor: Colors.black.withOpacity(0.14),
  child: Container(
    // 內容
  ),
)
```

### 2. 輸出 BitmapDescriptor 時留足 padding

```dart
.toBitmapDescriptor(
  logicalSize: const Size(100, 70),  // 留足空間給陰影
  imageSize: const Size(300, 210),   // 3x 高解析度
)
```

### 3. Anchor 錨點設定

```dart
Marker(
  anchor: const Offset(0.5, 0.85),  // 錨點在 anchor dot 位置
  // 讓標記像地圖釘，不像 banner
)
```

---

## 視覺效果對比

### ❌ 舊設計問題

1. **方形陰影殘影**
   - 使用 Container boxShadow + ClipRRect
   - 陰影不跟隨圓角

2. **粗紅外框貼紙感**
   - 粗邊框（2-3px）
   - 顏色過於鮮豔
   - 看起來像貼紙，不像浮起的元素

3. **巨大數字泡泡**
   - Cluster 顯示大圓圈 + 數字
   - 像資料提示，不像活動

### ✅ 新設計優勢

1. **完美圓角陰影**
   - 使用 PhysicalModel
   - 陰影完全跟隨圓角
   - 自然的浮起效果

2. **柔和的視覺層次**
   - 細邊框（1px，幾乎不可見）
   - 雙層陰影（更自然）
   - 半透明白色背景（0.95 opacity）

3. **統一的視覺語言**
   - Cluster 也用膠囊設計
   - 所有標記風格一致
   - Anchor dot 讓它像地圖釘

---

## 狀態展示

### Normal（正常狀態）
```
[圖標] 1/5
顏色：深灰 #2D3436
```

### Nearly Full（快滿，>=80%）
```
[圖標] 4/5
顏色：橘紅 #FF6B35
```

### Full（已滿）
```
[圖標] 5/5
顏色：灰色 #9E9E9E
互動：disable
```

### Live（進行中）
```
[LIVE] 3/5
LIVE chip：紅色 #FF4D4F
```

### Selected（選中）
```
[圖標] 標題 1/5
發光圈 + 放大 + 完整資訊
```

### Cluster（多活動）
```
[堆疊圖標] 2 活動
點擊 → 開列表
```

---

## 驗收標準

### ✅ 必過項目

1. **陰影正確性**
   - [ ] marker 圓角陰影不再出現四角方形殘影
   - [ ] 陰影完全跟隨 borderRadius
   - [ ] 在白色和深色背景上都清晰可見

2. **視覺效果**
   - [ ] marker 在地圖上看起來「浮起」而不是「貼紙」
   - [ ] 沒有粗紅外框的貼紙感
   - [ ] Anchor dot 讓標記像地圖釘

3. **一致性**
   - [ ] 單一活動 marker 與 cluster marker 風格一致
   - [ ] 所有狀態（normal/nearly_full/full/live）視覺統一

4. **互動性**
   - [ ] 點 cluster 出列表
   - [ ] 點列表 item 高亮/定位對應活動
   - [ ] 選中狀態有明顯的視覺回饋

---

## 交付物

### 已完成

1. ✅ ActivityPillMarker - 活動膠囊標記
   - Normal / Nearly Full / Full 三種狀態
   - LIVE chip 內嵌顯示
   - Anchor dot 定位點

2. ✅ ClusterPillMarker - Cluster 膠囊標記
   - 統一視覺語言
   - 顯示「N 活動」文字
   - 堆疊圖標

3. ✅ SelectedActivityMarker - 選中狀態標記
   - 發光圈效果
   - 完整資訊顯示
   - 放大尺寸

4. ✅ SpiderfyMarker - 扇形展開標記
   - 小膠囊設計
   - 短標題 + 人數

### 技術實作

- ✅ 使用 PhysicalModel 確保陰影跟隨圓角
- ✅ 留足透明 padding 避免陰影被裁切
- ✅ 3x 高解析度輸出避免鋸齒
- ✅ 正確的 anchor 錨點設定

---

## 參考案例

- **GoShare**：地圖標記的柔和陰影和浮起效果
- **Airbnb**：膠囊形標記設計
- **Google Maps**：Anchor dot 定位點設計

---

## 後續優化建議

### 動畫效果
- 標記出現時的彈性動畫
- 選中時的放大動畫
- LIVE chip 的脈衝效果

### 進階功能
- 根據地圖縮放等級動態調整標記大小
- 標記聚合時的平滑過渡動畫
- 長按標記顯示快速預覽

### 性能優化
- 標記 bitmap 快取機制
- 視窗外標記的延遲載入
- 大量標記時的分批渲染
