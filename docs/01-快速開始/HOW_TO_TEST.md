# 🧪 如何測試 Together App

## 📋 測試前準備

### 1️⃣ 檢查環境
```bash
# 執行環境檢查腳本
check_environment.bat
```

### 2️⃣ 安裝 Flutter（如果尚未安裝）
👉 **詳細步驟**：參考 [INSTALL_FLUTTER.md](INSTALL_FLUTTER.md)

**快速安裝**：
1. 下載 Flutter SDK：https://docs.flutter.dev/get-started/install/windows
2. 解壓縮到 `C:\src\flutter`
3. 將 `C:\src\flutter\bin` 加入 PATH 環境變數
4. 執行 `flutter doctor` 驗證

### 3️⃣ 安裝專案依賴
```bash
cd C:\work\other\TogetherApp
flutter pub get
```

---

## 🚀 三種測試方式

### 方式 A：Chrome 瀏覽器（最快速）⚡

**優點**：最快、不需要模擬器  
**缺點**：地圖功能可能受限

```bash
# 1. 啟用 Web 支援
flutter config --enable-web

# 2. 在 Chrome 中執行
flutter run -d chrome
```

---

### 方式 B：Android 模擬器（推薦）📱

**優點**：完整功能、接近真實體驗  
**缺點**：需要 Android Studio

**步驟**：
1. 安裝 Android Studio
2. 在 Android Studio 中建立並啟動模擬器
3. 執行：
   ```bash
   flutter run
   ```

---

### 方式 C：實體手機（最佳）🎯

**優點**：最佳效能、真實體驗  
**缺點**：需要實體裝置

**Android 手機步驟**：
1. 開啟「開發者選項」
2. 啟用「USB 偵錯」
3. 用 USB 連接電腦
4. 執行：
   ```bash
   flutter run
   ```

---

## 🎯 測試功能清單

### ✅ 基本功能
- [ ] 應用程式成功啟動
- [ ] 地圖正常顯示
- [ ] 看到 3 個測試活動標記（膠囊形狀）
- [ ] 標記顏色正確（青綠色邊框）

### ✅ 互動功能
- [ ] 點擊標記，底部面板滑出
- [ ] 查看活動詳情（標題、時間、人數）
- [ ] 點擊「建立活動」按鈕
- [ ] 填寫並提交建立活動表單
- [ ] 點擊「加入活動」按鈕

### ✅ UI 檢查
- [ ] 頂部搜尋列顯示正常
- [ ] 「我的位置」按鈕可點擊
- [ ] 「建立活動」按鈕可點擊
- [ ] 色彩符合設計（青綠色 #00D0DD）
- [ ] 圓角和陰影效果正確

---

## 🔧 設定 Google Maps API Key（重要）

### 取得 API Key
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立專案
3. 啟用 Maps SDK for Android/iOS
4. 建立 API Key

### 設定 API Key

**Android**：
編輯 `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="你的_API_KEY"/>
```

**iOS**：
編輯 `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("你的_API_KEY")
```

---

## 🐛 遇到問題？

### Flutter 命令找不到
```bash
# 檢查 Flutter 是否在 PATH 中
echo %PATH%

# 重新開啟終端機後再試
```

### 依賴安裝失敗
```bash
flutter clean
flutter pub get
```

### 地圖無法顯示
- 檢查 API Key 是否正確
- 確認網路連線
- 查看 Console 錯誤訊息

### 標記無法顯示
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 詳細文件

- **完整測試指南**：[TESTING_GUIDE.md](TESTING_GUIDE.md)
- **Flutter 安裝**：[INSTALL_FLUTTER.md](INSTALL_FLUTTER.md)
- **快速開始**：[QUICK_START.md](QUICK_START.md)
- **設定指南**：[SETUP_GUIDE.md](SETUP_GUIDE.md)

---

## 🎉 測試成功！

如果你看到：
- ✅ 地圖正常顯示
- ✅ 3 個膠囊形狀的活動標記
- ✅ 可以點擊標記查看詳情
- ✅ 可以建立新活動

**恭喜！Together App 運作正常！** 🎊

---

## 📞 需要協助？

1. 查看 [TESTING_GUIDE.md](TESTING_GUIDE.md) 的常見問題章節
2. 查看 [SETUP_GUIDE.md](SETUP_GUIDE.md) 的 FAQ
3. 參考 Flutter 官方文件：https://flutter.dev/docs

---

**祝測試順利！** 🚀
