# 加入請求 UI 修正

## 問題描述

「加入請求」對話框的 UI 有以下問題：

1. **按鈕被截斷**：「批准」按鈕顯示不完整，右側被截斷
2. **佈局擁擠**：使用 `ListTile` 的 `trailing` 導致空間不足
3. **視覺不一致**：與其他對話框的設計風格不統一

### 原始問題截圖分析

```
[頭像] 使用者          [批准] ← 按鈕被截斷
       時間戳記
```

## 根本原因

### 1. ListTile trailing 空間限制

```dart
// ❌ 問題代碼
ListTile(
  leading: const CircleAvatar(child: Icon(Icons.person)),
  title: Text(request['user_name'] ?? '使用者'),
  subtitle: Text(request['requested_at'] ?? ''),
  trailing: ElevatedButton(  // trailing 空間有限
    child: const Text('批准'),
  ),
)
```

`ListTile` 的 `trailing` 屬性有固定的最大寬度限制，當按鈕文字較長或需要 padding 時，會被截斷。

### 2. 缺少適當的 padding 和間距

原始設計沒有考慮到：
- 按鈕需要足夠的 padding（左右各 20px）
- 元素之間需要適當的間距
- 對話框內容需要適當的 padding

## 解決方案

### 使用自訂 Row 佈局取代 ListTile

```dart
// ✅ 修正後的代碼
Row(
  children: [
    // 使用者頭像
    CircleAvatar(
      backgroundColor: const Color(0xFF00D0DD).withOpacity(0.1),
      child: const Icon(Icons.person, color: Color(0xFF00D0DD)),
    ),
    const SizedBox(width: 12),
    
    // 使用者資訊（可擴展）
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
    
    // 批准按鈕（固定寬度）
    ElevatedButton(
      onPressed: () async { /* ... */ },
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
)
```

## 改善項目

### 1. 佈局優化

**使用 Row + Expanded：**
- 頭像：固定寬度（40px）
- 使用者資訊：可擴展（Expanded）
- 批准按鈕：固定寬度（根據內容 + padding）

**間距設定：**
- 元素之間：12px
- 按鈕 padding：horizontal 20px, vertical 10px
- 列表項 padding：vertical 8px

### 2. 視覺改善

**頭像樣式：**
```dart
CircleAvatar(
  backgroundColor: const Color(0xFF00D0DD).withOpacity(0.1),
  child: const Icon(Icons.person, color: Color(0xFF00D0DD)),
)
```
- 使用品牌色的淡背景
- 圖標使用品牌色

**按鈕樣式：**
```dart
ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF00D0DD),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
)
```
- 圓角 8px（更現代）
- 足夠的 padding
- 明確的前景色和背景色

**文字樣式：**
- 使用者名稱：15px, fontWeight.w600
- 時間戳記：12px, grey[600]
- 按鈕文字：14px, fontWeight.w600

### 3. 分隔線

```dart
ListView.separated(
  separatorBuilder: (context, index) => const Divider(height: 1),
  // ...
)
```
使用 `separated` 建構器在項目之間加入分隔線，視覺更清晰。

### 4. 對話框 padding

```dart
AlertDialog(
  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
  // ...
)
```
自訂 padding 確保內容不會太擁擠。

## 視覺效果對比

### ❌ 修正前

```
┌─────────────────────────────────┐
│ 加入請求                         │
├─────────────────────────────────┤
│ [👤] 使用者          [批准]← 截斷│
│      02/03 16:40                │
├─────────────────────────────────┤
│                          [關閉]  │
└─────────────────────────────────┘
```

問題：
- 按鈕被截斷
- 佈局擁擠
- 視覺不清晰

### ✅ 修正後

```
┌─────────────────────────────────┐
│ 加入請求                         │
├─────────────────────────────────┤
│ [👤]  使用者              [批准] │
│       02/03 16:40               │
├─────────────────────────────────┤
│ [👤]  使用者              [批准] │
│       02/03 16:40               │
├─────────────────────────────────┤
│                          [關閉]  │
└─────────────────────────────────┘
```

改善：
- 按鈕完整顯示
- 間距適當
- 視覺清晰
- 有分隔線

## 互動改善

### 成功回饋

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('已批准加入'),
    backgroundColor: Color(0xFF00D0DD),  // 使用品牌色
  ),
);
```

批准成功後：
1. 關閉對話框
2. 顯示品牌色的 SnackBar
3. 提供明確的成功訊息

### 關閉按鈕樣式

```dart
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
)
```

使用品牌色和適當的字重，與整體設計一致。

## 響應式設計

### 處理長使用者名稱

```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        request['user_name'] ?? '使用者',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,  // 自動截斷過長文字
        maxLines: 1,
      ),
      // ...
    ],
  ),
)
```

使用 `Expanded` 確保：
- 使用者名稱可以佔用可用空間
- 過長的名稱會自動截斷（...）
- 按鈕始終有足夠空間顯示

## 測試檢查清單

- [ ] 按鈕完整顯示，沒有被截斷
- [ ] 使用者名稱正常顯示（包括長名稱）
- [ ] 時間戳記正確顯示
- [ ] 分隔線清晰可見
- [ ] 點擊批准按鈕正常運作
- [ ] 成功訊息正確顯示
- [ ] 對話框可以正常關閉
- [ ] 在不同螢幕尺寸下都正常顯示

## 總結

通過以下改善，「加入請求」對話框的 UI 問題已完全修正：

1. ✅ 使用自訂 Row 佈局取代 ListTile
2. ✅ 適當的間距和 padding
3. ✅ 清晰的視覺層次
4. ✅ 一致的品牌色使用
5. ✅ 響應式設計（處理長文字）
6. ✅ 明確的互動回饋

新的設計更現代、更清晰，並且與整體 App 的設計風格保持一致。
