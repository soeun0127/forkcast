import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import 'home.dart';
import 'profile.dart';
import 'community_dir/community.dart';
import 'get_access_token.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPage();
}

class _CalendarPage extends State<CalendarPage> {
  int _selectedIndex = 2;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isFirstLoad = true;

  Map<String, dynamic>? _healthData;
  bool _loading = true;

  double _totalSodium = 0;
  double _totalSugar = 0;
  double _totalProtein = 0;

  double limitProtein = 0;
  double limitSugar = 0;
  double limitSodium = 0;

  String _warningMessage = '';

  Map<String, dynamic> _logs = {};
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    fetchMealsForDay(_selectedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _isFirstLoad = false;
    });
    fetchMealsForDay(selectedDay);
  }

  Future<void> calculateTotal() async {
    _totalProtein = 0;
    _totalSodium = 0;
    _totalSugar = 0;

    for (var type in ['breakfast', 'lunch', 'dinner']) {
      final meal = _logs[type];

      if(meal != null) {
        final nutrition = meal['nutritionTotal'];
        _totalProtein += (nutrition['protein'] ?? 0).toDouble();
        _totalSugar += (nutrition['sugar'] ?? 0).toDouble();
        _totalSodium += (nutrition['sodium'] ?? 0).toDouble();
      }
    }

    await checkNutrientWarnings();
  }

  Future<void> checkNutrientWarnings() async {
    List<String> warning = [];

    await fetchHealthData();

    if(_totalProtein > limitProtein) {
      warning.add("⚠️Protein intake exceeded!");
    }
    else if(_totalSugar > limitSugar) {
      warning.add("⚠️Sugar intake exceeded!");
    }
    else if(_totalSodium > limitSodium) {
      warning.add("⚠️Sodium intake exceeded!");
    }

    setState(() {
      _warningMessage = warning.join('\n');
    });
  }

  Future<void> fetchHealthData() async {
    final url = Uri.parse('https://forkcast.onrender.com/user/health');
    final token = await getAccessToken();

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          setState(() {
            _healthData = decoded[0]; // 첫 번째 객체만 사용
            _loading = false;
          });

          limitProtein = _healthData?['proteinLimit'];
          limitSugar = _healthData?['sugarLimit'];
          limitSodium = _healthData?['sodiumLimit'];

        } else {
          print("데이터 없음");
          setState(() => _loading = false);
        }
      } else {
        print("불러오기 실패: ${response.statusCode} ${response.body}");
        setState(() => _loading = false);
      }
    } catch (e) {
      print("예외 발생: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> fetchMealsForDay(DateTime day) async {
    try {
      final token = await getAccessToken();
      final formattedDate = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse('https://forkcast.onrender.com/diet/logs?date=$formattedDate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final decoded = jsonDecode(response.body);
        const encoder = JsonEncoder.withIndent('  ');
        print("PRETTY MAP STRUCTURE:\n${encoder.convert(decoded)}");

        setState(() {
          _logs = data['logs'] ?? {};
        });

        await calculateTotal();

      } else {
        print("Failed to fetch meals: ${response.statusCode}");
        setState(() => _logs = {});
      }
    } catch (e) {
      print("Error fetching meals: $e");
      setState(() => _logs = {});
    }
  }

  Widget _buildMealSection(String mealType, Map<String, dynamic> data) {
    final nutrition = data['nutritionTotal'];
    final foods = data['foodInfos'] as List;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mealType.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNutrientText('Calories', '${nutrition['energy']} kcal'),
                _buildNutrientText('Protein', '${nutrition['protein']} g'),
                _buildNutrientText('Sugar', '${nutrition['sugar']} g'),
                _buildNutrientText('Sodium', '${nutrition['sodium']} mg'),
              ],
            ),
            const Divider(height: 20),
            ...foods.where((item) {
              final name = item['name'];
              return name != null && name.toString().trim().isNotEmpty;
            }).map((item) {
              final List<String> parts = [];

              // 모든 값이 0이어도 다 출력
              parts.add("Calories: ${item['energy'] ?? 0} kcal\n");
              parts.add("- Protein: ${item['protein'] ?? 0} g\n");
              parts.add("- Sugar: ${item['sugar'] ?? 0} g\n");
              parts.add("- Sodium: ${item['sodium'] ?? 0} mg\n");

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("  - ${parts.join("  ")}"),
                  const SizedBox(height: 8),
                ],
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientText(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text("Check your health report", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const Text('MONTH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => !_isFirstLoad && isSameDay(day, _selectedDay),
              onDaySelected: _onDaySelected,
              calendarFormat: CalendarFormat.month,
              headerVisible: false,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.teal),
                weekendStyle: TextStyle(color: Colors.teal),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Color(0xFF1AB098), shape: BoxShape.circle),
                outsideDaysVisible: false,
              ),
              availableGestures: AvailableGestures.horizontalSwipe,
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_warningMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_warningMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                const SizedBox(height: 8),
                const Text('Analyze Today\'s Meals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_logs.isEmpty)
                  const Text('No meals found for this day.')
                else
                  ...['breakfast', 'lunch', 'dinner'].map((type) {
                    final meal = _logs[type];
                    return meal == null ? const SizedBox() : _buildMealSection(type, meal);
                  }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1AB098),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
          }
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
