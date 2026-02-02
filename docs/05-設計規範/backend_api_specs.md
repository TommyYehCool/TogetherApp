# Together App - 後端 API 規格文件

## 基本資訊

**Base URL**: `https://helpful-noticeably-bullfrog.ngrok-free.app`  
**環境**: Development (ngrok tunnel)  
**認證方式**: Bearer Token (Google OAuth)

---

## 1. 認證 (Authentication)

### 1.1 Google OAuth 登入

#### 發起登入流程
```
GET /auth/login/google
```

**說明**: 啟動 Google OAuth 登入流程

**使用方式**: 
- 在 WebView 或系統瀏覽器中開啟此 URL
- 使用者完成 Google 登入後會重導向到 callback URL

---

#### OAuth Callback
```
GET /auth/google/callback
```

**說明**: 處理 Google OAuth 的 callback 並交換 token

**回應**: 
- 成功後會返回 JWT token
- 前端需要儲存此 token 並在後續請求中使用

---

## 2. 活動管理 (Activities)

### 2.1 探索附近活動

```
GET /activities/nearby
```

**說明**: 取得使用者附近的活動列表，用於在地圖上顯示

**Query Parameters**:
| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| lat | float | 是 | 使用者當前緯度 |
| lng | float | 是 | 使用者當前經度 |
| radius | int | 否 | 搜尋半徑（公尺），預設 5000 |

**請求範例**:
```
GET /activities/nearby?lat=25.0330&lng=121.5654&radius=5000
```

**回應範例** (200 OK):
```json
[
  {
    "id": "uuid-string",
    "title": "Basketball 3v3",
    "description": "Looking for players",
    "start_time": "2023-10-27T10:00:00Z",
    "latitude": 25.0330,
    "longitude": 121.5654,
    "current_participants": 1,
    "max_participants": 6,
    "host_id": "user-uuid",
    "host_name": "小明",
    "is_boosted": false
  }
]
```

---

### 2.2 建立新活動

```
POST /activities/
```

**說明**: 在地圖上建立新的活動標記

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧",
  "start_time": "2023-10-27T14:00:00Z",
  "max_participants": 5,
  "latitude": 25.0330,
  "longitude": 121.5654,
  "category": "學習"
}
```

**欄位說明**:
| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| title | string | 是 | 活動標題 |
| description | string | 是 | 活動描述 |
| start_time | string | 是 | 開始時間 (ISO 8601 格式) |
| max_participants | int | 是 | 最大參與人數 |
| latitude | float | 是 | 活動地點緯度 |
| longitude | float | 是 | 活動地點經度 |
| category | string | 是 | 活動類別（社交/運動/學習/美食/旅遊/音樂/藝術/其他） |

**回應範例** (201 Created):
```json
{
  "id": "new-uuid",
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧",
  "start_time": "2023-10-27T14:00:00Z",
  "latitude": 25.0330,
  "longitude": 121.5654,
  "current_participants": 1,
  "max_participants": 5,
  "host_id": "current-user-uuid",
  "host_name": "我",
  "is_boosted": false
}
```

---

### 2.3 加入活動

```
POST /activities/{activity_id}/join
```

**說明**: 使用者請求加入指定的活動

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
| 參數 | 類型 | 說明 |
|------|------|------|
| activity_id | string | 活動 ID |

**回應**:
- `200 OK` - 成功加入活動
- `400 Bad Request` - 活動已額滿或其他錯誤
- `401 Unauthorized` - 未認證
- `404 Not Found` - 活動不存在

---

### 2.4 查看加入請求 (Host 專用)

```
GET /activities/{activity_id}/requests
```

**說明**: 活動主辦人查看所有加入請求

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例** (200 OK):
```json
[
  {
    "request_id": "req-uuid",
    "user_id": "user-uuid",
    "user_name": "小華",
    "requested_at": "2023-10-27T09:00:00Z",
    "status": "pending"
  }
]
```

---

### 2.5 批准加入請求 (Host 專用)

```
PUT /activities/requests/{request_id}/approve
```

**說明**: 活動主辦人批准特定的加入請求

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
| 參數 | 類型 | 說明 |
|------|------|------|
| request_id | string | 請求 ID |

**回應**:
- `200 OK` - 成功批准
- `403 Forbidden` - 非活動主辦人
- `404 Not Found` - 請求不存在

---

### 2.6 評分活動

```
POST /activities/{activity_id}/rate
```

**說明**: 活動結束後，參與者可以評分

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "score": 5,
  "comment": "Great game!"
}
```

**欄位說明**:
| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| score | int | 是 | 評分 (1-5) |
| comment | string | 否 | 評論 |

**回應**:
- `200 OK` - 評分成功
- `400 Bad Request` - 評分範圍錯誤

---

### 2.7 Boost 活動 (MVP 功能)

```
POST /activities/{activity_id}/mock-boost
```

**說明**: 模擬付費提升活動曝光度

**Headers**:
```
Authorization: Bearer {token}
```

**回應**:
- `200 OK` - Boost 成功
- `403 Forbidden` - 非活動主辦人

---

## 3. 使用者資料 (User Profile)

### 3.1 取得使用者主辦的活動

```
GET /users/me/hosted
```

**說明**: 取得當前使用者主辦的所有活動

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例** (200 OK):
```json
[
  {
    "id": "activity-uuid",
    "title": "籃球鬥牛",
    "start_time": "2023-10-27T10:00:00Z",
    "current_participants": 4,
    "max_participants": 6,
    "status": "active"
  }
]
```

---

### 3.2 取得使用者參加的活動

```
GET /users/me/joined
```

**說明**: 取得當前使用者參加的所有活動

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例** (200 OK):
```json
[
  {
    "id": "activity-uuid",
    "title": "咖啡廳讀書會",
    "start_time": "2023-10-27T14:00:00Z",
    "host_name": "小明",
    "status": "confirmed"
  }
]
```

---

## 4. 錯誤處理

### 標準錯誤回應格式

```json
{
  "error": "ERROR_CODE",
  "message": "Human readable error message",
  "details": {}
}
```

### 常見錯誤代碼

| HTTP Status | 錯誤代碼 | 說明 |
|-------------|----------|------|
| 400 | BAD_REQUEST | 請求參數錯誤 |
| 401 | UNAUTHORIZED | 未認證或 Token 無效 |
| 403 | FORBIDDEN | 無權限執行此操作 |
| 404 | NOT_FOUND | 資源不存在 |
| 409 | CONFLICT | 資源衝突（如已加入活動） |
| 500 | INTERNAL_ERROR | 伺服器內部錯誤 |

---

## 5. 前端整合說明

### 5.1 認證流程

1. 使用者點擊「Google 登入」
2. 開啟 WebView 或系統瀏覽器，導向 `/auth/login/google`
3. 使用者完成 Google 登入
4. 從 callback 取得 JWT token
5. 儲存 token 到本地（SharedPreferences / Keychain）
6. 在所有 API 請求中加入 `Authorization: Bearer {token}` header

### 5.2 地圖標記更新流程

1. 取得使用者位置 (lat, lng)
2. 呼叫 `GET /activities/nearby?lat={lat}&lng={lng}`
3. 將回應的活動列表轉換為地圖標記
4. 使用 `widget_to_marker` 產生自訂標記
5. 在地圖上顯示標記

### 5.3 建立活動流程

1. 使用者填寫活動表單
2. 取得當前地圖中心點座標
3. 呼叫 `POST /activities/` 建立活動
4. 成功後重新載入附近活動
5. 地圖自動顯示新建立的活動標記

---

## 6. 開發注意事項

### 6.1 ngrok Tunnel

- 目前使用 ngrok 作為開發環境
- Base URL 可能會變動，需要更新
- 正式環境需要替換為正式的 domain

### 6.2 CORS 設定

- 確保後端已設定 CORS，允許前端 domain
- Web 版本需要特別注意 CORS 問題

### 6.3 Token 管理

- Token 應該安全儲存
- 實作 token 過期處理
- 提供重新登入機制

### 6.4 錯誤處理

- 所有 API 呼叫都應該有 try-catch
- 提供使用者友善的錯誤訊息
- 網路錯誤時提供重試機制

---

## 7. 測試建議

### 7.1 Mock 模式

- 前端已實作 Mock 資料 fallback
- API 失敗時自動使用 Mock 資料
- 方便前端獨立開發測試

### 7.2 測試案例

1. **正常流程**
   - 登入 → 查看地圖 → 建立活動 → 加入活動

2. **錯誤處理**
   - 網路斷線
   - Token 過期
   - 活動已額滿

3. **邊界條件**
   - 最大參與人數
   - 過去的時間
   - 無效的座標

---

**文件版本**: 1.0.0  
**最後更新**: 2026-02-02  
**維護者**: Together App Team
