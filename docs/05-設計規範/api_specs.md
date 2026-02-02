# Together API 規格文件

## Base URL
```
https://api.together.app
```

## 認證
所有需要認證的 API 都需要在 Header 中帶入 JWT Token：
```
Authorization: Bearer {token}
```

---

## 活動相關 API

### 1. 取得附近活動
取得使用者附近的活動列表

**Endpoint**: `GET /activities/nearby`

**Query Parameters**:
| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| latitude | number | 是 | 緯度 |
| longitude | number | 是 | 經度 |
| radius | number | 否 | 搜尋半徑（公里），預設 5.0 |
| category | string | 否 | 活動類別篩選 |
| startTime | string | 否 | 開始時間篩選（ISO 8601） |

**Response** (200 OK):
```json
{
  "activities": [
    {
      "id": "act_123456",
      "title": "咖啡廳讀書會",
      "description": "一起來咖啡廳讀書吧！歡迎帶自己的書",
      "latitude": 25.0330,
      "longitude": 121.5654,
      "startTime": "2024-03-20T14:00:00Z",
      "maxParticipants": 5,
      "currentParticipants": 3,
      "category": "學習",
      "hostId": "user_001",
      "hostName": "小明",
      "isBoosted": true,
      "createdAt": "2024-03-19T10:00:00Z"
    }
  ],
  "total": 10
}
```

---

### 2. 建立新活動
建立一個新的活動

**Endpoint**: `POST /activities`

**Request Body**:
```json
{
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧！歡迎帶自己的書",
  "latitude": 25.0330,
  "longitude": 121.5654,
  "startTime": "2024-03-20T14:00:00Z",
  "maxParticipants": 5,
  "category": "學習"
}
```

**Response** (201 Created):
```json
{
  "id": "act_123456",
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧！歡迎帶自己的書",
  "latitude": 25.0330,
  "longitude": 121.5654,
  "startTime": "2024-03-20T14:00:00Z",
  "maxParticipants": 5,
  "currentParticipants": 1,
  "category": "學習",
  "hostId": "user_001",
  "hostName": "小明",
  "isBoosted": false,
  "createdAt": "2024-03-19T10:00:00Z"
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": "INVALID_INPUT",
  "message": "活動標題不能為空"
}
```

---

### 3. 加入活動
使用者加入指定的活動

**Endpoint**: `POST /activities/:activityId/join`

**Path Parameters**:
| 參數 | 類型 | 說明 |
|------|------|------|
| activityId | string | 活動 ID |

**Response** (200 OK):
```json
{
  "success": true,
  "message": "成功加入活動",
  "activity": {
    "id": "act_123456",
    "currentParticipants": 4
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": "ACTIVITY_FULL",
  "message": "活動已額滿"
}
```

**Error Response** (409 Conflict):
```json
{
  "error": "ALREADY_JOINED",
  "message": "您已經加入此活動"
}
```

---

### 4. 取得活動詳情
取得單一活動的完整資訊

**Endpoint**: `GET /activities/:activityId`

**Response** (200 OK):
```json
{
  "id": "act_123456",
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧！歡迎帶自己的書",
  "latitude": 25.0330,
  "longitude": 121.5654,
  "startTime": "2024-03-20T14:00:00Z",
  "maxParticipants": 5,
  "currentParticipants": 3,
  "category": "學習",
  "hostId": "user_001",
  "hostName": "小明",
  "isBoosted": true,
  "participants": [
    {
      "userId": "user_001",
      "userName": "小明",
      "avatar": "https://..."
    }
  ],
  "createdAt": "2024-03-19T10:00:00Z"
}
```

---

### 5. 離開活動
使用者離開已加入的活動

**Endpoint**: `POST /activities/:activityId/leave`

**Response** (200 OK):
```json
{
  "success": true,
  "message": "已離開活動"
}
```

---

## Boost 相關 API

### 6. Boost 活動
付費提升活動曝光度

**Endpoint**: `POST /activities/:activityId/boost`

**Request Body**:
```json
{
  "duration": 24,
  "paymentMethod": "credit_card"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "boostedUntil": "2024-03-21T10:00:00Z",
  "amount": 30
}
```

---

## 使用者相關 API

### 7. 取得使用者資料
取得目前登入使用者的資料

**Endpoint**: `GET /users/me`

**Response** (200 OK):
```json
{
  "id": "user_001",
  "name": "小明",
  "email": "user@example.com",
  "avatar": "https://...",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

---

### 8. 取得使用者的活動
取得使用者建立或參加的活動

**Endpoint**: `GET /users/me/activities`

**Query Parameters**:
| 參數 | 類型 | 必填 | 說明 |
|------|------|------|------|
| type | string | 否 | `hosted` 或 `joined`，預設全部 |
| status | string | 否 | `upcoming` 或 `past`，預設 `upcoming` |

**Response** (200 OK):
```json
{
  "activities": [
    {
      "id": "act_123456",
      "title": "咖啡廳讀書會",
      "startTime": "2024-03-20T14:00:00Z",
      "role": "host"
    }
  ]
}
```

---

## 錯誤代碼

| 錯誤代碼 | HTTP Status | 說明 |
|----------|-------------|------|
| INVALID_INPUT | 400 | 輸入資料格式錯誤 |
| UNAUTHORIZED | 401 | 未認證或 Token 無效 |
| FORBIDDEN | 403 | 無權限執行此操作 |
| NOT_FOUND | 404 | 資源不存在 |
| ACTIVITY_FULL | 400 | 活動已額滿 |
| ALREADY_JOINED | 409 | 已經加入此活動 |
| INTERNAL_ERROR | 500 | 伺服器內部錯誤 |

---

## 注意事項

1. 所有時間格式使用 ISO 8601 標準（UTC）
2. 座標使用 WGS84 標準（與 Google Maps 相同）
3. API 限流：每分鐘最多 60 次請求
4. 檔案上傳大小限制：5MB
