# CORS 設定指南（給後端開發者）

## 需要允許的網域

### 開發環境
Flutter Web 在開發時會使用以下網域：

```
http://localhost:*
http://127.0.0.1:*
```

常見的 Flutter Web 開發端口：
- `http://localhost:53000` (預設)
- `http://localhost:8080`
- `http://localhost:3000`
- 或任何 Flutter 自動分配的端口

### 建議設定

#### 方案 1：開發環境允許所有來源（最簡單）
```python
# FastAPI 範例
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 開發環境允許所有來源
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

#### 方案 2：只允許特定網域（較安全）
```python
# FastAPI 範例
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:53000",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://127.0.0.1:53000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
```

#### 方案 3：使用環境變數（推薦用於生產環境）
```python
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# 從環境變數讀取允許的來源
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

然後設定環境變數：
```bash
# 開發環境
export ALLOWED_ORIGINS="http://localhost:53000,http://localhost:8080"

# 生產環境
export ALLOWED_ORIGINS="https://your-production-domain.com"
```

---

## 其他後端框架範例

### Express.js (Node.js)
```javascript
const express = require('express');
const cors = require('cors');

const app = express();

// 開發環境
app.use(cors({
  origin: '*',
  credentials: true
}));

// 或指定網域
app.use(cors({
  origin: ['http://localhost:53000', 'http://localhost:8080'],
  credentials: true
}));
```

### Django
```python
# settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:53000",
    "http://localhost:8080",
    "http://127.0.0.1:53000",
]

# 或開發環境允許所有
CORS_ALLOW_ALL_ORIGINS = True

CORS_ALLOW_CREDENTIALS = True
```

### Spring Boot (Java)
```java
@Configuration
public class CorsConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                    .allowedOrigins("http://localhost:53000", "http://localhost:8080")
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowCredentials(true);
            }
        };
    }
}
```

---

## 如何找到 Flutter Web 的端口

### 方法 1：查看終端輸出
執行 `flutter run -d chrome` 後，終端會顯示：
```
Launching lib/main.dart on Chrome in debug mode...
Building application for the web...
lib/main.dart is being served at http://localhost:53000
```

### 方法 2：查看瀏覽器網址列
Chrome 開啟後，網址列會顯示完整 URL，例如：
```
http://localhost:53000/#/
```

### 方法 3：使用固定端口
```bash
flutter run -d chrome --web-port=8080
```
這樣就會固定使用 `http://localhost:8080`

---

## 驗證 CORS 設定

### 使用 curl 測試
```bash
curl -X OPTIONS \
  -H "Origin: http://localhost:53000" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  -v \
  https://helpful-noticeably-bullfrog.ngrok-free.app/activities/nearby
```

應該看到回應 headers 包含：
```
Access-Control-Allow-Origin: http://localhost:53000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Authorization
```

### 使用瀏覽器開發者工具
1. 打開 Chrome DevTools (F12)
2. 切換到 Network 標籤
3. 執行 API 請求
4. 查看 Response Headers 是否包含 CORS headers

---

## 常見 CORS 錯誤

### 錯誤 1：No 'Access-Control-Allow-Origin' header
**原因：** 後端沒有設定 CORS
**解決：** 加入 CORS middleware

### 錯誤 2：CORS policy: Credentials flag is 'true'
**原因：** 使用 credentials 時不能用 `*` 作為 origin
**解決：** 明確指定允許的網域

### 錯誤 3：Method not allowed
**原因：** 沒有允許特定的 HTTP 方法
**解決：** 在 `allow_methods` 加入需要的方法

---

## 快速設定檢查清單

後端開發者請確認：

- [ ] 已安裝 CORS middleware
- [ ] 允許 `http://localhost:*` 或特定端口
- [ ] 允許的方法包含：GET, POST, PUT, DELETE, OPTIONS
- [ ] 允許的 headers 包含：Authorization, Content-Type
- [ ] 如果使用 credentials，不能用 `*` 作為 origin
- [ ] 重啟後端服務使設定生效
- [ ] 使用 curl 或瀏覽器測試 CORS headers

---

## 給 Together App 後端的建議設定

```python
# FastAPI - Together App 後端
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# 開發環境設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:53000",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://127.0.0.1:53000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "ngrok-skip-browser-warning"],
)
```

設定完成後，Flutter Web 應該就能正常連接 API 了！
