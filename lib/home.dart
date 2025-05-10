import 'package:flutter/material.dart';
import 'edit_health_data.dart';
import 'calendar.dart';
import 'profile.dart';
import 'camera.dart';
import 'today_meal_record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int weekOffset = 0;
  int _selectedIndex = 0;
  DateTime today = DateTime.now();

  List<DateTime> getCurrentWeekDates() {
    int weekday = today.weekday;
    DateTime start = today.subtract(Duration(days: weekday - 1)).add(Duration(days: 7 * weekOffset));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getCurrentWeekDates();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Align(
          alignment: Alignment.centerLeft, // 텍스트를 왼쪽으로 정렬
          child: const Text(
            "Have a healthy meal",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Week Calendar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: weekDates.map((date) {
                  bool isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4), // 날짜 사이 간격
                      height: 80, // 정사각형 또는 비슷한 크기
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFF1AB098) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${date.day}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][date.weekday - 1],
                            style: TextStyle(
                              fontSize: 14,
                              color: isToday ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            /// Button List
            _buildMenuItem(Icons.thumb_up, "Recommended Meals", () {

            }),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.fact_check, "Weekly Meal Evaluation", () {}),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.people, "User Community", () {}),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.flag, "Today's Meal Record", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TodayMealRecordPage()));
            }),
            const SizedBox(height: 12),
            _buildMenuItem(
              Icons.info,
              "Edit Health Information",
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditUserHealthPage()),
                );
              },
            ),

            const SizedBox(height: 36),

            /// Scan Your Meal Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Scan Your Meal",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await initCameraModule(); // 반드시 먼저 호출
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CameraApp()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1AB098),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text("Take Food Photo"),
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1AB098),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text("Scan Barcode"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1AB098),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // 화면 전환 코드 추가
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            } else if (index == 1) {
             /* Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MailPage()),//MailPage())
              );*/
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarPage()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}

Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    leading: Icon(icon, color: const Color(0xFF1AB098)),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );
}
