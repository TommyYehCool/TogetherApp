# 📦 Flutter 安裝指南（Windows）

## 🎯 目標
在你的 Windows 系統上安裝 Flutter，以便測試 Together App。

---

## ⏱️ 預計時間
- **快速安裝**：30-45 分鐘
- **完整安裝**（含 Android Studio）：1-2 小時

---

## 📋 系統需求

### 最低需求
- **作業系統**：Windows 10 或更新版本（64-bit）
- **磁碟空間**：至少 2.5 GB（不含 IDE 和工具）
- **工具**：PowerShell 5.0 或更新版本

### 建議配置
- **RAM**：8 GB 或以上
- **磁碟空間**：10 GB 或以上
- **處理器**：Intel i5 或以上

---

## 🚀 安裝步驟

### 步驟 1：下載 Flutter SDK

1. **前往 Flutter 官網**
   - 網址：https://docs.flutter.dev/get-started/install/windows
   
2. **下載 Flutter SDK**
   - 點擊「Download Flutter SDK」
   - 下載最新的穩定版本（例如：flutter_windows_3.x.x-stable.zip）
   - 檔案大小約 1.5 GB

3. **選擇安裝位置**
   - 建議位置：`C:\src\flutter`
   - **避免**：`C:\Program Files\`（需要管理員權限）
   - **避免**：路徑中包含空格或特殊字元

---

### 步驟 2：解壓縮 Flutter

1. **解壓縮 ZIP 檔案**
   - 右鍵點擊下載的 ZIP 檔案
   - 選擇「解壓縮全部」
   - 選擇目標資料夾（例如：`C:\src\`）
   - 解壓縮後會得到 `C:\src\flutter` 資料夾

2. **驗證資料夾結構**
   ```
   C:\src\flutter\
   ├── bin\
   │   └── flutter.bat
   ├── packages\
   └── ...
   ```

---

### 步驟 3：設定環境變數

#### 方法 A：使用圖形介面（推薦）

1. **開啟環境變數設定**
   - 按 `Win + R`
   - 輸入 `sysdm.cpl` 並按 Enter
   - 點擊「進階」標籤
   - 點擊「環境變數」按鈕

2. **編輯 Path 變數**
   - 在「使用者變數」區域找到 `Path`
   - 點擊「編輯」
   - 點擊「新增」
   - 輸入：`C:\src\flutter\bin`（根據你的實際路徑）
   - 點擊「確定」儲存

3. **驗證設定**
   - 開啟新的 PowerShell 或 CMD 視窗
   - 執行：`flutter --version`
   - 應該會顯示 Flutter 版本資訊

#### 方法 B：使用命令列

```powershell
# 在 PowerShell 中執行（以管理員身分）
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\src\flutter\bin",
    "User"
)
```

---

### 步驟 4：執行 Flutter Doctor

1. **開啟新的終端機**
   - 按 `Win + R`
   - 輸入 `powershell` 並按 Enter

2. **執行診斷**
   ```bash
   flutter doctor
   ```

3. **查看結果**
   ```
   Doctor summary (to see all details, run flutter doctor -v):
   [✓] Flutter (Channel stable, 3.x.x, on Microsoft Windows)
   [✗] Android toolchain - develop for Android devices
   [✗] Chrome - develop for the web
   [✗] Visual Studio - develop for Windows
   [!] Android Studio (not installed)
   [✓] VS Code (version x.x.x)
   ```

---

### 步驟 5：安裝必要工具

根據 `flutter doctor` 的結果，安裝缺少的工具：

#### A. Android Studio（用於 Android 開發）

1. **下載 Android Studio**
   - 網址：https://developer.android.com/studio
   - 下載最新版本

2. **安裝 Android Studio**
   - 執行安裝程式
   - 選擇「Standard」安裝類型
   - 等待下載 Android SDK 和工具

3. **設定 Flutter 外掛**
   - 開啟 Android Studio
   - 前往 `File` → `Settings` → `Plugins`
   - 搜尋「Flutter」
   - 點擊「Install」
   - 重新啟動 Android Studio

4. **接受 Android 授權**
   ```bash
   flutter doctor --android-licenses
   ```
   - 輸入 `y` 接受所有授權

#### B. Chrome（用於 Web 開發）

1. **下載 Chrome**
   - 網址：https://www.google.com/chrome/
   - 安裝最新版本

2. **啟用 Web 支援**
   ```bash
   flutter config --enable-web
   ```

#### C. Visual Studio（用於 Windows 桌面開發，選用）

1. **下載 Visual Studio**
   - 網址：https://visualstudio.microsoft.com/downloads/
   - 選擇「Community」版本（免費）

2. **安裝必要元件**
   - 選擇「使用 C++ 的桌面開發」工作負載
   - 安裝

---

### 步驟 6：驗證安裝

1. **再次執行 Flutter Doctor**
   ```bash
   flutter doctor
   ```

2. **理想結果**
   ```
   [✓] Flutter (Channel stable, 3.x.x)
   [✓] Android toolchain
   [✓] Chrome
   [✓] Android Studio
   [✓] VS Code
   ```

3. **最低要求**（至少要有一個平台）
   - ✓ Flutter
   - ✓ Android toolchain 或 Chrome

---

## 🎯 測試 Flutter 安裝

### 建立測試專案

```bash
# 建立測試專案
flutter create test_app

# 進入專案目錄
cd test_app

# 執行專案
flutter run
```

如果成功，你應該會看到一個計數器應用程式！

---

## 🔧 Together App 專案設定

安裝完 Flutter 後，回到 Together App 專案：

```bash
# 1. 進入專案目錄
cd C:\work\other\TogetherApp

# 2. 安裝依賴
flutter pub get

# 3. 檢查可用裝置
flutter devices

# 4. 執行應用程式
flutter run
```

---

## 🐛 常見問題

### 問題 1：flutter 命令找不到

**症狀**：
```
'flutter' 不是內部或外部命令
```

**解決方案**：
1. 確認 Flutter 已加入 PATH 環境變數
2. 重新開啟終端機
3. 執行 `echo %PATH%` 檢查是否包含 Flutter 路徑

---

### 問題 2：Android licenses 錯誤

**症狀**：
```
Android sdkmanager not found
```

**解決方案**：
1. 確認 Android Studio 已安裝
2. 開啟 Android Studio，讓它完成初始設定
3. 執行：
   ```bash
   flutter doctor --android-licenses
   ```

---

### 問題 3：下載速度慢

**解決方案**：
使用中國鏡像（如果在中國）：
```bash
# 設定環境變數
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

---

### 問題 4：Visual Studio 找不到

**症狀**：
```
Visual Studio not installed
```

**解決方案**：
- 如果不需要 Windows 桌面開發，可以忽略
- 或安裝 Visual Studio Community 版本

---

## 📱 設定 Android 模擬器

### 使用 Android Studio

1. **開啟 AVD Manager**
   - 開啟 Android Studio
   - 點擊 `Tools` → `Device Manager`

2. **建立虛擬裝置**
   - 點擊「Create Device」
   - 選擇裝置型號（例如：Pixel 5）
   - 選擇系統映像（例如：Android 13）
   - 點擊「Finish」

3. **啟動模擬器**
   - 在 Device Manager 中點擊「Play」按鈕
   - 等待模擬器啟動

4. **驗證**
   ```bash
   flutter devices
   ```
   應該會看到模擬器裝置

---

## 🎯 快速測試方案

### 方案 A：使用 Chrome（最快）

```bash
# 1. 啟用 Web 支援
flutter config --enable-web

# 2. 在 Chrome 中執行
cd C:\work\other\TogetherApp
flutter run -d chrome
```

**優點**：
- 最快速
- 不需要模擬器
- 即時熱重載

**缺點**：
- Google Maps 需要額外設定
- 某些功能可能不完整

---

### 方案 B：使用 Android 模擬器

```bash
# 1. 啟動模擬器（在 Android Studio 中）

# 2. 執行應用程式
cd C:\work\other\TogetherApp
flutter run
```

**優點**：
- 完整功能
- 接近真實裝置
- 可測試 Google Maps

**缺點**：
- 需要較多資源
- 啟動較慢

---

### 方案 C：使用實體手機（推薦）

```bash
# 1. 開啟手機的開發者選項和 USB 偵錯

# 2. 用 USB 連接電腦

# 3. 執行應用程式
cd C:\work\other\TogetherApp
flutter run
```

**優點**：
- 最佳效能
- 真實體驗
- 可測試所有功能

**缺點**：
- 需要實體裝置
- 需要 USB 線

---

## 📚 延伸閱讀

- [Flutter 官方安裝指南](https://docs.flutter.dev/get-started/install/windows)
- [Flutter 中文網](https://flutter.cn/)
- [Android Studio 下載](https://developer.android.com/studio)
- [VS Code Flutter 外掛](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

---

## ✅ 安裝完成檢查清單

- [ ] Flutter SDK 已下載並解壓縮
- [ ] Flutter bin 目錄已加入 PATH
- [ ] `flutter --version` 可以執行
- [ ] `flutter doctor` 顯示至少一個平台可用
- [ ] Android Studio 已安裝（如需 Android 開發）
- [ ] Chrome 已安裝（如需 Web 開發）
- [ ] Android licenses 已接受
- [ ] 可以執行 `flutter devices` 看到裝置

---

## 🎉 下一步

安裝完成後：

1. **回到 Together App 專案**
   ```bash
   cd C:\work\other\TogetherApp
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **設定 Google Maps API Key**
   - 參考 `QUICK_START.md`

4. **執行測試**
   ```bash
   flutter run
   ```

5. **查看測試指南**
   - 參考 `TESTING_GUIDE.md`

---

**祝安裝順利！** 🚀

如有任何問題，請參考 Flutter 官方文件或社群論壇。
