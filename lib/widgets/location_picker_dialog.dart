import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import '../config/env_config.dart';

class LocationPickerDialog extends StatefulWidget {
  final LatLng initialPosition;

  const LocationPickerDialog({
    super.key,
    required this.initialPosition,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText: json['structured_formatting']['main_text'] as String,
      secondaryText: json['structured_formatting']['secondary_text'] as String? ?? '',
    );
  }
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng _selectedPosition;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  String _currentAddress = '載入中...';
  bool _isLoadingAddress = false;
  List<PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  final Dio _dio = Dio();
  
  // 從環境變數取得 Google Maps API Key
  String get _apiKey => EnvConfig.googleMapsApiKey;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _getAddressFromLatLng(_selectedPosition);
    
    // 監聽搜尋輸入
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _getPlaceSuggestions(_searchController.text);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  // 從經緯度取得地址
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress = '${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''}'.trim();
          if (_currentAddress.isEmpty) {
            _currentAddress = '${place.country ?? ''} ${place.administrativeArea ?? ''}'.trim();
          }
          if (_currentAddress.isEmpty) {
            _currentAddress = '未知地址';
          }
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = '無法取得地址';
        _isLoadingAddress = false;
      });
    }
  }

  // 取得地點建議（Google Places Autocomplete API）
  Future<void> _getPlaceSuggestions(String input) async {
    if (input.isEmpty) return;

    // 檢查 API Key
    if (_apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      print('❌ 錯誤：API Key 尚未設定！');
      print('請到 lib/widgets/location_picker_dialog.dart 第 57 行設定你的 API Key');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('請先設定 Google Maps API Key'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print('\n========== 搜尋地址 ==========');
    print('搜尋關鍵字: $input');
    print('API Key: ${_apiKey.substring(0, 10)}...');

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      print('請求 URL: $url');
      
      final response = await _dio.get(
        url,
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'language': 'zh-TW',
          'components': 'country:tw', // 限制在台灣
          'location': '${_selectedPosition.latitude},${_selectedPosition.longitude}',
          'radius': 50000, // 50km 範圍內優先
        },
      );

      print('回應狀態: ${response.data['status']}');
      
      if (response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        print('找到 ${predictions.length} 個建議');
        
        setState(() {
          _suggestions = predictions
              .map((p) => PlaceSuggestion.fromJson(p))
              .toList();
          _showSuggestions = true;
        });
        
        print('✅ 建議列表已更新');
      } else if (response.data['status'] == 'REQUEST_DENIED') {
        print('❌ API 請求被拒絕');
        print('錯誤訊息: ${response.data['error_message']}');
        print('可能原因：');
        print('1. API Key 無效');
        print('2. Places API 未啟用');
        print('3. API Key 有使用限制');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API 請求被拒絕: ${response.data['error_message'] ?? '請檢查 API Key 設定'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (response.data['status'] == 'ZERO_RESULTS') {
        print('⚠️ 沒有找到結果');
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      } else {
        print('⚠️ 其他狀態: ${response.data['status']}');
        print('錯誤訊息: ${response.data['error_message']}');
      }
      
      print('========== 搜尋完成 ==========\n');
    } catch (e) {
      print('❌ 取得地點建議失敗: $e');
      if (e is DioException) {
        print('錯誤類型: ${e.type}');
        print('錯誤訊息: ${e.message}');
        if (e.response != null) {
          print('回應狀態碼: ${e.response?.statusCode}');
          print('回應資料: ${e.response?.data}');
        }
      }
      print('========== 搜尋失敗 ==========\n');
    }
  }

  // 從 Place ID 取得詳細資訊（經緯度）
  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'language': 'zh-TW',
          'fields': 'geometry,formatted_address',
        },
      );

      if (response.data['status'] == 'OK') {
        final location = response.data['result']['geometry']['location'];
        final address = response.data['result']['formatted_address'];
        
        final newPosition = LatLng(
          location['lat'] as double,
          location['lng'] as double,
        );
        
        setState(() {
          _selectedPosition = newPosition;
          _currentAddress = address;
          _showSuggestions = false;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPosition, 17),
        );
        
        // 關閉鍵盤
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('無法取得地點資訊'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇活動地點'),
        backgroundColor: const Color(0xFF00D0DD),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedPosition);
            },
            child: const Text(
              '確認',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 地圖（Uber 風格：拖曳地圖來選擇位置）
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 17,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              // 當地圖移動時，更新選擇的位置
              setState(() {
                _selectedPosition = position.target;
              });
            },
            onCameraIdle: () {
              // 當地圖停止移動時，取得地址
              _getAddressFromLatLng(_selectedPosition);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 中心標記（固定在畫面中央）
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 50,
                  color: const Color(0xFF00D0DD),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                const SizedBox(height: 50), // 補償圖標高度
              ],
            ),
          ),

          // 搜尋列和建議列表
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // 搜尋輸入框
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜尋地址...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00D0DD)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _showSuggestions = false;
                                  _suggestions = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                
                // 建議列表
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Color(0xFF00D0DD),
                          ),
                          title: Text(
                            suggestion.mainText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            suggestion.secondaryText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            _searchController.text = suggestion.description;
                            _getPlaceDetails(suggestion.placeId);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 地址資訊卡片
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF00D0DD),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '已選擇位置',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingAddress
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
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
                          _currentAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 提示文字（首次使用）
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D0DD).withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.pan_tool,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '拖曳地圖來選擇位置',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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
}
