import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community_dir/community.dart';
import 'get_access_token.dart';
import 'home.dart';
import 'calendar.dart';
import 'onboarding.dart';
import 'user_info/check_information.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;
  Map<String, dynamic>? _healthData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchHealthData();
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingPage()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.teal,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  'name : ${_healthData?["user"]["name"]}', //$name
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'email : ${_healthData?["user"]["email"]}', //$email
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildProfileTile(Icons.favorite_border, 'Check Information'),
                _buildProfileTile(
                    Icons.calendar_month, 'Analyze Meal'),
                _buildProfileTile(Icons.forum, 'User Community'),
                _buildProfileTile(Icons.logout, 'log out'),
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
            // 화면 전환 코드 추가
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            } else if (index == 1) {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityPage()),
              );
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

  Widget _buildProfileTile(IconData icon, String title) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(icon, color: Colors.teal, size: 20),
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      visualDensity: const VisualDensity(vertical: 0),
      // 밀도 균일화
      onTap: () {
        if(title == 'Check Information') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CheckUserInfoPage()));
        }
        else if(title == 'User Community') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityPage()));
        }
        else if(title == 'Analyze Meal') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarPage()));
        }
        else if(title == 'log out') {
          logout();
        }
      },
    );
  }
}