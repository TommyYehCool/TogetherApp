# Backend API 規格（最新版本 v1.0.0）

**Base URL**: `https://helpful-noticeably-bullfrog.ngrok-free.app`

**API 標題**: Together API - Together 社交媒合平台的後端介面文件

---

## 認證 (Auth)

### GET /auth/me
**說明**: [保護路由] 拿著 JWT Token 換取當前登入用戶的詳細資訊

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例**:
```json
{
  "id": 4,
  "email": "user@example.com",
  "name": "使用者名稱"
}
```

### GET /auth/login/google
**說明**: 啟動 Google OAuth 登入流程

### GET /auth/login/facebook
**說明**: 啟動 Facebook OAuth 登入流程

### GET /auth/google/callback
**說明**: Google OAuth 回調處理

### GET /auth/facebook/callback
**說明**: Facebook OAuth 回調處理

---

## 活動 (Activities)

### POST /activities/
**說明**: 建立新活動

**詳細說明**:
主辦人發起一個社交活動。系統會執行以下動作：
1. 將經緯度轉換為 Geography 地理空間資料以利後續檢索
2. 自動將當前登入用戶設為主辦人 (Host)

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
  "lat": 25.0330,
  "lng": 121.5654,
  "max_slots": 5,
  "activity_type": "學習"
}
```

**欄位說明**:
| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| title | string | 是 | 活動標題 |
| description | string | 是 | 活動描述 |
| lat | float | 是 | 活動地點緯度 |
| lng | float | 是 | 活動地點經度 |
| max_slots | int | 是 | 最大參與人數 |
| activity_type | string | 是 | 活動類型（社交/運動/學習/美食/旅遊/音樂/藝術/其他） |

**回應範例** (200/201):
```json
{
  "id": 123,
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧",
  "lat": 25.0330,
  "lng": 121.5654,
  "current_participants": 1,
  "max_slots": 5,
  "activity_type": "學習",
  "host_id": 4,
  "host_name": "使用者名稱"
}
```

---

### GET /activities/nearby
**說明**: 地圖範圍檢索

**詳細說明**:
根據用戶傳入的經緯度座標，搜尋指定半徑內的活動。
- **排序權重**: 優先顯示付費曝光 (Boosted) 且未過期的活動，其次依照建立時間排序
- **單位**: 距離計算以『公尺』為單位

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| lat | float | 是 | - | 當前位置緯度 |
| lng | float | 是 | - | 當前位置經度 |
| radius_meters | int | 否 | 5000 | 搜尋半徑（公尺） |

**範例請求**:
```
GET /activities/nearby?lat=25.0330&lng=121.5654&radius_meters=300
```

**回應範例**:
```json
[
  {
    "id": 123,
    "title": "咖啡廳讀書會",
    "description": "一起來咖啡廳讀書吧",
    "lat": 25.0330,
    "lng": 121.5654,
    "current_participants": 3,
    "max_slots": 5,
    "activity_type": "學習",
    "host_id": 4,
    "host_name": "小明",
    "is_boosted": true
  }
]
```

---

### GET /activities/search
**說明**: 關鍵字與類型搜尋

**詳細說明**:
透過關鍵字匹配標題或描述，並可篩選特定活動類型。可選擇是否過濾已滿員的活動。

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| query | string | 否 | - | 搜尋關鍵字（標題、描述） |
| activity_type | string | 否 | - | 活動類型篩選 |
| only_available | bool | 否 | true | 只顯示未滿員的活動 |
| limit | int | 否 | 20 | 每頁筆數 |
| offset | int | 否 | 0 | 分頁偏移量 |

**範例請求**:
```
GET /activities/search?query=讀書&activity_type=學習&only_available=true&limit=10
```

**回應範例**:
```json
[
  {
    "id": 123,
    "title": "咖啡廳讀書會",
    "description": "一起來咖啡廳讀書吧",
    "lat": 25.0330,
    "lng": 121.5654,
    "current_participants": 3,
    "max_slots": 5,
    "activity_type": "學習",
    "host_id": 4,
    "host_name": "小明"
  }
]
```

---

### POST /activities/{activity_id}/join
**說明**: 申請加入活動

**詳細說明**:
用戶申請參加該活動。
- **風控邏輯**: 如果用戶的 `no_show_count` (爽約次數) 大於等於 3，系統將拒絕申請
- **重複校驗**: 不能對同一個活動重複發送申請

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**回應範例**:
```json
{
  "message": "申請成功",
  "status": "pending"
}
```

**錯誤回應**:
```json
{
  "detail": "您的爽約次數過多，無法申請活動"
}
```

---

### GET /activities/{activity_id}/requests
**說明**: 【主辦人】查看申請清單

**詳細說明**:
僅限主辦人調用，查看此活動的所有申請者資訊及信用評價。

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**回應範例**:
```json
[
  {
    "request_id": 456,
    "user_id": 5,
    "user_name": "小華",
    "status": "pending",
    "no_show_count": 0,
    "avg_rating": 4.5,
    "created_at": "2024-02-02T10:00:00Z"
  }
]
```

---

### PUT /activities/requests/{request_id}/approve
**說明**: 【主辦人】核准申請

**詳細說明**:
核准用戶參加活動，會同步檢查當前活動是否已滿員。

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `request_id` (int): 申請 ID

**回應範例**:
```json
{
  "message": "已批准",
  "status": "approved"
}
```

**錯誤回應**:
```json
{
  "detail": "活動已滿員"
}
```

---

### POST /activities/{activity_id}/rate
**說明**: 活動後評價主辦人

**詳細說明**:
參與者（需狀態為 accepted）可對主辦人進行一次性評分，將影響主辦人的平均星等。

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**Request Body**:
```json
{
  "score": 5
}
```

**欄位說明**:
| 欄位 | 類型 | 必填 | 範圍 | 說明 |
|------|------|------|------|------|
| score | int | 是 | 1-5 | 評分（1 到 5 星） |

**回應範例**:
```json
{
  "message": "評分成功"
}
```

---

### POST /activities/{activity_id}/mock-boost
**說明**: 測試用：模擬支付曝光

**詳細說明**:
【模擬環境】將活動設為付費曝光狀態，並設定到期日。

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| days | int | 否 | 1 | 曝光天數 |

**範例請求**:
```
POST /activities/123/mock-boost?days=3
```

**回應範例**:
```json
{
  "message": "Boost 成功",
  "boosted_until": "2024-02-05T10:00:00Z"
}
```

---

## 使用者 (Users)

### GET /users/me/hosted
**說明**: 查詢我發起的活動

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例**:
```json
[
  {
    "id": 123,
    "title": "咖啡廳讀書會",
    "description": "一起來咖啡廳讀書吧",
    "lat": 25.0330,
    "lng": 121.5654,
    "current_participants": 3,
    "max_slots": 5,
    "activity_type": "學習"
  }
]
```

---

### GET /users/me/joined
**說明**: 查詢我參加過的活動

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例**:
```json
[
  {
    "id": 456,
    "title": "籃球鬥牛",
    "description": "缺 2 人打全場",
    "lat": 25.0320,
    "lng": 121.5644,
    "current_participants": 4,
    "max_slots": 6,
    "activity_type": "運動",
    "host_id": 7,
    "host_name": "阿傑"
  }
]
```

---

## 重要功能說明

### 風控機制
- **爽約次數限制**: 用戶的 `no_show_count` >= 3 時，無法申請新活動
- **重複申請防護**: 同一用戶不能對同一活動重複申請

### 排序邏輯
- **地圖檢索**: 優先顯示 Boosted 活動，其次按建立時間排序
- **搜尋結果**: 可過濾未滿員活動

### 評分系統
- 只有狀態為 `accepted` 的參與者可以評分
- 每個參與者對每個活動只能評分一次
- 評分會影響主辦人的平均星等

---

## 錯誤回應格式

**422 Validation Error**:
```json
{
  "detail": [
    {
      "loc": ["body", "lat"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

**401 Unauthorized**:
```json
{
  "detail": "Not authenticated"
}
```

**403 Forbidden**:
```json
{
  "detail": "Permission denied"
}
```

**400 Bad Request**:
```json
{
  "detail": "您的爽約次數過多，無法申請活動"
}
```

### GET /auth/me
**說明**: [保護路由] 拿著 JWT Token 換取當前登入用戶的詳細資訊

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例**:
```json
{
  "id": 4,
  "email": "user@example.com",
  "name": "使用者名稱"
}
```

### GET /auth/login/google
**說明**: 啟動 Google OAuth 登入流程

### GET /auth/login/facebook
**說明**: 啟動 Facebook OAuth 登入流程

### GET /auth/google/callback
**說明**: Google OAuth 回調處理

### GET /auth/facebook/callback
**說明**: Facebook OAuth 回調處理

---

## 活動 (Activities)

### POST /activities/
**說明**: 建立新活動

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
  "lat": 25.0330,
  "lng": 121.5654,
  "max_slots": 5,
  "activity_type": "學習"
}
```

**欄位說明**:
| 欄位 | 類型 | 必填 | 說明 |
|------|------|------|------|
| title | string | 是 | 活動標題 |
| description | string | 是 | 活動描述 |
| lat | float | 是 | 活動地點緯度 |
| lng | float | 是 | 活動地點經度 |
| max_slots | int | 是 | 最大參與人數 |
| activity_type | string | 是 | 活動類型（社交/運動/學習/美食/旅遊/音樂/藝術/其他） |

**回應範例** (200/201):
```json
{
  "id": 123,
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧",
  "lat": 25.0330,
  "lng": 121.5654,
  "current_participants": 1,
  "max_slots": 5,
  "activity_type": "學習",
  "host_id": 4,
  "host_name": "使用者名稱"
}
```

---

### GET /activities/nearby
**說明**: 地圖檢索 API - 取得附近的活動（距離計算單位為公尺）

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| lat | float | 是 | - | 當前位置緯度 |
| lng | float | 是 | - | 當前位置經度 |
| radius_meters | int | 否 | 5000 | 搜尋半徑（公尺） |

**範例請求**:
```
GET /activities/nearby?lat=25.0330&lng=121.5654&radius_meters=300
```

**回應範例**:
```json
[
  {
    "id": 123,
    "title": "咖啡廳讀書會",
    "description": "一起來咖啡廳讀書吧",
    "lat": 25.0330,
    "lng": 121.5654,
    "current_participants": 3,
    "max_slots": 5,
    "activity_type": "學習",
    "host_id": 4,
    "host_name": "小明"
  }
]
```

---

### GET /activities/search
**說明**: 進階搜尋 API - 可依關鍵字、類型搜尋，並過濾未滿員活動

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| query | string | 否 | - | 搜尋關鍵字（標題、描述） |
| activity_type | string | 否 | - | 活動類型篩選 |
| only_available | bool | 否 | true | 只顯示未滿員的活動 |
| limit | int | 否 | 20 | 每頁筆數 |
| offset | int | 否 | 0 | 分頁偏移量 |

**範例請求**:
```
GET /activities/search?query=讀書&activity_type=學習&only_available=true&limit=10
```

**回應範例**:
```json
[
  {
    "id": 123,
    "title": "咖啡廳讀書會",
    "description": "一起來咖啡廳讀書吧",
    "lat": 25.0330,
    "lng": 121.5654,
    "current_participants": 3,
    "max_slots": 5,
    "activity_type": "學習",
    "host_id": 4,
    "host_name": "小明"
  }
]
```

---

### POST /activities/{activity_id}/join
**說明**: 申請參加活動

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**回應範例**:
```json
{
  "message": "申請成功",
  "status": "pending"
}
```

---

### GET /activities/{activity_id}/requests
**說明**: 主辦人查看申請名單

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**回應範例**:
```json
[
  {
    "request_id": 456,
    "user_id": 5,
    "user_name": "小華",
    "status": "pending",
    "created_at": "2024-02-02T10:00:00Z"
  }
]
```

---

### PUT /activities/requests/{request_id}/approve
**說明**: 主辦人批准申請

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `request_id` (int): 申請 ID

**回應範例**:
```json
{
  "message": "已批准",
  "status": "approved"
}
```

---

### POST /activities/{activity_id}/rate
**說明**: 活動結束後對主辦人評分

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**Request Body**:
```json
{
  "score": 5
}
```

**欄位說明**:
| 欄位 | 類型 | 必填 | 範圍 | 說明 |
|------|------|------|------|------|
| score | int | 是 | 1-5 | 評分（1 到 5 星） |

**回應範例**:
```json
{
  "message": "評分成功"
}
```

---

### POST /activities/{activity_id}/mock-boost
**說明**: 模擬支付成功 - 將活動設為付費曝光狀態

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| days | int | 否 | 1 | 曝光天數 |

**範例請求**:
```
POST /activities/123/mock-boost?days=3
```

**回應範例**:
```json
{
  "message": "Boost 成功",
  "boosted_until": "2024-02-05T10:00:00Z"
}
```

---

## 使用者 (Users)

### GET /users/me/hosted
**說明**: 查詢我發起的活動

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例**:
```json
[
  {
    "id": 123,
    "title": "咖啡廳讀書會",
    "description": "一起來咖啡廳讀書吧",
    "lat": 25.0330,
    "lng": 121.5654,
    "current_participants": 3,
    "max_slots": 5,
    "activity_type": "學習"
  }
]
```

---

### GET /users/me/joined
**說明**: 查詢我參加過的活動

**Headers**:
```
Authorization: Bearer {token}
```

**回應範例**:
```json
[
  {
    "id": 456,
    "title": "籃球鬥牛",
    "description": "缺 2 人打全場",
    "lat": 25.0320,
    "lng": 121.5644,
    "current_participants": 4,
    "max_slots": 6,
    "activity_type": "運動",
    "host_id": 7,
    "host_name": "阿傑"
  }
]
```

---

## 重要變更說明

### 與舊版 API 的差異

1. **建立活動欄位變更**:
   - `latitude` → `lat`
   - `longitude` → `lng`
   - `max_participants` → `max_slots`
   - `category` → `activity_type`
   - ❌ 移除 `start_time` 欄位

2. **附近活動查詢**:
   - `radius` → `radius_meters`（明確單位為公尺）

3. **activity_id 類型**:
   - 從 string (UUID) 改為 int

4. **新增功能**:
   - ✅ 進階搜尋 API (`/activities/search`)
   - ✅ 評分功能只需要 score（移除 comment）

---

## 錯誤回應格式

**422 Validation Error**:
```json
{
  "detail": [
    {
      "loc": ["body", "lat"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

**401 Unauthorized**:
```json
{
  "detail": "Not authenticated"
}
```

**403 Forbidden**:
```json
{
  "detail": "Permission denied"
}
```
