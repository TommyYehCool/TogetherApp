# Google Maps API 設定指南

## 功能說明

Together App 使用 Google Maps API 提供以下功能：
1. **地址搜尋**：在建立活動時搜尋地址
2. **自動完成**：輸入時顯示地址建議
3. **反向地理編碼**：將座標轉換為地址
4. **地圖顯示**：顯示活動位置

## 需要啟用的 API

請到 [Google Cloud Console](https://console.cloud.google.com/) 啟用以下 API：

### 1. Places API
- 用途：地址搜尋和自動完成
- 啟用連結：https://console.cloud.google.com/apis/library/places-backend.googleapis.com

### 2. Geocoding API
- 用途：座標 ↔ 地址轉換
- 啟用連結：https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com

### 3. Maps SDK for Android
- 用途：Android 地圖顯示
- 啟用連結：https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com

### 4. Maps SDK for iOS
- 用途：iOS 地圖顯示
- 啟用連結：https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com

### 5. Maps JavaScript API
- 用途：Web 地圖顯示
- 啟用連結：https://console.cloud.google.com/apis/library/maps-backend.googleapis.com

## 設定步驟

### 步驟 1：建立 Google Cloud 專案

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 點擊「選擇專案」→「新增專案」
3. 輸入專案名稱（例如：Together App）
4. 點擊「建立」

### 步驟 2：啟用計費

1. 在左側選單選擇「計費」
2. 連結信用卡（Google 提供 $300 免費額度）
3. 注意：Places API 和 Geocoding API 需要啟用計費才能使用

### 步驟 3：啟用 API

1. 在左側選單選擇「API 和服務」→「程式庫」
2. 搜尋並啟用上述 5 個 API
3. 每個 API 都點擊「啟用」按鈕

### 步驟 4：建立 API 金鑰

1. 在左側選單選擇「API 和服務」→「憑證」
2. 點擊「建立憑證」→「API 金鑰」
3. 複製產生的 API 金鑰

### 步驟 5：限制 API 金鑰（重要！）

為了安全性，建議限制 API 金鑰的使用範圍：

#### Android 限制
1. 點擊剛建立的 API 金鑰
2. 在「應用程式限制」選擇「Android 應用程式」
3. 點擊「新增套件名稱和指紋」
4. 輸入套件名稱：`com.together.app`
5. 取得 SHA-1 指紋：
   ```bash
   # Debug 版本
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release 版本
   keytool -list -v -keystore /path/to/your/keystore -alias your-alias
   ```
6. 複製 SHA-1 指紋並貼上

#### iOS 限制
1. 點擊 API 金鑰
2. 在「應用程式限制」選擇「iOS 應用程式」
3. 輸入 Bundle ID：`com.together.app`

#### API 限制
1. 在「API 限制」選擇「限制金鑰」
2. 勾選以下 API：
   - Places API
   - Geocoding API
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API

### 步驟 6：設定 API 金鑰到專案

#### Flutter 專案
編輯 `lib/widgets/location_picker_dialog.dart`：
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

#### Android
編輯 `android/app/src/main/AndroidManifest.xml`：
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

#### iOS
編輯 `ios/Runner/AppDelegate.swift`：
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Web
編輯 `web/index.html`：
```html
<head>
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
</head>
```

## 費用說明

### 免費額度（每月）

| API | 免費額度 | 超過後費用 |
|-----|---------|-----------|
| Places Autocomplete | 前 1,000 次免費 | $2.83 / 1,000 次 |
| Place Details | 前 1,000 次免費 | $17 / 1,000 次 |
| Geocoding | 前 40,000 次免費 | $5 / 1,000 次 |
| Maps SDK | 前 28,000 次載入免費 | $7 / 1,000 次 |

### 預估使用量

假設 100 個活躍使用者：
- 地址搜尋：100 次/天 × 30 天 = 3,000 次/月
- 地點詳情：100 次/天 × 30 天 = 3,000 次/月
- 反向地理編碼：200 次/天 × 30 天 = 6,000 次/月
- 地圖載入：500 次/天 × 30 天 = 15,000 次/月

**總費用**：約 $0-10 USD/月（大部分在免費額度內）

### 節省費用的建議

1. **快取地址**：將常用地址快取到資料庫
2. **限制搜尋頻率**：使用防抖動（debounce）
3. **限制搜尋範圍**：只搜尋台灣地區
4. **使用 Session Token**：Places API 提供 session token 可節省費用

## 測試 API 金鑰

### 測試 Places Autocomplete
```bash
curl "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=台北101&key=YOUR_API_KEY&language=zh-TW"
```

### 測試 Geocoding
```bash
curl "https://maps.googleapis.com/maps/api/geocode/json?address=台北101&key=YOUR_API_KEY&language=zh-TW"
```

### 測試 Place Details
```bash
curl "https://maps.googleapis.com/maps/api/place/details/json?place_id=PLACE_ID&key=YOUR_API_KEY&language=zh-TW"
```

## 常見問題

### Q: API 金鑰無效？
A: 確認已啟用所有必要的 API，並等待 5-10 分鐘讓設定生效。

### Q: 超過免費額度怎麼辦？
A: 可以設定預算警示，在 Google Cloud Console 的「計費」→「預算與警示」設定。

### Q: 如何監控使用量？
A: 在 Google Cloud Console 的「API 和服務」→「資訊主頁」查看使用量統計。

### Q: 可以使用多個 API 金鑰嗎？
A: 可以，建議為不同環境（開發、測試、正式）使用不同的 API 金鑰。

## 安全性建議

1. **不要將 API 金鑰提交到 Git**
   - 使用環境變數或設定檔
   - 加入 `.gitignore`

2. **定期輪換 API 金鑰**
   - 每 3-6 個月更換一次

3. **監控異常使用**
   - 設定使用量警示
   - 定期檢查 API 使用記錄

4. **使用 API 限制**
   - 限制 HTTP referrer（Web）
   - 限制 Bundle ID（iOS）
   - 限制套件名稱和 SHA-1（Android）

## 參考資源

- [Google Maps Platform 文件](https://developers.google.com/maps/documentation)
- [Places API 文件](https://developers.google.com/maps/documentation/places/web-service)
- [Geocoding API 文件](https://developers.google.com/maps/documentation/geocoding)
- [定價說明](https://developers.google.com/maps/billing-and-pricing/pricing)
- [最佳實踐](https://developers.google.com/maps/documentation/places/web-service/best-practices)
