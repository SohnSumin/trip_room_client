import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChecklistCard extends StatefulWidget {
  final String roomId;

  const ChecklistCard({super.key, required this.roomId});

  @override
  State<ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<ChecklistCard> {
  List<Map<String, dynamic>> _checklist = [];
  final TextEditingController _checklistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  @override
  void dispose() {
    _checklistController.dispose();
    super.dispose();
  }

  // SharedPreferences에서 체크리스트 불러오기
  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? checklistJson = prefs.getString('checklist_${widget.roomId}');
    if (checklistJson != null) {
      setState(() {
        _checklist = List<Map<String, dynamic>>.from(
          json.decode(checklistJson),
        );
      });
    } else {
      setState(() {
        _checklist = []; // 저장된 데이터가 없으면 빈 리스트로 초기화
      });
    }
  }

  // SharedPreferences에 체크리스트 저장하기
  Future<void> _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'checklist_${widget.roomId}',
      json.encode(_checklist),
    );
  }

  // 체크리스트 아이템 추가
  void _addChecklistItem(String item) {
    if (item.isNotEmpty) {
      setState(() {
        _checklist.add({'text': item, 'checked': false});
      });
      _checklistController.clear();
      _saveChecklist();
    }
  }

  // 체크리스트 아이템 상태 변경
  void _toggleChecklistItem(int index) {
    setState(() {
      _checklist[index]['checked'] = !_checklist[index]['checked'];
    });
    _saveChecklist();
  }

  // 체크리스트 아이템 삭제
  void _deleteChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
    });
    _saveChecklist();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF6000), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHECKLIST',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6000),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _checklistController,
              decoration: InputDecoration(
                hintText: '준비물 추가 (예: 여권, 충전기)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addChecklistItem(_checklistController.text),
                ),
              ),
              onSubmitted: _addChecklistItem,
            ),
            const SizedBox(height: 10),
            if (_checklist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '챙겨야 할 준비물을 추가해보세요!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklist.length,
                itemBuilder: (context, index) {
                  final item = _checklist[index];
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      item['text'],
                      style: TextStyle(
                        decoration: item['checked']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item['checked'] ? Colors.grey : Colors.black,
                      ),
                    ),
                    value: item['checked'],
                    onChanged: (bool? value) => _toggleChecklistItem(index),
                    secondary: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () => _deleteChecklistItem(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
