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

  Map<String, dynamic> _logs = {};
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    fetchMealsForDay(_selectedDay);
    fetchRecommendations();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _isFirstLoad = false;
    });
    fetchMealsForDay(selectedDay);
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
        setState(() {
          _logs = data['logs'] ?? {};
        });
      } else {
        print("Failed to fetch meals: ${response.statusCode}");
        setState(() => _logs = {});
      }
    } catch (e) {
      print("Error fetching meals: $e");
      setState(() => _logs = {});
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse('https://forkcast.onrender.com/recommendations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recommendations = List<String>.from(data['messages']);
        });
      } else {
        print("Failed to fetch recommendations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
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
              final energy = item['energy'] ?? 0;
              final protein = item['protein'] ?? 0;
              final sugar = item['sugar'] ?? 0;
              final sodium = item['sodium'] ?? 0;

              // ❌ 이름이 없거나 모든 영양소 값이 0이면 제외
              final isEmptyName = name == null || name.toString().trim().isEmpty;
              final allZero = energy == 0 && protein == 0 && sugar == 0 && sodium == 0;

              return !isEmptyName && !allZero;
            }).map((item) {
              final List<String> parts = [];

              if ((item['energy'] ?? 0) > 0) parts.add("Calories: ${item['energy']} kcal\n");
              if ((item['protein'] ?? 0) > 0) parts.add("- Protein: ${item['protein']} g\n");
              if ((item['sugar'] ?? 0) > 0) parts.add("- Sugar: ${item['sugar']} g\n");
              if ((item['sodium'] ?? 0) > 0) parts.add("- Sodium: ${item['sodium']} mg\n");

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
                //const Text('Weekly Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                //const SizedBox(height: 8),
                //if (_recommendations.isEmpty)
                //  const Text("No recommendations found.")
                /*else
                  Card(
                    color: const Color(0xFFF9F9F9),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _recommendations.map((text) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontSize: 16)),
                              Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),*/
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
