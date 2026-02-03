# Together - 地圖社交活動媒合平台

一個基於地圖的社交活動媒合平台，讓使用者可以在地圖上發現並參加附近的活動。

## 🚀 快速開始

### 1. 安裝依賴

```bash
flutter pub get
```

### 2. 設定環境變數

複製 `.env.example` 為 `.env`：

```bash
cp .env.example .env
```

編輯 `.env` 檔案，填入你的設定：

```env
# Google Maps API Key
GOOGLE_MAPS_API_KEY=你的_API_KEY

# 後端 API 設定
API_BASE_URL=https://your-api-url.com

# 開發用 Bearer Token（選填）
DEV_BEARER_TOKEN=你的_TOKEN
```

### 3. 執行應用程式

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## 📋 環境變數說明

| 變數名稱 | 說明 | 必填 |
|---------|------|------|
| `GOOGLE_MAPS_API_KEY` | Google Maps API 金鑰 | 是 |
| `API_BASE_URL` | 後端 API 網址 | 是 |
| `DEV_BEARER_TOKEN` | 開發用認證 Token | 否 |

## 🔑 取得 Google Maps API Key

1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立新專案或選擇現有專案
3. 啟用以下 API：
   - Places API
   - Geocoding API
   - Maps JavaScript API
   - Maps SDK for Android
   - Maps SDK for iOS
4. 建立 API 金鑰
5. 複製金鑰到 `.env` 檔案

詳細說明請參考：`docs/GOOGLE_MAPS_API_SETUP.md`

## 📚 專案文件

- [快速開始](docs/01-快速開始/START_HERE.md)
- [測試指南](docs/03-測試指南/TESTING_GUIDE.md)
- [專案架構](docs/04-專案架構/PROJECT_STRUCTURE.md)
- [API 規格](docs/05-設計規範/backend_api_specs_updated.md)
- [Google Maps 設定](docs/GOOGLE_MAPS_API_SETUP.md)

## 🛠️ 技術棧

- **框架**: Flutter 3.0+
- **狀態管理**: Provider
- **地圖**: Google Maps Flutter
- **網路請求**: Dio
- **環境變數**: flutter_dotenv

## ⚠️ 注意事項

1. **不要提交 `.env` 檔案到 Git**
2. API Key 應該設定使用限制
3. Web 版本可能遇到 CORS 問題，建議使用 Android/iOS 測試

## 📝 授權

此專案僅供學習和開發使用。
