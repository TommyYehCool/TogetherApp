import 'package:dio/dio.dart';

class ApiDiagnostics {
  static Future<Map<String, dynamic>> checkApiConnection({
    required String baseUrl,
    String? token,
  }) async {
    final dio = Dio();
    final results = <String, dynamic>{};

    // 1. 檢查網路連線
    print('=== API 診斷開始 ===');
    print('Base URL: $baseUrl');
    print('Token: ${token != null && token.isNotEmpty ? "${token.substring(0, 20)}..." : "未設定"}');

    // 2. 測試基本連線
    try {
      print('\n[測試 1] 測試基本連線...');
      
      // 設定較長的超時時間
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      
      final response = await dio.get(
        '$baseUrl/activities/nearby',
        queryParameters: {
          'lat': 25.0330,
          'lng': 121.5654,
          'radius': 5000,
        },
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true, // 接受所有狀態碼
          followRedirects: true,
        ),
      );

      results['connection'] = {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusMessage,
        'data': response.data,
      };

      print('狀態碼: ${response.statusCode}');
      print('回應: ${response.data}');

      if (response.statusCode == 401) {
        print('❌ 認證失敗：Token 無效或已過期');
        results['tokenValid'] = false;
      } else if (response.statusCode == 200) {
        print('✅ 連線成功');
        results['tokenValid'] = true;
      } else if (response.statusCode == 403) {
        print('❌ 權限不足：可能是 CORS 問題');
        results['corsIssue'] = true;
      }
    } on DioException catch (e) {
      print('❌ 連線失敗: ${e.type}');
      print('錯誤訊息: ${e.message}');
      
      results['connection'] = {
        'success': false,
        'error': e.message,
        'errorType': e.type.toString(),
      };
      
      // 判斷錯誤類型
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        print('⚠️ 連線超時：後端可能未運行或網路問題');
        results['timeoutIssue'] = true;
      } else if (e.type == DioExceptionType.connectionError) {
        print('⚠️ 連線錯誤：可能是 CORS 問題或後端未運行');
        results['connectionError'] = true;
      }
    } catch (e) {
      print('❌ 未知錯誤: $e');
      results['connection'] = {
        'success': false,
        'error': e.toString(),
      };
    }

    // 3. 檢查 Token 格式
    if (token != null && token.isNotEmpty) {
      print('\n[測試 2] 檢查 Token 格式...');
      final parts = token.split('.');
      if (parts.length == 3) {
        print('✅ Token 格式正確（JWT）');
        results['tokenFormat'] = true;
      } else {
        print('❌ Token 格式錯誤');
        results['tokenFormat'] = false;
      }
    } else {
      print('\n[測試 2] ⚠️ 未設定 Token');
      results['tokenFormat'] = false;
    }

    print('\n=== 診斷完成 ===\n');
    return results;
  }

  static String generateReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('API 診斷報告');
    buffer.writeln('=' * 40);

    if (results['connection'] != null) {
      final conn = results['connection'];
      buffer.writeln('\n連線測試:');
      buffer.writeln('  狀態: ${conn['success'] ? '✅ 成功' : '❌ 失敗'}');
      if (conn['statusCode'] != null) {
        buffer.writeln('  HTTP 狀態碼: ${conn['statusCode']}');
      }
      if (conn['error'] != null) {
        buffer.writeln('  錯誤: ${conn['error']}');
      }
      if (conn['errorType'] != null) {
        buffer.writeln('  錯誤類型: ${conn['errorType']}');
      }
    }

    buffer.writeln('\nToken 檢查:');
    buffer.writeln('  格式: ${results['tokenFormat'] == true ? '✅ 正確' : '❌ 錯誤'}');
    buffer.writeln('  有效性: ${results['tokenValid'] == true ? '✅ 有效' : '❌ 無效或未設定'}');

    buffer.writeln('\n建議:');
    
    // CORS 問題
    if (results['connectionError'] == true || results['corsIssue'] == true) {
      buffer.writeln('  ⚠️ 偵測到 CORS 或連線問題：');
      buffer.writeln('  • 在 Chrome 測試時，後端需要設定 CORS headers');
      buffer.writeln('  • 或使用 Android/iOS 模擬器測試（無 CORS 限制）');
      buffer.writeln('  • 確認後端服務正在運行');
      buffer.writeln('  • 檢查 ngrok tunnel 是否正常');
    }
    
    if (results['tokenValid'] != true && results['connectionError'] != true) {
      buffer.writeln('  • 請到設定頁面輸入有效的 Bearer Token');
      buffer.writeln('  • 確認 Token 未過期');
    }
    
    if (results['timeoutIssue'] == true) {
      buffer.writeln('  • 連線超時：檢查網路連線');
      buffer.writeln('  • 確認後端服務正在運行');
    }
    
    if (results['connection']?['success'] != true && results['connectionError'] != true) {
      buffer.writeln('  • 檢查網路連線');
      buffer.writeln('  • 確認後端服務正在運行');
      buffer.writeln('  • 檢查 Base URL 是否正確');
    }

    buffer.writeln('\n💡 提示：');
    buffer.writeln('  如果是 CORS 問題，建議：');
    buffer.writeln('  1. 使用 Android/iOS 模擬器測試');
    buffer.writeln('  2. 或請後端開發者設定 CORS');
    buffer.writeln('  3. 或使用 Mock 資料模式開發');

    return buffer.toString();
  }
}
