import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  runApp(MaterialApp(home: DiaryPage()));
}

class DiaryPage extends StatefulWidget {
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final List<DiaryEntry> _entries = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late SharedPreferences _prefs;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _controller = TextEditingController();
  Color _selectedColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadEntries();
  }

  void _loadEntries() async {
    _prefs = await SharedPreferences.getInstance();
    final data = _prefs.getString('diary_entries');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < decoded.length; i++) {
          final entry = DiaryEntry.fromJson(decoded[i]);
          _entries.add(entry);
          _listKey.currentState?.insertItem(i);
        }
      });
    }
  }

  void _saveEntries() async {
    await _prefs.setString('diary_entries', jsonEncode(_entries));
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _addOrEditEntry({DiaryEntry? oldEntry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        if (oldEntry != null) {
          _controller.text = oldEntry.content;
          _selectedColor = oldEntry.color;
        } else {
          _controller.clear();
          _selectedColor = Colors.deepPurple;
        }

        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(oldEntry != null ? 'Chỉnh sửa' : 'Ghi nhật ký',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Nhập nội dung hoặc nhấn mic...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.color_lens, color: _selectedColor),
                      SizedBox(width: 16),
                      DropdownButton<Color>(
                        value: _selectedColor,
                        onChanged: (color) {
                          if (color != null) {
                            setModalState(() => _selectedColor = color);
                          }
                        },
                        underline: SizedBox(),
                        selectedItemBuilder: (context) => [
                          Colors.deepPurple,
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.red,
                        ].map((color) {
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedColor,
                              border: Border.all(color: Colors.grey),
                            ),
                          );
                        }).toList(),
                        items: [
                          Colors.deepPurple,
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.red,
                        ].map((color) {
                          return DropdownMenuItem<Color>(
                            value: color,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                        label: Text(_isListening ? 'Đang ghi...' : 'Ghi âm', style: TextStyle(color: Colors.white)),
                        onPressed: _isListening ? _stopListening : _startListening,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final content = _controller.text.trim();
                          if (content.isEmpty) return;

                          if (oldEntry != null) {
                            final index = _entries.indexOf(oldEntry);
                            setState(() {
                              _entries[index] = DiaryEntry(
                                content: content,
                                dateTime: oldEntry.dateTime,
                                color: _selectedColor,
                              );
                            });
                          } else {
                            final newEntry = DiaryEntry(
                              content: content,
                              dateTime: DateTime.now(),
                              color: _selectedColor,
                            );
                            _entries.insert(0, newEntry);
                            _listKey.currentState?.insertItem(0);
                          }

                          _saveEntries();
                          Navigator.pop(context);
                        },
                        child: Text('Lưu', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteEntry(int index) {
    final removed = _entries.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
          (context, animation) => _buildAnimatedItem(removed, index, animation),
    );
    _saveEntries();
  }

  Widget _buildAnimatedItem(DiaryEntry entry, int index, Animation<double> animation) {
    final formattedDate = DateFormat.yMMMMEEEEd('vi_VN').add_Hm().format(entry.dateTime);
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        onTap: () => _addOrEditEntry(oldEntry: entry),
        leading: CircleAvatar(backgroundColor: entry.color),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 4),
            Text(entry.content),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.deepPurple),
          onPressed: () => _deleteEntry(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nhật ký cá nhân')),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _entries.length,
        itemBuilder: (context, index, animation) {
          return _buildAnimatedItem(_entries[index], index, animation);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditEntry(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class DiaryEntry {
  final String content;
  final DateTime dateTime;
  final Color color;

  DiaryEntry({required this.content, required this.dateTime, required this.color});

  Map<String, dynamic> toJson() => {
    'content': content,
    'dateTime': dateTime.toIso8601String(),
    'color': color.value,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    content: json['content'],
    dateTime: DateTime.parse(json['dateTime']),
    color: Color(json['color']),
  );
}
