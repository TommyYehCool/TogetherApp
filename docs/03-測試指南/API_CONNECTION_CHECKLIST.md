# API 連接檢查清單

## 問題：API 似乎都沒有連接成功

### 快速診斷步驟

#### 1. 檢查 Bearer Token
- [ ] 打開應用程式，點擊右上角頭像
- [ ] 進入「設定」頁面
- [ ] 確認是否已輸入 Bearer Token
- [ ] Token 格式應該是：`eyJhbGc...` 開頭的長字串
- [ ] 確認 Token 未過期

**如何取得 Token：**
```bash
# 從後端登入取得 Token
# 或向後端開發者索取測試 Token
```

#### 2. 測試 API 連線
- [ ] 在設定頁面點擊「測試 API 連線」按鈕
- [ ] 查看診斷報告
- [ ] 確認所有項目都是 ✅

#### 3. 檢查後端服務
- [ ] 確認後端服務正在運行
- [ ] 確認 ngrok tunnel 正常運作
- [ ] Base URL: `https://helpful-noticeably-bullfrog.ngrok-free.app`

**測試後端：**
```bash
# 在瀏覽器或 Postman 測試
GET https://helpful-noticeably-bullfrog.ngrok-free.app/activities/nearby?lat=25.0330&lng=121.5654&radius=5000

# Headers:
Authorization: Bearer YOUR_TOKEN_HERE
ngrok-skip-browser-warning: true
```

#### 4. 檢查網路連線
- [ ] 確認裝置/電腦有網路連線
- [ ] 嘗試在瀏覽器開啟 Base URL
- [ ] 確認沒有防火牆阻擋

#### 5. 查看 Console 日誌
在 VS Code Terminal 中查看應用程式輸出：
```
API 請求: GET https://...
使用 Token: eyJhbGc...
API 回應: 200 https://...
```

如果看到：
- `401 Unauthorized` → Token 無效或過期
- `404 Not Found` → URL 錯誤
- `500 Internal Server Error` → 後端錯誤
- `Connection refused` → 後端未運行

---

## 常見問題解決

### 問題 1：CORS 錯誤（Chrome 測試）
**症狀：**
- 錯誤訊息：`DioException [connection error]`
- 錯誤訊息：`XMLHttpRequest onError callback was called`
- 診斷報告顯示「連線錯誤」

**原因：**
Web 瀏覽器的 CORS（跨域資源共享）安全限制

**解決方法：**
1. **推薦：使用 Android/iOS 模擬器測試**
   ```bash
   # Android
   flutter run -d android
   
   # iOS (需要 Mac)
   flutter run -d ios
   ```
   
2. **或：請後端開發者設定 CORS**
   後端需要加入以下 headers：
   ```python
   # FastAPI 範例
   from fastapi.middleware.cors import CORSMiddleware
   
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],  # 開發環境可用 *
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

3. **或：使用 Mock 資料模式開發**
   - 不輸入 Token
   - 應用程式會自動使用 Mock 資料
   - 可以正常開發 UI 功能

### 問題 2：Token 無效（401 錯誤）
### 問題 2：Token 無效（401 錯誤）
**解決方法：**
1. 重新從後端取得新的 Token
2. 在設定頁面更新 Token
3. 再次測試連線

### 問題 3：無法連接到後端
### 問題 3：無法連接到後端
**解決方法：**
1. 確認後端服務正在運行
2. 確認 ngrok tunnel 正常
3. 檢查 Base URL 是否正確

### 問題 4：Google Maps API 無法使用
**位置選擇器的地址搜尋功能需要：**
1. 在 `lib/widgets/location_picker_dialog.dart` 第 52 行設定 API Key
2. 在 Google Cloud Console 啟用以下 API：
   - Places API
   - Geocoding API
   - Maps JavaScript API

**取得 API Key：**
1. 前往 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立專案或選擇現有專案
3. 啟用上述 API
4. 建立 API Key
5. 將 Key 貼到程式碼中

---

## Mock 資料模式

如果 API 連接失敗，應用程式會自動使用 Mock 資料：
- ✅ 可以正常瀏覽地圖
- ✅ 可以看到測試活動
- ✅ 可以建立活動（僅本地）
- ❌ 資料不會同步到後端
- ❌ 無法看到其他使用者的活動

---

## 檢查清單總結

完成以下步驟確保 API 正常運作：

1. ✅ 設定有效的 Bearer Token
2. ✅ 測試 API 連線（診斷報告全綠）
3. ✅ 確認後端服務運行中
4. ✅ 設定 Google Maps API Key（地址搜尋功能）
5. ✅ 查看 Console 確認沒有錯誤

**如果所有步驟都完成但仍有問題，請提供：**
- 診斷報告截圖
- Console 日誌
- 後端 API 回應
