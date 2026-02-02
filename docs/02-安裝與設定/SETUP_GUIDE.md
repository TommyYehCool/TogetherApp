# Together App 設定指南

## 快速開始

### 1. 環境需求
- Flutter SDK 3.0.0 或更高版本
- Dart SDK 3.0.0 或更高版本
- Android Studio / Xcode（依據目標平台）
- Google Maps API Key

### 2. 取得 Google Maps API Key

#### 步驟：
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立新專案或選擇現有專案
3. 啟用以下 API：
   - Maps SDK for Android
   - Maps SDK for iOS
4. 建立 API Key（憑證）
5. 設定 API Key 的使用限制（建議限制應用程式）

### 3. 設定 API Key

#### Android
編輯 `android/app/src/main/AndroidManifest.xml`：
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="你的_GOOGLE_MAPS_API_KEY"/>
```

#### iOS
1. 編輯 `ios/Runner/AppDelegate.swift`：
```swift
import UIKit
import Flutter
import GoogleMaps  // 加入這行

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("你的_GOOGLE_MAPS_API_KEY")  // 加入這行
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

2. 編輯 `ios/Podfile`，確保有以下設定：
```ruby
platform :ios, '12.0'
```

### 4. 安裝依賴套件
```bash
flutter pub get
```

### 5. 執行應用程式

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

#### 模擬器
```bash
# 列出可用裝置
flutter devices

# 在特定裝置上執行
flutter run -d <device_id>
```

---

## 功能測試清單

### ✅ 基本功能
- [ ] 應用程式啟動成功
- [ ] 地圖正常顯示
- [ ] 取得使用者位置權限
- [ ] 地圖移動到使用者位置

### ✅ 活動標記
- [ ] 地圖上顯示活動標記（膠囊形狀）
- [ ] 標記顯示活動標題和人數
- [ ] Boosted 活動顯示金色邊框
- [ ] 已額滿活動顯示灰色
- [ ] 點擊標記開啟詳情面板

### ✅ 活動詳情
- [ ] 滑動面板正常開啟/關閉
- [ ] 顯示活動完整資訊
- [ ] 「加入活動」按鈕可點擊
- [ ] 已額滿活動按鈕顯示為禁用狀態

### ✅ 建立活動
- [ ] 點擊「建立活動」按鈕開啟表單
- [ ] 所有欄位正常輸入
- [ ] 日期時間選擇器正常運作
- [ ] 人數滑桿正常調整
- [ ] 表單驗證正常運作
- [ ] 建立成功後地圖更新

### ✅ UI/UX
- [ ] 頂部搜尋列正常顯示
- [ ] 「我的位置」按鈕正常運作
- [ ] 所有按鈕和互動符合設計規範
- [ ] 色彩使用正確（主色調 #00D0DD）
- [ ] 圓角和陰影效果正確

---

## 常見問題

### Q1: 地圖無法顯示
**A**: 檢查以下項目：
1. Google Maps API Key 是否正確設定
2. API Key 是否已啟用 Maps SDK
3. 網路連線是否正常
4. 檢查 Console 是否有錯誤訊息

### Q2: 無法取得位置
**A**: 確認：
1. AndroidManifest.xml 和 Info.plist 已設定位置權限
2. 裝置/模擬器的位置服務已開啟
3. 應用程式已授予位置權限

### Q3: 標記無法顯示
**A**: 檢查：
1. `widget_to_marker` 套件是否正確安裝
2. 活動資料是否正確載入
3. Console 是否有錯誤訊息

### Q4: iOS 編譯失敗
**A**: 嘗試：
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### Q5: Android 編譯失敗
**A**: 檢查：
1. `android/build.gradle` 的 Gradle 版本
2. `android/app/build.gradle` 的 minSdkVersion（建議 21+）
3. 執行 `flutter clean` 後重新編譯

---

## 開發模式

### Mock 資料模式
目前 `ApiService` 會在 API 連線失敗時自動使用 Mock 資料，方便開發測試。

Mock 資料位置：`lib/services/api_service.dart` 的 `_getMockActivities()` 方法

### 切換到真實 API
當後端 API 就緒後：
1. 更新 `lib/services/api_service.dart` 中的 `baseUrl`
2. 確認 API 端點符合 `api_specs.md` 的規格
3. 移除或註解 Mock 資料的 fallback 邏輯

---

## 效能優化建議

### 地圖效能
- 限制同時顯示的標記數量（建議 < 100）
- 使用地圖的 Cluster 功能（未來實作）
- 根據地圖縮放等級調整標記顯示

### 網路請求
- 實作請求快取機制
- 加入請求防抖（debounce）
- 使用分頁載入活動資料

### 記憶體管理
- 及時釋放不需要的資源
- 優化圖片大小和格式
- 使用 `const` 建構子減少重建

---

## 下一步開發

### 優先級 P0（MVP 必須）
- [ ] 使用者認證系統
- [ ] 真實 API 整合
- [ ] 活動聊天室
- [ ] 推播通知

### 優先級 P1（重要）
- [ ] 活動篩選功能
- [ ] 使用者個人頁面
- [ ] 活動歷史記錄
- [ ] Boost 付費功能

### 優先級 P2（加分）
- [ ] 社交分享功能
- [ ] 活動評價系統
- [ ] 好友系統
- [ ] 活動推薦演算法

---

## 聯絡與支援

如有任何問題，請參考：
- [Flutter 官方文件](https://flutter.dev/docs)
- [Google Maps Flutter 套件](https://pub.dev/packages/google_maps_flutter)
- [Provider 狀態管理](https://pub.dev/packages/provider)
