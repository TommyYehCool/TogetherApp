# 🚀 Together App - 快速啟動指南

## 5 分鐘快速上手

### 步驟 1: 安裝依賴 (1 分鐘)
```bash
flutter pub get
```

### 步驟 2: 設定 Google Maps API Key (2 分鐘)

#### 取得 API Key
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立專案 → 啟用 Maps SDK for Android/iOS
3. 建立 API Key

#### Android 設定
編輯 `android/app/src/main/AndroidManifest.xml`，找到這行：
```xml
android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"
```
替換為你的 API Key。

#### iOS 設定
編輯 `ios/Runner/AppDelegate.swift`，找到這行：
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
```
替換為你的 API Key。

### 步驟 3: 執行應用程式 (2 分鐘)
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# 或讓 Flutter 自動選擇
flutter run
```

---

## 🎯 核心功能測試

### 1. 查看地圖與活動標記
- ✅ 應用程式啟動後會自動顯示地圖
- ✅ 地圖上會顯示 3 個測試活動（Mock 資料）
- ✅ 標記為膠囊形狀，顯示標題和人數

### 2. 查看活動詳情
- ✅ 點擊任一標記
- ✅ 底部面板會向上滑出
- ✅ 顯示活動完整資訊

### 3. 建立新活動
- ✅ 點擊右下角「建立活動」按鈕
- ✅ 填寫表單
- ✅ 點擊「建立活動」
- ✅ 地圖會更新顯示新活動

### 4. 加入活動
- ✅ 在活動詳情面板中
- ✅ 點擊「加入活動」按鈕
- ✅ 會顯示成功訊息（目前為 Mock）

---

## 📱 測試裝置建議

### Android
- 實體裝置（推薦）
- Android 模擬器（需啟用 Google Play Services）

### iOS
- 實體裝置（推薦）
- iOS 模擬器

---

## 🐛 遇到問題？

### 問題 1: 地圖無法顯示
**解決方案**: 檢查 API Key 是否正確設定

### 問題 2: 無法取得位置
**解決方案**: 
- 檢查裝置位置服務是否開啟
- 授予應用程式位置權限

### 問題 3: 標記無法顯示
**解決方案**: 
- 執行 `flutter clean`
- 重新執行 `flutter pub get`
- 重新啟動應用程式

### 問題 4: 編譯錯誤
**解決方案**:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 更多資訊

- **完整設定指南**: 參考 `SETUP_GUIDE.md`
- **專案結構**: 參考 `PROJECT_STRUCTURE.md`
- **實作總結**: 參考 `IMPLEMENTATION_SUMMARY.md`
- **API 規格**: 參考 `api_specs.md`

---

## 🎉 成功啟動！

如果你看到地圖和活動標記，恭喜！你已經成功啟動 Together App。

現在你可以：
1. 探索現有的 Mock 活動
2. 建立新活動
3. 測試 UI 互動
4. 準備整合真實後端 API

---

**需要協助？** 查看 `SETUP_GUIDE.md` 的常見問題章節。
