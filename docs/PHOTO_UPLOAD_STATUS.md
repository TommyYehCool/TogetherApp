# 照片上傳功能狀態說明

## 當前狀態 ✅

### 前端實作 ✅
- 建立活動時可選擇最多 3 張照片
- 照片預覽功能（使用 Image.memory 支援 Web 平台）
- 主辦人可在個人資料頁面補上傳照片
- 自動壓縮照片（最大 1920x1920，品質 85%）

### 後端 API 狀態 ✅
**照片上傳 API 已確認可用！**

根據 OpenAPI 規格，後端已實作照片上傳功能：

**POST /activities/{activity_id}/upload-images**
- Content-Type: multipart/form-data
- Authorization: Bearer {token}
- Body: files (array<string>) - 最多 3 張照片
- 照片儲存在 AWS S3

## 照片上傳失敗的可能原因

根據 API 規格，可能的失敗原因：

1. **權限問題** ⚠️
   - 只有活動主辦人可以上傳照片
   - 需要確認 Token 是否正確
   - 需要確認是否為活動的主辦人

2. **檔案數量超過限制**
   - 最多只能上傳 3 張照片
   - 前端已有檢查，但後端也會驗證

3. **檔案格式問題**
   - 需要確認後端支援的格式（JPG, PNG, WEBP）
   - 檔案可能損壞或格式不正確

4. **網路或 CORS 問題**
   - 檢查是否有 CORS 錯誤
   - 檢查網路連線狀態

5. **Activity ID 類型錯誤** ⚠️
   - **重要**: 後端 API 使用 `int` 類型的 activity_id
   - 前端目前使用 `String` 類型
   - **需要修正**: 將 String ID 轉換為 int

## 🔧 需要修正的問題

### Activity ID 類型不匹配

**問題**: 
- 前端 Activity model 使用 `String id`
- 後端 API 要求 `int activity_id`

**解決方案**:
在上傳照片時，將 String ID 轉換為 int：

```dart
// api_service.dart
Future<Map<String, dynamic>> uploadActivityImages(String activityId, List<String> imagePaths) async {
  // 將 String ID 轉換為 int
  final activityIdInt = int.tryParse(activityId);
  if (activityIdInt == null) {
    return {
      'success': false,
      'message': '活動 ID 格式錯誤',
    };
  }
  
  final response = await _dio.post(
    '$baseUrl/activities/$activityIdInt/upload-images',  // 使用 int
    data: formData,
  );
}
```

## 主辦人補上傳照片功能 ✅

### 使用方式
1. 進入「個人資料」頁面
2. 點擊「我主辦的活動」
3. 點擊活動卡片右上角的「...」按鈕
4. 選擇「上傳活動照片」
5. 選擇最多 3 張照片
6. 系統自動上傳並顯示結果

### 實作位置
- `lib/screens/profile_screen.dart` - `_uploadActivityPhotos()` 函數
- `lib/services/api_service.dart` - `uploadActivityImages()` 方法
- `lib/services/activity_service.dart` - `uploadActivityImages()` 包裝方法

## API 規格（已確認）

### POST /activities/{activity_id}/upload-images

**說明**: 上傳活動照片（最多 3 張）

**權限**: 只有活動主辦人可以上傳

**Headers**:
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Path Parameters**:
- `activity_id` (int): 活動 ID ⚠️ 注意是 int 類型

**Request Body** (multipart/form-data):
- `files`: File[] - 照片檔案陣列（最多 3 張）

**回應範例** (200):
```json
{
  "message": "照片上傳成功",
  "images": [
    "https://s3.amazonaws.com/bucket/activity_123_1.jpg",
    "https://s3.amazonaws.com/bucket/activity_123_2.jpg"
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

## 測試步驟

### 1. 建立活動時上傳
- ✅ 建立新活動
- ✅ 選擇 1-3 張照片
- ⏳ 確認照片上傳成功（需要修正 ID 類型）
- ⏳ 檢查活動詳情是否顯示照片

### 2. 補上傳照片
- ✅ 進入個人資料頁面
- ✅ 選擇已建立的活動
- ✅ 點擊「上傳活動照片」
- ✅ 選擇照片並上傳
- ⏳ 確認上傳成功（需要修正 ID 類型）

### 3. 錯誤處理
- ✅ 測試上傳超過 3 張照片
- ⏳ 測試非主辦人上傳照片
- ⏳ 確認錯誤訊息正確顯示

## 前端已完成的功能

✅ 照片選擇器（支援多選）
✅ 照片預覽（Web 平台相容，使用 Image.memory）
✅ 照片移除功能
✅ 自動壓縮
✅ 上傳進度指示
✅ 錯誤處理
✅ 主辦人補上傳功能
✅ 所有對話框阻擋背景互動

## 待修正

⚠️ Activity ID 類型轉換（String → int）
⏳ 測試實際上傳功能
⏳ 在活動詳情中顯示照片

---

**更新日期**: 2026-02-04
**狀態**: 後端 API 已確認，前端需要修正 ID 類型轉換

