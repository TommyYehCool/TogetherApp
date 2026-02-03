import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import '../services/activity_service.dart';
import 'location_picker_dialog.dart';

class CreateActivityDialog extends StatefulWidget {
  final LatLng initialPosition;
  final VoidCallback onActivityCreated;

  const CreateActivityDialog({
    super.key,
    required this.initialPosition,
    required this.onActivityCreated,
  });

  @override
  State<CreateActivityDialog> createState() => _CreateActivityDialogState();
}

class _CreateActivityDialogState extends State<CreateActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = '社交';
  int _maxParticipants = 5;
  late LatLng _selectedLocation;
  String _locationAddress = '載入地址中...';
  bool _isLoadingAddress = false;
  
  // 新增：時間相關欄位
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 3));

  final List<String> _categories = [
    '社交', '運動', '學習', '美食', '旅遊', '音樂', '藝術', '其他'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
    _getAddressFromLocation(_selectedLocation);
  }

  // 從經緯度取得地址
  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''}'.trim();
        
        if (address.isEmpty) {
          address = '${place.country ?? ''} ${place.administrativeArea ?? ''}'.trim();
        }
        
        if (address.isEmpty) {
          address = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }
        
        setState(() {
          _locationAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('取得地址失敗: $e');
      setState(() {
        _locationAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _isLoadingAddress = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 選擇開始時間 - 使用滾輪式選擇器
  Future<void> _selectStartTime() async {
    picker.DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 365)),
      currentTime: _startTime,
      locale: picker.LocaleType.zh,
      theme: const picker.DatePickerTheme(
        backgroundColor: Colors.white,
        itemStyle: TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        doneStyle: TextStyle(
          color: Color(0xFF00D0DD),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        cancelStyle: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        titleHeight: 50,
        containerHeight: 240,
      ),
      onConfirm: (date) {
        setState(() {
          _startTime = date;
          // 自動調整結束時間（開始時間 + 2 小時）
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 2));
          }
        });
      },
    );
  }

  // 選擇結束時間 - 使用滾輪式選擇器
  Future<void> _selectEndTime() async {
    picker.DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: _startTime,
      maxTime: DateTime.now().add(const Duration(days: 365)),
      currentTime: _endTime,
      locale: picker.LocaleType.zh,
      theme: const picker.DatePickerTheme(
        backgroundColor: Colors.white,
        itemStyle: TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        doneStyle: TextStyle(
          color: Color(0xFF00D0DD),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        cancelStyle: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        titleHeight: 50,
        containerHeight: 240,
      ),
      onConfirm: (date) {
        if (date.isAfter(_startTime)) {
          setState(() {
            _endTime = date;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('結束時間必須晚於開始時間'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  // 建立日期時間選擇器 UI
  Widget _buildDateTimeSelector({
    required IconData icon,
    required String label,
    required DateTime dateTime,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00D0DD), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<ActivityService>();
    
    // 檢查 Token 狀態
    final token = service.apiService.currentToken;
    print('\n========== 準備建立活動 ==========');
    print('Token 狀態: ${token != null && token.isNotEmpty ? "已設定 (${token.substring(0, 20)}...)" : "❌ 未設定"}');
    
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先到設定頁面輸入 Bearer Token'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D0DD)),
      ),
    );

    // 從完整地址中提取地區（取前面的部分作為 region）
    String region = _locationAddress;
    String address = _locationAddress;
    
    // 嘗試從地址中提取地區（例如：台北市、新北市等）
    final regionMatch = RegExp(r'([\u4e00-\u9fa5]+[市縣])').firstMatch(_locationAddress);
    if (regionMatch != null) {
      region = regionMatch.group(1) ?? _locationAddress;
    }
    
    print('地區: $region');
    print('地址: $address');

    final activity = await service.createActivity(
      title: _titleController.text,
      description: _descriptionController.text,
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      maxParticipants: _maxParticipants,
      activityType: _selectedCategory,
      region: region,
      address: address,
      startTime: _startTime,      // 新增
      endTime: _endTime,          // 新增
    );

    if (mounted) {
      Navigator.pop(context); // 關閉載入對話框
      
      if (activity != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 活動建立成功！'),
            backgroundColor: Color(0xFF00D0DD),
          ),
        );
        
        widget.onActivityCreated();
        Navigator.pop(context); // 關閉建立對話框
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('建立活動失敗，請稍後再試'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 標題列
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48), // 左側佔位
                const Expanded(
                  child: Text(
                    '建立新活動',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 表單內容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 活動標題
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: '活動標題',
                        hintText: '例如：咖啡廳讀書會',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入活動標題';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // 活動類別
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: '活動類別',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),

                    const SizedBox(height: 20),

                    // 活動說明
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: '活動說明',
                        hintText: '描述活動內容、注意事項等...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '請輸入活動說明';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // 人數上限
                    Text(
                      '人數上限：$_maxParticipants 人',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Slider(
                      value: _maxParticipants.toDouble(),
                      min: 2,
                      max: 20,
                      divisions: 18,
                      activeColor: const Color(0xFF00D0DD),
                      label: '$_maxParticipants 人',
                      onChanged: (value) {
                        setState(() => _maxParticipants = value.toInt());
                      },
                    ),

                    const SizedBox(height: 20),

                    // 開始時間
                    _buildDateTimeSelector(
                      icon: Icons.access_time,
                      label: '開始時間',
                      dateTime: _startTime,
                      onTap: () => _selectStartTime(),
                    ),

                    const SizedBox(height: 12),

                    // 結束時間
                    _buildDateTimeSelector(
                      icon: Icons.event_available,
                      label: '結束時間',
                      dateTime: _endTime,
                      onTap: () => _selectEndTime(),
                    ),

                    const SizedBox(height: 20),

                    // 活動地點
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Color(0xFF00D0DD)),
                      title: const Text(
                        '活動地點',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: _isLoadingAddress
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00D0DD),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('載入地址中...'),
                              ],
                            )
                          : Text(
                              _locationAddress,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPickerDialog(
                              initialPosition: _selectedLocation,
                            ),
                          ),
                        );
                        
                        if (result != null) {
                          setState(() {
                            _selectedLocation = result;
                          });
                          // 更新地址
                          await _getAddressFromLocation(result);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 建立按鈕
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _createActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D0DD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '建立活動',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
