import 'package:flutter/material.dart';

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  String? selectedAI; // Null nếu chưa chọn người nào

  final Map<String, List<Map<String, String>>> chatHistories = {};

  final List<Map<String, String>> aiProfiles = [
    {'id': 'normal', 'name': 'Trợ lý AI', 'avatar': '🤖'},
    {'id': 'grandson', 'name': 'Cháu Nam', 'avatar': '🧒'},
    {'id': 'daughter', 'name': 'Con Mai', 'avatar': '👩'},
    {'id': 'friend', 'name': 'Bạn Hòa', 'avatar': '🧓'},
  ];

  void _addNewProfile() async {
    String? newName;
    String? newEmoji;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Thêm người trò chuyện mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Tên hoặc biệt danh"),
                onChanged: (value) => newName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Biểu tượng emoji (ví dụ: 👨‍🦳)"),
                onChanged: (value) => newEmoji = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (newName != null && newEmoji != null && newName!.isNotEmpty && newEmoji!.isNotEmpty) {
                  final newId = DateTime.now().millisecondsSinceEpoch.toString();
                  setState(() {
                    aiProfiles.add({
                      'id': newId,
                      'name': newName!,
                      'avatar': newEmoji!,
                    });
                    chatHistories[newId] = [];
                    selectedAI = newId;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text("Thêm"),
            ),
          ],
        );
      },
    );
  }

  final TextEditingController _messageController = TextEditingController();

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      chatHistories.putIfAbsent(selectedAI!, () => []);
      chatHistories[selectedAI!]!.add({'from': 'user', 'text': text.trim()});
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedChatHistory = selectedAI == null ? [] : (chatHistories[selectedAI] ?? []);
    final selectedProfile = selectedAI != null
        ? aiProfiles.firstWhere((e) => e['id'] == selectedAI)
        : null;

    return Scaffold(
      backgroundColor: Color(0xFFEFF3FE),
      appBar: AppBar(
        backgroundColor: Color(0xFFEFF3FE),
        elevation: 0,
        leading: selectedAI != null
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              selectedAI = null;
            });
          },
        )
            : IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: selectedAI != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(selectedProfile!['avatar']!, style: TextStyle(fontSize: 18)),
            ),
            SizedBox(width: 8),
            Text(
              selectedProfile['name']!,
              style: TextStyle(color: Colors.black),
            ),
          ],
        )
            : Text(
          'Chọn người để trò chuyện',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: selectedAI == null
          ? ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: aiProfiles.length + 1,
        itemBuilder: (context, index) {
          if (index == aiProfiles.length) {
            return ListTile(
              leading: CircleAvatar(child: Icon(Icons.add, color: Colors.blue)),
              title: Text("Thêm người mới"),
              onTap: _addNewProfile,
            );
          }
          final ai = aiProfiles[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(ai['avatar']!, style: TextStyle(fontSize: 20)),
            ),
            title: Text(ai['name']!),
            onTap: () {
              setState(() {
                selectedAI = ai['id'];
                chatHistories.putIfAbsent(selectedAI!, () => []);
              });
            },
          );
        },
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: selectedChatHistory.length,
              itemBuilder: (context, index) {
                final message = selectedChatHistory[index];
                final isUser = message['from'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      chatHistories[selectedAI!]!.add({'from': 'user', 'text': 'Giả lập giọng nói...'});
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
