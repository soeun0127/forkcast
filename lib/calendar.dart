import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/community_dir/community.dart';
import 'package:solution_challenge/get_access_token.dart';
import 'package:table_calendar/table_calendar.dart';

import 'home.dart';
import 'profile.dart';

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

  List<dynamic> _meals = [];

  @override
  void initState() {
    super.initState();
    fetchMealsForDay(_selectedDay); // load today's meals on startup
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _isFirstLoad = false; // 이후부터는 연한 색 강조
    });
    fetchMealsForDay(selectedDay);
  }

  Future<void> fetchMealsForDay(DateTime day) async {
    try {
      final token = await getAccessToken();
      final formattedDate =
          "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse('https://your-api.com/meals?date=$formattedDate'), //실제 api로 바꾸기
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _meals = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _meals = [];
        });
        print("Failed to fetch meals: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _meals = [];
      });
      print("Error fetching meals: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Check your meal",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Text(
            'MONTH',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return !_isFirstLoad && isSameDay(day, _selectedDay);
              },
              onDaySelected: _onDaySelected,
              calendarFormat: CalendarFormat.month,
              headerVisible: false,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.teal),
                weekendStyle: TextStyle(color: Colors.teal),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF1AB098),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              availableGestures: AvailableGestures.horizontalSwipe,
              startingDayOfWeek: StartingDayOfWeek.monday,
            ),
          ),
          _meals.isEmpty
              ? const Text('No meals found for this day.')
              : Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return ListTile(
                  title: Text(meal['foodName']),
                  subtitle: Text("${meal['calories']} kcal"),
                );
              },
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
