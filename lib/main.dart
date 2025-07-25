import 'package:demo_app/HomePage.dart';
import 'package:demo_app/chatbot_page.dart';
import 'package:demo_app/calendar_page.dart';
import 'package:demo_app/DiaryPage.dart';
import 'package:demo_app/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Bắt buộc khi dùng async
  await initializeDateFormatting('vi_VN', null); // Khởi tạo dữ liệu locale tiếng Việt
  runApp(SeniorsApp());
}

class SeniorsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seniors Health App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomePage(),
    ChatBotPage(),
    CalendarPage(),
    DiaryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
    );
  }
}
