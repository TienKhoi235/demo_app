import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';
import 'chatbot_page.dart';
import 'calendar_page.dart';
import 'DiaryPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = true;
  int currentBPM = 82;
  List<FlSpot> bpmData = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if (isConnected) startGeneratingData();
  }

  void startGeneratingData() {
    timer = Timer.periodic(Duration(seconds: 2), (_) {
      final now = DateTime.now();
      final bpm = 70 + Random().nextInt(30); // Simulated heart rate 70-100
      setState(() {
        currentBPM = bpm;
        bpmData.add(FlSpot(now.second.toDouble(), bpm.toDouble()));
        if (bpmData.length > 20) bpmData.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget buildChart() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: bpmData.asMap().entries.map((entry) {
              // mỗi điểm cách nhau 2s, vì Timer là mỗi 2s
              return FlSpot(entry.key * 2.0, entry.value.y);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.transparent, // nền trong suốt
                  strokeWidth: 2,
                  strokeColor: Colors.red,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}s', style: TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: true),
        minY: 50,
        maxY: 120,
        minX: 0,
        maxX: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 24),
            Container(
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 6)
                ],
              ),
              child: isConnected
                  ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Theo dõi nhịp tim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Đã kết nối", style: TextStyle(color: Colors.green)),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.monitor_heart, size: 30, color: Colors.red),
                        SizedBox(height: 6),
                        Text('$currentBPM', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.red)),
                        Text("BPM", style: TextStyle(letterSpacing: 1)),
                        SizedBox(height: 4),
                        Text("Nhịp tim bình thường")
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isConnected = false;
                        timer?.cancel();
                        bpmData.clear();
                      });
                    },
                    child: Text("Ngắt kết nối"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
                  : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Theo dõi nhịp tim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Chưa kết nối", style: TextStyle(color: Colors.grey.shade800)),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isConnected = true;
                        startGeneratingData();
                      });
                    },
                    child: Text("Kết nối thiết bị"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Biểu đồ nhịp tim", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text("Biểu đồ nhịp tim theo thời gian"),
                  SizedBox(height: 12),
                  isConnected
                      ? SizedBox(height: 200, child: buildChart())
                      : Center(child: Text("Chưa có dữ liệu - hãy kết nối thiết bị")),
                ],
              ),
            ),

            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  featureCard(Icons.chat_bubble_outline, "Trò chuyện", "Trò chuyện bằng giọng nói với người thân", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatBotPage()));
                  }, color: Colors.blue.shade50, iconColor: Colors.blue),
                  featureCard(Icons.calendar_today, "Lịch nhắc", "Thêm và quản lý các lời nhắc hằng ngày", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarPage()));
                  }, color: Colors.green.shade50, iconColor: Colors.green),
                  featureCard(Icons.book, "Nhật ký", "Ghi lại những kỷ niệm bằng giọng nói", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryPage()));
                  }, color: Colors.purple.shade50, iconColor: Colors.purple),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget featureCard(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color, Color? iconColor}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              SizedBox(height: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
