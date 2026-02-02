# 建立活動 Debug 指南

## 問題：建立活動後沒有存入資料庫

### 檢查步驟

#### 1. 查看 Console 日誌
在 VS Code Terminal 或 Chrome DevTools Console 查看：

**成功的日誌應該顯示：**
```
建立活動 API 請求:
URL: https://helpful-noticeably-bullfrog.ngrok-free.app/activities/
Data: {
  title: 長安街吃餐當勞,
  description: ...,
  start_time: 2024-02-02T...,
  max_participants: 5,
  latitude: 25.0330,
  longitude: 121.5654,
  category: 美食
}
API 請求: POST https://...
使用 Token: eyJhbGc...
API 回應: 201 https://...
建立活動回應: 201
回應資料: {...}
```

**失敗的日誌會顯示：**
```
建立活動失敗: DioException...
錯誤類型: ...
錯誤訊息: ...
回應狀態碼: 400/401/500
回應資料: {...}
```

#### 2. 檢查 API 請求格式

**前端發送的資料格式：**
```json
{
  "title": "活動標題",
  "description": "活動描述",
  "start_time": "2024-02-02T14:00:00.000Z",
  "max_participants": 5,
  "latitude": 25.0330,
  "longitude": 121.5654,
  "category": "美食"
}
```

**後端期望的欄位（請確認）：**
- ✅ title (string)
- ✅ description (string)
- ✅ start_time (ISO 8601 格式)
- ✅ max_participants (int)
- ✅ latitude (float)
- ✅ longitude (float)
- ✅ category (string) - **新增**

#### 3. 常見錯誤原因

##### 錯誤 1：缺少 category 欄位
**症狀：** 後端回應 400 或 422 錯誤
**解決：** 已在程式碼中加入 category 欄位

##### 錯誤 2：Token 無效
**症狀：** 後端回應 401 錯誤
**解決：** 
1. 到設定頁面更新 Token
2. 確認 Token 未過期

##### 錯誤 3：欄位名稱不符
**症狀：** 後端回應 422 錯誤
**檢查：** 
- 前端使用 snake_case: `start_time`, `max_participants`
- 後端是否期望相同格式？

##### 錯誤 4：資料類型錯誤
**症狀：** 後端回應 422 錯誤
**檢查：**
- `max_participants` 是 int 不是 string
- `latitude`, `longitude` 是 float 不是 string
- `start_time` 是 ISO 8601 格式字串

##### 錯誤 5：CORS 問題
**症狀：** 看到 DioException connection error
**解決：** 參考 CORS_SETUP_GUIDE.md

#### 4. 使用 Chrome DevTools 檢查

1. 打開 Chrome DevTools (F12)
2. 切換到 Network 標籤
3. 建立活動
4. 找到 `POST /activities/` 請求
5. 查看：
   - Request Headers（是否有 Authorization）
   - Request Payload（資料格式是否正確）
   - Response（後端回應什麼）

#### 5. 使用 Postman 測試後端

**測試建立活動 API：**
```
POST https://helpful-noticeably-bullfrog.ngrok-free.app/activities/

Headers:
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json
ngrok-skip-browser-warning: true

Body (JSON):
{
  "title": "測試活動",
  "description": "測試描述",
  "start_time": "2024-02-02T14:00:00Z",
  "max_participants": 5,
  "latitude": 25.0330,
  "longitude": 121.5654,
  "category": "其他"
}
```

**預期回應：**
```json
{
  "id": "uuid-string",
  "title": "測試活動",
  "description": "測試描述",
  "start_time": "2024-02-02T14:00:00Z",
  "latitude": 25.0330,
  "longitude": 121.5654,
  "current_participants": 1,
  "max_participants": 5,
  "category": "其他",
  "host_id": "user-uuid",
  "host_name": "你的名字"
}
```

---

## 修正內容

### 已修正的問題

1. ✅ **加入 category 欄位**
   - 位置：`lib/services/api_service.dart`
   - 現在會正確發送 category 到後端

2. ✅ **加入詳細日誌**
   - 可以在 Console 看到完整的請求和回應
   - 錯誤時會顯示詳細的錯誤訊息

3. ✅ **更新 API 文件**
   - `docs/05-設計規範/backend_api_specs.md`
   - 加入 category 欄位說明

### 需要後端確認的事項

請後端開發者確認：

1. **欄位名稱格式**
   - 是否使用 snake_case？（start_time, max_participants）
   - 還是 camelCase？（startTime, maxParticipants）

2. **category 欄位**
   - 是否為必填？
   - 接受的值有哪些？
   - 是否需要驗證？

3. **回應格式**
   - 成功時回應 200 還是 201？
   - 回應的資料結構是什麼？

4. **錯誤處理**
   - 各種錯誤的狀態碼和訊息格式？

---

## 下一步

1. **重新啟動應用程式**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

2. **建立活動並查看 Console**
   - 查看完整的請求日誌
   - 確認是否有錯誤訊息

3. **提供日誌給後端開發者**
   - 如果仍然失敗，複製 Console 的錯誤訊息
   - 包含請求資料和回應資料

4. **確認資料庫**
   - 請後端開發者檢查資料庫
   - 確認是否有收到請求
   - 確認是否有錯誤日誌
