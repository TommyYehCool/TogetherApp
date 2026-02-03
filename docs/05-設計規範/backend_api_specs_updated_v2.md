# Backend API 規格（最新版本 v1.0.0）

**Base URL**: `https://helpful-noticeably-bullfrog.ngrok-free.app`

**API 標題**: Together API - Together 社交媒合平台的後端介面文件

---

## 📸 照片上傳功能

### POST /activities/{activity_id}/upload-images
**說明**: 上傳活動照片

**詳細說明**:
主辦人為活動上傳照片，限制最多 3 張，照片將上傳至 AWS S3。
- **權限**: 只有活動主辦人可以上傳
- **限制**: 最多 3 張照片
- **格式**: 支援 JPG, PNG, WEBP
- **儲存**: 照片上傳至 AWS S3

**Headers**:
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Path Parameters**:
- `activity_id` (int): 活動 ID

**Request Body** (multipart/form-data):
```
files: File[] (array<string>)
```

**範例請求** (使用 curl):
```bash
curl -X POST "https://helpful-noticeably-bullfrog.ngrok-free.app/activities/123/upload-images" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "files=@photo1.jpg" \
  -F "files=@photo2.jpg" \
  -F "files=@photo3.jpg"
```

**回應範例** (200):
```json
{
  "message": "照片上傳成功",
  "images": [
    "https://s3.amazonaws.com/bucket/activity_123_1.jpg",
    "https://s3.amazonaws.com/bucket/activity_123_2.jpg",
    "https://s3.amazonaws.com/bucket/activity_123_3.jpg"
  ]
}
```

**錯誤回應**:

403 Forbidden:
```json
{
  "detail": "只有主辦人可以上傳照片"
}
```

400 Bad Request:
```json
{
  "detail": "最多只能上傳 3 張照片"
}
```

422 Validation Error:
```json
{
  "detail": [
    {
      "loc": ["body", "files"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

---

### POST /users/upload/avatar
**說明**: 上傳用戶大頭貼

**詳細說明**:
將照片上傳至 AWS S3 並更新資料庫中的頭像連結。

**Headers**:
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body** (multipart/form-data):
```
file: File (string)
```

**範例請求** (使用 curl):
```bash
curl -X POST "https://helpful-noticeably-bullfrog.ngrok-free.app/users/upload/avatar" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@avatar.jpg"
```

**回應範例** (200):
```json
{
  "message": "大頭貼上傳成功",
  "avatar_url": "https://s3.amazonaws.com/bucket/avatar_user_4.jpg"
}
```

---

## 🎯 活動相關 APIs

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
  "activity_type": "學習",
  "region": "台北市",
  "address": "信義區信義路五段7號",
  "start_time": "2024-02-04T14:00:00Z",
  "end_time": "2024-02-04T16:00:00Z",
  "registration_deadline": "2024-02-04T12:00:00Z"
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
| activity_type | string | 是 | 活動類型 |
| region | string | 是 | 地區 |
| address | string | 是 | 詳細地址 |
| start_time | datetime | 是 | 開始時間 |
| end_time | datetime | 是 | 結束時間 |
| registration_deadline | datetime | 否 | 報名截止時間 |

**回應範例**:
```json
{
  "id": 123,
  "title": "咖啡廳讀書會",
  "description": "一起來咖啡廳讀書吧",
  "activity_type": "學習",
  "max_slots": 5,
  "region": "台北市",
  "address": "信義區信義路五段7號",
  "lat": 25.0330,
  "lng": 121.5654,
  "is_boosted": false,
  "host_rating": 0.0,
  "slots_info": "1/5",
  "can_join": true,
  "host_username": "使用者名稱",
  "images": [],
  "start_time": "2024-02-04T14:00:00Z",
  "end_time": "2024-02-04T16:00:00Z",
  "registration_deadline": "2024-02-04T12:00:00Z",
  "created_at": "2024-02-04T10:00:00Z"
}
```

---

### GET /activities/nearby
**說明**: 地圖範圍檢索

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
    "activity_type": "學習",
    "max_slots": 5,
    "region": "台北市",
    "address": "信義區信義路五段7號",
    "lat": 25.0330,
    "lng": 121.5654,
    "is_boosted": true,
    "host_rating": 4.5,
    "slots_info": "3/5",
    "can_join": true,
    "host_username": "小明",
    "images": [
      "https://s3.amazonaws.com/bucket/activity_123_1.jpg",
      "https://s3.amazonaws.com/bucket/activity_123_2.jpg"
    ],
    "start_time": "2024-02-04T14:00:00Z",
    "end_time": "2024-02-04T16:00:00Z",
    "created_at": "2024-02-04T10:00:00Z"
  }
]
```

---

### GET /activities/search
**說明**: 關鍵字與類型搜尋

**Query Parameters**:
| 參數 | 類型 | 必填 | 預設值 | 說明 |
|------|------|------|--------|------|
| query | string | 否 | - | 搜尋關鍵字 |
| region | string | 否 | - | 地區篩選 |
| activity_type | string | 否 | - | 活動類型篩選 |
| only_available | bool | 否 | true | 只顯示未滿員 |
| limit | int | 否 | 20 | 每頁筆數 |
| offset | int | 否 | 0 | 分頁偏移量 |

---

### POST /activities/{activity_id}/join
**說明**: 申請加入活動

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
**說明**: 【主辦人】查看申請清單

**Headers**:
```
Authorization: Bearer {token}
```

---

### PUT /activities/requests/{request_id}/approve
**說明**: 【主辦人】核准申請

**Headers**:
```
Authorization: Bearer {token}
```

---

### POST /activities/{activity_id}/rate
**說明**: 活動後評價主辦人

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "score": 5
}
```

---

### POST /activities/{activity_id}/mock-boost
**說明**: 測試用：模擬支付曝光

**Headers**:
```
Authorization: Bearer {token}
```

**Query Parameters**:
- `days` (int, 預設: 1): 曝光天數

---

## 👤 使用者相關 APIs

### GET /users/me/hosted
**說明**: 查詢我發起的活動

**Headers**:
```
Authorization: Bearer {token}
```

---

### GET /users/me/joined
**說明**: 查詢我參加的活動紀錄

**Headers**:
```
Authorization: Bearer {token}
```

---

## 🔐 認證相關 APIs

### GET /auth/me
**說明**: 取得當前用戶資訊

**Headers**:
```
Authorization: Bearer {token}
```

### GET /auth/login/google
**說明**: Google OAuth 登入

### GET /auth/login/facebook
**說明**: Facebook OAuth 登入

---

## 📝 重要說明

### ActivityResponse 欄位說明

| 欄位 | 類型 | 說明 |
|------|------|------|
| id | int | 活動 ID |
| title | string | 活動標題 |
| description | string | 活動描述 |
| activity_type | string | 活動類型 |
| max_slots | int | 最大參與人數 |
| region | string | 地區 |
| address | string | 詳細地址 |
| lat | float | 緯度 |
| lng | float | 經度 |
| is_boosted | bool | 是否付費曝光 |
| host_rating | float | 主辦人評分 (預設 0.0) |
| slots_info | string | 人數資訊 (例如: "3/5") |
| can_join | bool | 是否可加入 (預設 true) |
| host_username | string | 主辦人名稱 |
| images | array | 活動照片 URL 陣列 (預設 []) |
| start_time | datetime | 開始時間 |
| end_time | datetime | 結束時間 |
| registration_deadline | datetime | 報名截止時間 (可為 null) |
| created_at | datetime | 建立時間 |

### 照片上傳注意事項

1. **multipart/form-data 格式**
   - 活動照片: 使用 `files` 欄位（陣列）
   - 用戶頭像: 使用 `file` 欄位（單一檔案）

2. **前端實作**
   ```dart
   // 活動照片上傳
   final formData = FormData();
   for (var imagePath in imagePaths) {
     final file = await MultipartFile.fromFile(imagePath, filename: 'image.jpg');
     formData.files.add(MapEntry('files', file));
   }
   
   // 用戶頭像上傳
   final formData = FormData.fromMap({
     'file': await MultipartFile.fromFile(imagePath, filename: 'avatar.jpg'),
   });
   ```

3. **限制**
   - 活動照片: 最多 3 張
   - 檔案格式: JPG, PNG, WEBP
   - 建議壓縮: 最大 1920x1920, 品質 85%

---

**更新日期**: 2026-02-04
**版本**: v1.0.0
**狀態**: ✅ 照片上傳 API 已確認可用
