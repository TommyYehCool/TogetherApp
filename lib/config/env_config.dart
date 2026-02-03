import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境變數配置類
/// 統一管理所有環境變數
class EnvConfig {
  /// Google Maps API Key
  static String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_GOOGLE_MAPS_API_KEY';
  
  /// 後端 API Base URL
  static String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'https://helpful-noticeably-bullfrog.ngrok-free.app';
  
  /// 開發用 Bearer Token（選填）
  static String get devBearerToken => 
      dotenv.env['DEV_BEARER_TOKEN'] ?? '';
  
  /// 檢查環境變數是否已正確設定
  static bool get isConfigured {
    return googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY' &&
           apiBaseUrl.isNotEmpty;
  }
  
  /// 顯示配置狀態（用於 Debug）
  static void printConfig() {
    print('\n========== 環境變數配置 ==========');
    print('Google Maps API Key: ${googleMapsApiKey.substring(0, 10)}...');
    print('API Base URL: $apiBaseUrl');
    print('Dev Token: ${devBearerToken.isNotEmpty ? "已設定" : "未設定"}');
    print('配置狀態: ${isConfigured ? "✅ 完整" : "⚠️ 未完成"}');
    print('==================================\n');
  }
}
