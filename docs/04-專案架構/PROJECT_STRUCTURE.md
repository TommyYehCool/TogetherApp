# Together 專案結構

## 📁 專案目錄結構

```
TogetherApp/
├── lib/
│   ├── main.dart                          # 應用程式入口點
│   ├── models/
│   │   └── activity.dart                  # 活動資料模型
│   ├── services/
│   │   ├── api_service.dart              # API 服務層（含 Mock 資料）
│   │   └── activity_service.dart         # 活動狀態管理服務
│   ├── screens/
│   │   └── home_screen.dart              # 主畫面（地圖視圖）
│   └── widgets/
│       ├── activity_marker_widget.dart   # 膠囊形狀的地圖標記
│       ├── activity_detail_panel.dart    # 活動詳情滑動面板
│       └── create_activity_dialog.dart   # 建立活動對話框
│
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml           # Android 權限與設定
│
├── ios/
│   └── Runner/
│       ├── Info.plist                    # iOS 權限與設定
│       └── AppDelegate.swift             # iOS 應用程式委派
│
├── pubspec.yaml                          # Flutter 依賴套件設定
├── README.md                             # 專案說明文件
├── SETUP_GUIDE.md                        # 設定指南
├── PROJECT_STRUCTURE.md                  # 本檔案
├── api_specs.md                          # API 規格文件
├── ui_design_specs.md                    # UI/UX 設計規範
└── Together 專案提案書.md                 # 產品提案書
```

---

## 📄 核心檔案說明

### 1. `lib/main.dart`
- 應用程式的入口點
- 設定 Provider 狀態管理
- 定義應用程式主題（色彩、字型等）
- 設定路由（目前只有 HomeScreen）

### 2. `lib/models/activity.dart`
**Activity 資料模型**，包含：
- 活動基本資訊（ID、標題、描述）
- 地理位置（經緯度）
- 時間資訊（開始時間）
- 參與者資訊（當前人數、上限）
- 主辦人資訊
- Boost 狀態
- JSON 序列化/反序列化方法

### 3. `lib/services/api_service.dart`
**API 服務層**，負責：
- 與後端 API 通訊（使用 Dio）
- 取得附近活動 (`GET /activities/nearby`)
- 建立新活動 (`POST /activities`)
- 加入活動 (`POST /activities/:id/join`)
- **Mock 資料**：當 API 未就緒時提供測試資料

### 4. `lib/services/activity_service.dart`
**狀態管理服務**（使用 Provider），管理：
- 活動列表狀態
- 當前選中的活動
- 載入狀態
- 提供方法給 UI 層呼叫

### 5. `lib/screens/home_screen.dart`
**主畫面**，包含：
- 全螢幕 Google Map
- 自訂活動標記顯示
- 滑動面板整合
- 頂部搜尋列
- 浮動按鈕（我的位置、建立活動）
- 位置權限處理

### 6. `lib/widgets/activity_marker_widget.dart`
**膠囊標記元件**，特色：
- Stadium 形狀（藥丸/膠囊）
- 顯示活動標題 + 參與人數
- 支援 Boosted 狀態（金色邊框）
- 已額滿狀態（灰色）
- 使用 `widget_to_marker` 轉換為地圖標記

### 7. `lib/widgets/activity_detail_panel.dart`
**活動詳情面板**，功能：
- 使用 `SlidingUpPanel` 實作
- 顯示活動完整資訊
- 類別標籤、Boosted 標籤
- 時間、人數、主辦人資訊
- 「加入活動」按鈕（含狀態處理）

### 8. `lib/widgets/create_activity_dialog.dart`
**建立活動對話框**，包含：
- 底部彈出式表單
- 活動標題輸入
- 類別選擇（下拉選單）
- 活動說明（多行輸入）
- 人數上限（滑桿）
- 開始時間（日期時間選擇器）
- 表單驗證

---

## 🎨 設計系統

### 色彩定義
```dart
// 主色調
Color(0xFF00D0DD)  // 青綠色 - 按鈕、強調色

// 文字
Color(0xFF2D3436)  // 深灰色 - 主要文字
Colors.grey[700]   // 次要文字

// 背景
Colors.white       // 主要背景
Colors.grey[300]   // 已額滿狀態
```

### 圓角規範
- 按鈕：28px
- 卡片/面板：24px
- 標籤：20px
- 膠囊標記：100px（完全圓角）

### 間距規範
- 小間距：8px
- 中間距：16px
- 大間距：24px

---

## 🔌 依賴套件

### 核心套件
| 套件 | 版本 | 用途 |
|------|------|------|
| `google_maps_flutter` | ^2.5.0 | Google 地圖整合 |
| `dio` | ^5.4.0 | HTTP 網路請求 |
| `provider` | ^6.1.1 | 狀態管理 |
| `sliding_up_panel` | ^2.0.0+1 | 滑動面板 UI |
| `widget_to_marker` | ^1.0.3 | Widget 轉地圖標記 |
| `geolocator` | ^10.1.0 | 地理定位 |
| `permission_handler` | ^11.1.0 | 權限管理 |
| `intl` | ^0.18.1 | 國際化與日期格式 |

---

## 🔄 資料流程

### 1. 載入附近活動
```
HomeScreen (initState)
    ↓
ActivityService.loadNearbyActivities()
    ↓
ApiService.getNearbyActivities()
    ↓ (如果 API 失敗)
_getMockActivities() [Mock 資料]
    ↓
ActivityService 更新狀態
    ↓
HomeScreen._updateMarkers()
    ↓
地圖顯示標記
```

### 2. 點擊標記查看詳情
```
使用者點擊地圖標記
    ↓
Marker.onTap()
    ↓
ActivityService.selectActivity()
    ↓
PanelController.open()
    ↓
ActivityDetailPanel 顯示
```

### 3. 加入活動
```
使用者點擊「加入活動」
    ↓
ActivityDetailPanel._joinActivity()
    ↓
ActivityService.joinActivity()
    ↓
ApiService.joinActivity()
    ↓
顯示成功/失敗訊息
```

### 4. 建立活動
```
使用者點擊「建立活動」FAB
    ↓
顯示 CreateActivityDialog
    ↓
使用者填寫表單
    ↓
ActivityService.createActivity()
    ↓
ApiService.createActivity()
    ↓
HomeScreen._updateMarkers()
    ↓
地圖更新顯示新活動
```

---

## 🚀 開發流程

### 階段 1：環境設定 ✅
- [x] 建立 Flutter 專案結構
- [x] 設定依賴套件
- [x] 設定 Android/iOS 權限

### 階段 2：核心功能 ✅
- [x] Activity 資料模型
- [x] API 服務層（含 Mock）
- [x] 狀態管理服務
- [x] 膠囊標記元件

### 階段 3：UI 實作 ✅
- [x] 地圖主畫面
- [x] 活動詳情面板
- [x] 建立活動對話框
- [x] 頂部搜尋列
- [x] 浮動按鈕

### 階段 4：整合測試（待完成）
- [ ] 真實 API 整合
- [ ] 使用者認證
- [ ] 錯誤處理優化
- [ ] 效能優化

### 階段 5：進階功能（待完成）
- [ ] 活動篩選
- [ ] 聊天室
- [ ] 推播通知
- [ ] Boost 付費功能

---

## 📝 開發注意事項

### Mock 資料
目前 `ApiService` 包含 Mock 資料，位於 `_getMockActivities()` 方法。
當後端 API 就緒後，可以移除此方法的 fallback 邏輯。

### Google Maps API Key
**重要**：不要將 API Key 提交到版本控制！
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/AppDelegate.swift`

這些檔案已加入 `.gitignore`。

### 權限處理
應用程式需要以下權限：
- **定位權限**：取得使用者位置
- **網路權限**：API 請求

已在 `AndroidManifest.xml` 和 `Info.plist` 中設定。

### 狀態管理
使用 Provider 進行簡單的狀態管理：
- `ActivityService` 管理活動相關狀態
- 使用 `ChangeNotifier` 通知 UI 更新
- 使用 `Consumer` 或 `context.watch()` 監聽變化

---

## 🐛 除錯技巧

### 查看 Console 輸出
```bash
flutter run --verbose
```

### 檢查網路請求
在 `ApiService` 中加入 Dio 攔截器：
```dart
_dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

### 檢查地圖標記
在 `_updateMarkers()` 中加入 print：
```dart
print('載入 ${activities.length} 個活動');
print('建立 ${newMarkers.length} 個標記');
```

### 檢查狀態更新
在 `ActivityService` 中加入 print：
```dart
@override
void notifyListeners() {
  print('ActivityService 狀態更新');
  super.notifyListeners();
}
```

---

## 📚 參考資源

- [Flutter 官方文件](https://flutter.dev/docs)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Provider 套件](https://pub.dev/packages/provider)
- [Dio 網路請求](https://pub.dev/packages/dio)
- [Material Design 3](https://m3.material.io/)
