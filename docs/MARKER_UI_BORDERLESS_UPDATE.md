# Marker UI 調整：無邊框純陰影設計

## 調整目標

將活動 Marker 改成與「2 活動」Cluster 同款設計：
- ✅ 完全不要邊框/描邊/螢光外框
- ✅ 白底卡片 + 柔和陰影
- ✅ 選取狀態用「微放大 + 陰影加深」，不要外框
- ✅ LIVE chip 是唯一的重點色

## 設計規範

### 1. Activity Marker (Normal)

**基本規格：**
```
bg: rgba(255,255,255,0.96)
border: none（完全移除）
radius: 22px (height=44px)
shadow: 雙層陰影
  - elevation: 12
  - shadowColor: rgba(0,0,0,0.14)
  - 效果：0 12 28 rgba(0,0,0,0.14) + 0 3 10 rgba(0,0,0,0.10)
```

**LIVE Chip（唯一重點色）：**
```
bg: #FF4D4F（紅底）
text: white（白字）
height: 24px
radius: 12px
padding: 10px horizontal
```

**人數顏色規則：**
- 預設：深灰 #2D3436
- >=80%：橘紅 #FF6B35
- 已滿：灰色 #9E9E9E

**Anchor Dot（定位點）：**
```
size: 10px
fill: #2D3436（深色）
ring: 2px white
shadow: 0 4 10 rgba(0,0,0,0.18)
不要 ripple 光圈
```

### 2. Activity Marker (Selected)

**選中效果：**
```
scale: 1.04（微放大）
shadow: 加深
  - elevation: 16
  - shadowColor: rgba(0,0,0,0.18)
  - 效果：0 16 34 rgba(0,0,0,0.18) + 0 5 14 rgba(0,0,0,0.12)
```

**重要：**
- ❌ 不加任何外框
- ❌ 不加任何 halo
- ❌ 不加青色效果
- ✅ 只用放大 + 陰影加深

**Anchor Dot（放大版）：**
```
size: 12px（稍微放大）
ring: 2.5px white
shadow: 0 4 12 rgba(0,0,0,0.2)
```

### 3. Cluster Marker（與活動標記同款）

**完全一致的風格：**
```
bg: rgba(255,255,255,0.96)
border: none
radius: 22px (height=44px)
shadow: elevation 12
icon: layers（堆疊圖標）
text: "N 活動"
```

## 技術實作

### 使用 PhysicalModel 產生純陰影

```dart
PhysicalModel(
  color: Colors.white.withOpacity(0.96),
  borderRadius: BorderRadius.circular(22),
  elevation: 12,
  shadowColor: Colors.black.withOpacity(0.14),
  child: Container(
    height: 44,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      // 完全移除 border
    ),
    // ...
  ),
)
```

### 選中狀態的放大效果

```dart
Transform.scale(
  scale: 1.04,
  child: PhysicalModel(
    elevation: 16, // 加深陰影
    shadowColor: Colors.black.withOpacity(0.18),
    // ...
  ),
)
```

### Anchor Dot 實作

```dart
Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: const Color(0xFF2D3436), // 深色
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.white,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.18),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
)
```

## 視覺效果對比

### ❌ 舊設計（已移除）

```
┌─────────────────────┐
│ [圖標] 1/5          │ ← 有青色邊框
└─────────────────────┘
      ↓ 三角形指向
```

問題：
- 有粗邊框（1-2px）
- 選中時有青色外框/halo
- 看起來像貼紙，不夠柔和

### ✅ 新設計（無邊框）

```
  ┌─────────────────┐
  │ [圖標] 1/5      │ ← 無邊框，純陰影
  └─────────────────┘
         ●            ← Anchor dot
```

改善：
- 完全無邊框
- 柔和的陰影浮起效果
- 選中時只放大 + 陰影加深
- 與「2 活動」cluster 風格一致

## 狀態展示

### Normal（一般狀態）

```
┌──────────────┐
│ 🏃 1/5       │  ← 白底 + 柔和陰影
└──────────────┘
      ●
```

### Nearly Full（快滿 >=80%）

```
┌──────────────┐
│ 🏃 4/5       │  ← 人數變橘紅色
└──────────────┘
      ●
```

### Live（進行中）

```
┌──────────────┐
│ [LIVE] 3/5   │  ← LIVE chip 紅底白字
└──────────────┘
      ●
```

### Selected（選中）

```
  ┌────────────────────┐
  │ 🏃 活動名稱 1/5    │  ← 放大 1.04 倍 + 陰影加深
  └────────────────────┘
           ●
```

### Cluster（多活動）

```
┌──────────────┐
│ 📚 2 活動    │  ← 與活動標記同款
└──────────────┘
      ●
```

## 關鍵改善點

### 1. 移除所有邊框

**Before:**
```dart
border: Border.all(
  color: Colors.black.withOpacity(0.05),
  width: 1,
),
```

**After:**
```dart
decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(22),
  // 完全移除 border
),
```

### 2. 選中狀態不用外框

**Before:**
```dart
// ❌ 舊方式：加青色邊框
border: Border.all(
  color: const Color(0xFF00D0DD),
  width: 2,
),
// 或加發光圈
boxShadow: [
  BoxShadow(
    color: const Color(0xFF00D0DD).withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 4,
  ),
],
```

**After:**
```dart
// ✅ 新方式：只用放大 + 陰影加深
Transform.scale(
  scale: 1.04,
  child: PhysicalModel(
    elevation: 16, // 陰影加深
    // 無邊框、無 halo
  ),
)
```

### 3. Anchor Dot 簡化

**Before:**
```dart
// ❌ 舊方式：複雜的多層圓圈
Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    color: const Color(0xFF00D0DD).withOpacity(0.2),
  ),
),
Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: const Color(0xFF00D0DD).withOpacity(0.4),
  ),
),
```

**After:**
```dart
// ✅ 新方式：簡單的小圓點
Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: const Color(0xFF2D3436),
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 2),
  ),
)
```

## 一致性檢查

### 所有標記使用相同的設計語言

| 標記類型 | 背景 | 邊框 | 陰影 | Anchor Dot |
|---------|------|------|------|-----------|
| Activity (Normal) | rgba(255,255,255,0.96) | ❌ 無 | elevation 12 | 10px |
| Activity (Selected) | rgba(255,255,255,0.96) | ❌ 無 | elevation 16 | 12px |
| Cluster | rgba(255,255,255,0.96) | ❌ 無 | elevation 12 | 10px |
| Spiderfy | rgba(255,255,255,0.96) | ❌ 無 | elevation 8 | 8px |

✅ 完全一致的視覺風格

## 驗收標準

- [x] 活動標記完全無邊框
- [x] 選中狀態不加外框/halo/青色效果
- [x] 只用微放大（1.04）+ 陰影加深
- [x] LIVE chip 是唯一的重點色（紅底白字）
- [x] 人數顏色：預設深灰，>=80% 才轉橘紅
- [x] Anchor dot 簡化為 10px 小圓點
- [x] 與「2 活動」cluster 風格完全一致
- [x] 所有標記使用相同的陰影規格

## 總結

通過這次調整，活動 Marker 的設計更加：

1. **統一**：與 Cluster 標記風格完全一致
2. **柔和**：純陰影浮起，無邊框干擾
3. **簡潔**：移除所有不必要的視覺元素
4. **清晰**：LIVE chip 作為唯一重點色，更突出
5. **現代**：符合當代地圖 UI 設計趨勢

新設計讓地圖看起來更乾淨、更專業，視覺層次更清晰！
