# Together - 地圖社交活動媒合平台

> 「把你想做的事，直接釘在地圖上，等人一起來。」

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-MVP%20Complete-success.svg)](docs/04-專案架構/PROJECT_CHECKLIST.md)

---

## 🎯 專案簡介

Together 是一個以地圖為核心的即時活動發現與媒合平台，幫助用戶在 30 分鐘內找到一起參加活動的人。

### 核心特色
- ⭐ **獨特的膠囊標記** - 使用 `widget_to_marker` 實作的自訂地圖標記
- 🗺️ **地圖為首頁** - GoShare/Uber 風格的簡潔設計
- 📱 **完整的 MVP** - 從資料層到 UI 層完整實作
- 🔧 **Mock 資料支援** - 無需後端即可開發測試

---

## 🚀 快速開始

### 1️⃣ 檢查環境
```bash
# Windows 使用者
check_environment.bat
```

### 2️⃣ 安裝依賴
```bash
flutter pub get
```

### 3️⃣ 執行應用程式
```bash
flutter run
```

### 📚 詳細指南
👉 **[查看完整文件](docs/README.md)**  
👉 **[快速開始指南](docs/01-快速開始/START_HERE.md)**

---

## 📂 專案結構

```
TogetherApp/
├── lib/                          # Flutter 應用程式
│   ├── main.dart                 # 應用程式入口
│   ├── models/                   # 資料模型
│   ├── services/                 # 服務層（API、狀態管理）
│   ├── screens/                  # 畫面層
│   └── widgets/                  # UI 元件
│       └── activity_marker_widget.dart  # ⭐ 膠囊標記
│
├── android/                      # Android 設定
├── ios/                          # iOS 設定
│
├── docs/                         # 📚 完整文件
│   ├── 01-快速開始/             # 入門指南
│   ├── 02-安裝與設定/           # 環境設定
│   ├── 03-測試指南/             # 測試方法
│   ├── 04-專案架構/             # 架構說明
│   ├── 05-設計規範/             # UI/UX 與 API
│   └── 06-產品文件/             # 產品提案
│
└── README.md                     # 本檔案
```

---

## 🎨 核心功能

### ⭐ 膠囊標記（專案亮點）
自訂的 Stadium 形狀地圖標記，顯示活動標題和參與人數

```dart
ActivityMarkerWidget(
  title: "咖啡廳讀書會",
  participantCount: "3/5",
  isBoosted: true,
)
```

### 🗺️ 地圖主畫面
- 全螢幕 Google Map
- 自動取得使用者位置
- 顯示附近活動標記
- 點擊標記查看詳情

### 📋 活動管理
- 建立新活動
- 加入活動
- 查看活動詳情
- 滑動面板設計

---

## 🔧 技術棧

| 技術 | 版本 | 用途 |
|------|------|------|
| Flutter | 3.0+ | 跨平台框架 |
| google_maps_flutter | ^2.5.0 | 地圖顯示 |
| dio | ^5.4.0 | 網路請求 |
| provider | ^6.1.1 | 狀態管理 |
| sliding_up_panel | ^2.0.0+1 | 滑動面板 |
| widget_to_marker | ^1.0.3 | 自訂標記 ⭐ |
| geolocator | ^10.1.0 | 地理定位 |

---

## 📚 文件導覽

### 🚀 快速開始
- **[START_HERE.md](docs/01-快速開始/START_HERE.md)** - 📍 從這裡開始
- **[QUICK_START.md](docs/01-快速開始/QUICK_START.md)** - ⚡ 5 分鐘上手
- **[HOW_TO_TEST.md](docs/01-快速開始/HOW_TO_TEST.md)** - 🧪 測試指南

### ⚙️ 安裝與設定
- **[INSTALL_FLUTTER.md](docs/02-安裝與設定/INSTALL_FLUTTER.md)** - 📦 Flutter 安裝
- **[SETUP_GUIDE.md](docs/02-安裝與設定/SETUP_GUIDE.md)** - 🔧 設定指南

### 🏗️ 專案架構
- **[PROJECT_STRUCTURE.md](docs/04-專案架構/PROJECT_STRUCTURE.md)** - 📐 架構詳解
- **[IMPLEMENTATION_SUMMARY.md](docs/04-專案架構/IMPLEMENTATION_SUMMARY.md)** - 📊 實作總結
- **[VISUAL_OVERVIEW.md](docs/04-專案架構/VISUAL_OVERVIEW.md)** - 🎨 視覺化總覽

### 🎨 設計規範
- **[ui_design_specs.md](docs/05-設計規範/ui_design_specs.md)** - 🎨 UI/UX 規範
- **[api_specs.md](docs/05-設計規範/api_specs.md)** - 🔌 API 規格

### 📄 產品文件
- **[Together 專案提案書.md](docs/06-產品文件/Together%20專案提案書.md)** - 📋 產品提案

👉 **[查看所有文件](docs/README.md)**

---

## 🎯 開發狀態

```
✅ 資料層      100%
✅ 服務層      100%
✅ UI 層       100%
✅ 設定檔      100%
✅ 文件        100%

總體進度：100% 🎉
```

### MVP 功能清單
- ✅ Activity 資料模型
- ✅ API 服務（含 Mock 資料）
- ✅ 狀態管理（Provider）
- ✅ 膠囊標記元件 ⭐
- ✅ 地圖主畫面
- ✅ 活動詳情面板
- ✅ 建立活動功能
- ✅ 完整文件

---

## 🧪 測試

### 快速測試
```bash
# 使用 Chrome 瀏覽器（最快）
flutter config --enable-web
flutter run -d chrome
```

### 完整測試
```bash
# 使用 Android 模擬器或實體手機
flutter run
```

### 測試功能
- [ ] 地圖正常顯示
- [ ] 看到 3 個膠囊標記（Mock 資料）
- [ ] 點擊標記查看詳情
- [ ] 建立新活動
- [ ] 加入活動

👉 **[完整測試指南](docs/03-測試指南/TESTING_GUIDE.md)**

---

## 🎨 設計風格

- **參考**：GoShare / Uber 風格
- **主色調**：#00D0DD（青綠色）
- **特色**：簡潔、極簡、地圖為核心
- **圓角**：20-28px
- **間距**：8/16/24px 系統

---

## 📱 支援平台

| 平台 | 狀態 | 最低版本 |
|------|------|----------|
| Android | ✅ 支援 | Android 5.0 (API 21) |
| iOS | ✅ 支援 | iOS 12.0 |
| Web | ⚠️ 部分支援 | Chrome 最新版 |

---

## 🚀 下一步開發

### 優先級 P0（立即）
- [ ] 取得 Google Maps API Key
- [ ] 測試所有功能
- [ ] 開發後端 API
- [ ] 整合真實 API

### 優先級 P1（重要）
- [ ] 使用者認證系統
- [ ] 活動聊天室
- [ ] 推播通知
- [ ] 活動篩選功能

### 優先級 P2（加分）
- [ ] Boost 付費功能
- [ ] 評價系統
- [ ] 好友系統
- [ ] 活動推薦演算法

---

## 💡 重要提示

### Mock 資料
目前應用程式包含 Mock 資料，即使沒有後端 API 也能正常運作。  
Mock 資料位於 `lib/services/api_service.dart`。

### Google Maps API Key
需要設定 Google Maps API Key 才能顯示地圖：
- **Android**：`android/app/src/main/AndroidManifest.xml`
- **iOS**：`ios/Runner/AppDelegate.swift`

👉 **[設定指南](docs/02-安裝與設定/SETUP_GUIDE.md)**

---

## 📞 需要協助？

### 快速參考
- **環境問題**：[INSTALL_FLUTTER.md](docs/02-安裝與設定/INSTALL_FLUTTER.md)
- **測試問題**：[TESTING_GUIDE.md](docs/03-測試指南/TESTING_GUIDE.md)
- **設定問題**：[SETUP_GUIDE.md](docs/02-安裝與設定/SETUP_GUIDE.md)
- **架構問題**：[PROJECT_STRUCTURE.md](docs/04-專案架構/PROJECT_STRUCTURE.md)

### 外部資源
- [Flutter 官方文件](https://flutter.dev/docs)
- [Flutter 中文網](https://flutter.cn/)
- [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Provider 套件](https://pub.dev/packages/provider)

---

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

---

## 📄 授權

MIT License

---

## 🎉 開始使用

準備好了嗎？

1. **查看文件**：[docs/README.md](docs/README.md)
2. **快速開始**：[START_HERE.md](docs/01-快速開始/START_HERE.md)
3. **開始測試**：[HOW_TO_TEST.md](docs/01-快速開始/HOW_TO_TEST.md)

---

**Together App - 讓活動不再孤單** 🚀

*建立日期：2026-02-02 | 版本：1.0.0 | 狀態：✅ MVP 完成*
