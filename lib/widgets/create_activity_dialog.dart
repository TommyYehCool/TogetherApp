import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';

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
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  final List<String> _categories = [
    '社交', '運動', '學習', '美食', '旅遊', '音樂', '藝術', '其他'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<ActivityService>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D0DD)),
      ),
    );

    final activity = await service.createActivity(
      title: _titleController.text,
      description: _descriptionController.text,
      latitude: widget.initialPosition.latitude,
      longitude: widget.initialPosition.longitude,
      startTime: _selectedDateTime,
      maxParticipants: _maxParticipants,
      category: _selectedCategory,
    );

    if (mounted) {
      Navigator.pop(context); // 關閉載入對話框
      
      if (activity != null) {
        widget.onActivityCreated();
        Navigator.pop(context); // 關閉建立對話框
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('活動建立成功！'),
            backgroundColor: Color(0xFF00D0DD),
          ),
        );
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
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
                const SizedBox(width: 48),
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Color(0xFF00D0DD)),
                      title: const Text('開始時間'),
                      subtitle: Text(
                        '${_selectedDateTime.month}/${_selectedDateTime.day} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        
                        if (date != null && mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                          );
                          
                          if (time != null) {
                            setState(() {
                              _selectedDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
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
