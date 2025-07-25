import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  final List<ScheduleEvent> _events = [];
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _initNotifications();
  }

  void _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notificationsPlugin.initialize(settings);
    tz.initializeTimeZones();
  }

  void _scheduleNotification(ScheduleEvent event) async {
    await _notificationsPlugin.zonedSchedule(
      event.hashCode,
      'Nhắc nhở: ${event.title}',
      'Lúc ${event.time.hour}:${event.time.minute.toString().padLeft(2, '0')}',
      tz.TZDateTime.from(event.time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Nhắc nhở',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  void _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('events');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      setState(() {
        _events.clear();
        _events.addAll(decoded.map((e) => ScheduleEvent.fromJson(e)));
      });
    }
  }

  void _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('events', jsonEncode(_events));
  }

  void _addEventDialog() {
    final controller = TextEditingController();
    TimeOfDay? startTime;
    Color selectedColor = Colors.deepPurple;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm nhắc nhở'),
        content: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: InputDecoration(labelText: 'Nội dung')),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (picked != null) setModalState(() => startTime = picked);
                },
                child: Text(startTime != null
                    ? 'Giờ: ${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}'
                    : 'Chọn giờ nhắc'),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.color_lens, color: selectedColor),
                  SizedBox(width: 16),
                  DropdownButton<Color>(
                    value: selectedColor,
                    onChanged: (color) {
                      if (color != null) setModalState(() => selectedColor = color);
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
                          color: selectedColor,
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
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Huỷ')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty || startTime == null) return;
              final start = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                startTime!.hour,
                startTime!.minute,
              );
              final event = ScheduleEvent(
                date: _selectedDate,
                time: start,
                title: controller.text.trim(),
                color: selectedColor,
              );
              setState(() {
                _events.add(event);
              });
              _scheduleNotification(event);
              _saveEvents();
              Navigator.pop(context);
            },
            child: Text('Thêm'),
          )
        ],
      ),
    );
  }


  List<ScheduleEvent> get _eventsForSelectedDate {
    final events = _events.where((e) => isSameDay(e.date, _selectedDate)).toList();
    events.sort((a, b) => a.time.compareTo(b.time));
    return events;
  }

  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return Scaffold(
      appBar: AppBar(title: Text('Lịch nhắc nhở')),
      body: Column(
        children: [
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = startOfWeek.add(Duration(days: index));
                final isSelected = isSameDay(day, _selectedDate);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: Container(
                    width: 60,
                    margin: EdgeInsets.all(4),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('T${day.weekday}', style: TextStyle(color: isSelected ? Colors.white : Colors.deepPurple)),
                        SizedBox(height: 4),
                        Text('${day.day}', style: TextStyle(color: isSelected ? Colors.white : Colors.deepPurple)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _eventsForSelectedDate.length,
              itemBuilder: (context, index) {
                final event = _eventsForSelectedDate[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: event.color),
                  title: Text(event.title),
                  subtitle: Text('${event.time.hour}:${event.time.minute.toString().padLeft(2, '0')}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _events.remove(event));
                      _saveEvents();
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEventDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

class ScheduleEvent {
  final DateTime date;
  final DateTime time;
  final String title;
  final Color color;

  ScheduleEvent({required this.date, required this.time, required this.title, required this.color});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'time': time.toIso8601String(),
    'title': title,
    'color': color.value,
  };

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) => ScheduleEvent(
    date: DateTime.parse(json['date']),
    time: DateTime.parse(json['time']),
    title: json['title'],
    color: Color(json['color']),
  );
}