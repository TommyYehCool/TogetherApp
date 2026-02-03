# API 變更記錄

## 2026-02-03: 後端 API 規格更新

### 重大變更：ActivityCreate Schema

後端 API 的 `POST /activities/` 端點現在要求以下**必填欄位**：

#### 新增必填欄位

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| `region` | string | 地區（縣市） | "台北市"、"新北市" |
| `address` | string | 詳細地址 | "信義區信義路五段7號" |

#### 完整 ActivityCreate Schema

```json
{
  "title": "string",           // 必填：活動標題
  "description": "string",     // 必填：活動說明
  "max_slots": "integer",      // 必填：人數上限
  "activity_type": "string",   // 必填：活動類型
  "region": "string",          // 必填：地區（新增）
  "address": "string",         // 必填：詳細地址（新增）
  "lat": "number",             // 必填：緯度
  "lng": "number"              // 必填：經度
}
```

### 後端處理邏輯

根據 API 文件說明，後端會執行以下動作：

1. **地理空間轉換**：將經緯度轉換為 Geography 地理空間資料以利後續檢索
2. **儲存地區資訊**：儲存必填的 `region` (地區)
3. **儲存詳細地址**：儲存必填的 `address` (詳細地址)
4. **設定主辦人**：自動將當前登入用戶設為主辦人 (Host)

### 前端更新內容

#### 1. API Service (`lib/services/api_service.dart`)

**變更**：`createActivity` 方法新增兩個必填參數

```dart
Future<Activity?> createActivity({
  required String title,
  required String description,
  required double latitude,
  required double longitude,
  required int maxParticipants,
  required String activityType,
  required String region,      // 新增必填
  required String address,     // 新增必填
})
```

**API 請求範例**：
```dart
final response = await _dio.post(
  '$baseUrl/activities/',
  data: {
    'title': title,
    'description': description,
    'lat': latitude,
    'lng': longitude,
    'max_slots': maxParticipants,
    'activity_type': activityType,
    'region': region,          // 新增
    'address': address,        // 新增
  },
);
```

#### 2. Activity Service (`lib/services/activity_service.dart`)

**變更**：`createActivity` 方法新增兩個必填參數並傳遞給 API Service

```dart
Future<Activity?> createActivity({
  required String title,
  required String description,
  required double latitude,
  required double longitude,
  required int maxParticipants,
  required String activityType,
  required String region,      // 新增必填
  required String address,     // 新增必填
})
```

#### 3. Create Activity Dialog (`lib/widgets/create_activity_dialog.dart`)

**變更**：從 `_locationAddress` 中提取 `region` 和 `address`

```dart
// 從完整地址中提取地區（取前面的部分作為 region）
String region = _locationAddress;
String address = _locationAddress;

// 嘗試從地址中提取地區（例如：台北市、新北市等）
final regionMatch = RegExp(r'([\u4e00-\u9fa5]+[市縣])').firstMatch(_locationAddress);
if (regionMatch != null) {
  region = regionMatch.group(1) ?? _locationAddress;
}

final activity = await service.createActivity(
  title: _titleController.text,
  description: _descriptionController.text,
  latitude: _selectedLocation.latitude,
  longitude: _selectedLocation.longitude,
  maxParticipants: _maxParticipants,
  activityType: _selectedCategory,
  region: region,    // 傳遞地區
  address: address,  // 傳遞地址
);
```

**地區提取邏輯**：
- 使用正則表達式 `([\u4e00-\u9fa5]+[市縣])` 匹配中文地區名稱
- 例如：從 "台北市信義區信義路五段7號" 提取 "台北市"
- 如果無法提取，則使用完整地址作為 region

#### 4. Activity Model (`lib/models/activity.dart`)

**變更**：新增 `region` 欄位

```dart
class Activity {
  final String? address;  // 詳細地址
  final String? region;   // 地區（新增）
  final String? status;   // 活動狀態
  
  Activity({
    // ... 其他欄位
    this.address,
    this.region,   // 新增
    this.status,
  });
}
```

**fromJson 更新**：
```dart
factory Activity.fromJson(Map<String, dynamic> json) {
  return Activity(
    // ... 其他欄位
    address: json['address'] as String?,
    region: json['region'] as String?,    // 新增
    status: json['status'] as String?,
  );
}
```

### 向後相容性

- ✅ **GET /activities/nearby**：回傳資料現在包含 `region` 和 `address` 欄位
- ✅ **GET /activities/search**：回傳資料現在包含 `region` 和 `address` 欄位
- ✅ **Activity Model**：`region` 和 `address` 為可選欄位，不影響現有資料解析

### 測試建議

#### 1. 測試建立活動

```dart
// 測試案例 1：完整地址
region: "台北市"
address: "台北市信義區信義路五段7號"

// 測試案例 2：簡短地址
region: "新北市"
address: "新北市板橋區中山路一段161號"

// 測試案例 3：只有地區
region: "台中市"
address: "台中市"
```

#### 2. 驗證 API 請求

檢查 Console 輸出：
```
========== 建立活動開始 ==========
建立活動 API 請求:
URL: https://your-api.com/activities/
Data: {
  title: 咖啡廳讀書會,
  description: 一起來讀書,
  lat: 25.033,
  lng: 121.565,
  max_slots: 5,
  activity_type: 學習,
  region: 台北市,
  address: 台北市信義區信義路五段7號
}
```

#### 3. 驗證後端回應

成功回應：
```json
{
  "status": "success",
  "activity_id": 123
}
```

錯誤回應（缺少必填欄位）：
```json
{
  "detail": [
    {
      "loc": ["body", "region"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

### 常見問題

#### Q1: 如果地址搜尋失敗怎麼辦？
A: `LocationPickerDialog` 會使用座標作為預設地址，並嘗試反向地理編碼取得實際地址。

#### Q2: region 和 address 可以相同嗎？
A: 可以。如果無法提取地區，兩者都會使用完整地址。

#### Q3: 後端如何使用 region 欄位？
A: 根據 API 文件，後端會：
- 儲存 region 用於地區篩選
- 儲存 address 用於詳細地址顯示
- 將經緯度轉換為 Geography 資料用於空間檢索

#### Q4: 舊的活動資料會受影響嗎？
A: 不會。`region` 和 `address` 在 Activity Model 中是可選欄位，舊資料會顯示為 null。

### 相關文件

- `docs/GOOGLE_MAPS_API_SETUP.md` - Google Maps API 設定指南
- `docs/IMPLEMENTATION_STATUS.md` - 實作狀態總覽
- `docs/05-設計規範/backend_api_specs_updated.md` - 後端 API 規格

### 更新日期

- **2026-02-03**: 初始版本 - 新增 region 和 address 必填欄位

---

## 其他 API 端點（無變更）

以下端點維持原有規格：

- ✅ `GET /activities/nearby` - 地圖範圍檢索
- ✅ `GET /activities/search` - 關鍵字與類型搜尋
- ✅ `POST /activities/{activity_id}/join` - 申請加入活動
- ✅ `GET /activities/{activity_id}/requests` - 查看申請清單
- ✅ `PUT /activities/requests/{request_id}/approve` - 核准申請
- ✅ `POST /activities/{activity_id}/rate` - 活動後評價
- ✅ `POST /activities/{activity_id}/mock-boost` - 測試用曝光
- ✅ `GET /users/me/hosted` - 查詢我發起的活動
- ✅ `GET /users/me/joined` - 查詢我參加的活動
- ✅ `POST /users/upload/avatar` - 上傳用戶大頭貼

### 認證相關（無變更）

- ✅ `GET /auth/me` - 取得當前用戶資訊
- ✅ `GET /auth/login/google` - Google 登入
- ✅ `GET /auth/login/facebook` - Facebook 登入
- ✅ `GET /auth/google/callback` - Google 回調
- ✅ `GET /auth/facebook/callback` - Facebook 回調
