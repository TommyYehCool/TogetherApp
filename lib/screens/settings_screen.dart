import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';
import '../utils/api_diagnostics.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenController = TextEditingController();
  bool _tokenSaved = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF00D0DD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Token 設定
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key, color: Color(0xFF00D0DD)),
                      const SizedBox(width: 8),
                      const Text(
                        'API Token 設定',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '請輸入你的 Bearer Token 以連接後端 API',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Bearer Token',
                      hintText: '貼上你的 Token',
                      border: const OutlineInputBorder(),
                      suffixIcon: _tokenSaved
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveToken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D0DD),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            '儲存 Token',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _clearToken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                        ),
                        child: const Text(
                          '清除',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // API 資訊
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF00D0DD)),
                      const SizedBox(width: 8),
                      const Text(
                        'API 資訊',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Base URL', 'https://helpful-noticeably-bullfrog.ngrok-free.app'),
                  const Divider(),
                  _buildInfoRow('環境', 'Development (ngrok)'),
                  const Divider(),
                  _buildInfoRow('認證方式', 'Bearer Token'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 測試連線
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: Color(0xFF00D0DD)),
                      const SizedBox(width: 8),
                      const Text(
                        '測試連線',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('測試 API 連線'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 說明
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '使用說明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. 從後端取得你的 Bearer Token\n'
                    '2. 將 Token 貼上到上方欄位\n'
                    '3. 點擊「儲存 Token」\n'
                    '4. 點擊「測試 API 連線」確認連線\n'
                    '5. 如果沒有 Token，應用程式會使用 Mock 資料',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Chrome 測試注意事項',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '在 Chrome 測試時可能遇到 CORS 錯誤。\n'
                          '建議使用 Android/iOS 模擬器測試，\n'
                          '或請後端開發者設定 CORS headers。',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF2D3436)),
            ),
          ),
        ],
      ),
    );
  }

  void _saveToken() {
    final token = _tokenController.text.trim();
    
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請輸入 Token'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 儲存 Token 到 ActivityService
    context.read<ActivityService>().setAuthToken(token);

    setState(() {
      _tokenSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token 已儲存！'),
        backgroundColor: Color(0xFF00D0DD),
      ),
    );
  }

  void _clearToken() {
    _tokenController.clear();
    setState(() {
      _tokenSaved = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token 已清除'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Future<void> _testConnection() async {
    final service = context.read<ActivityService>();
    final token = service.apiService.currentToken;
    
    // 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00D0DD),
        ),
      ),
    );

    try {
      // 執行診斷
      final results = await ApiDiagnostics.checkApiConnection(
        baseUrl: service.apiService.baseUrl,
        token: token,
      );
      
      final report = ApiDiagnostics.generateReport(results);
      
      if (mounted) {
        Navigator.pop(context); // 關閉載入對話框
        
        // 顯示診斷報告
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  results['connection']?['success'] == true 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: results['connection']?['success'] == true 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('診斷報告'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                report,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('確定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 關閉載入對話框
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('診斷失敗'),
              ],
            ),
            content: Text('診斷過程發生錯誤:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('確定'),
              ),
            ],
          ),
        );
      }
    }
  }
}
