import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/get_access_token.dart';
import 'package:solution_challenge/recommend/recommended_meal.dart';

class InfoRecommendedMealPage extends StatefulWidget {
  const InfoRecommendedMealPage({super.key});

  @override
  State<InfoRecommendedMealPage> createState() => _InfoRecommendedMealPageState();
}

class _InfoRecommendedMealPageState extends State<InfoRecommendedMealPage> {
  final Color primaryColor = const Color(0xFF20A090);
  final Color secondColor = const Color(0xFFEAF4F0);
  final TextEditingController _notesController = TextEditingController();
  String? _selectedMealType;
  final List<String> _mealTypes = ['breakfast', 'launch', 'dinner'];

  /*Future<List<Map<String, dynamic>>> fetchUserInfo() async {
    final token = await getAccessToken();

    final response = await http.get(
      Uri.parse('https://forkcast.onrender.com/user/health'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      print('🔵 받은 사용자 데이터: $decoded');

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.cast<Map<String, dynamic>>();
      } else {
        throw Exception('빈 리스트 또는 잘못된 데이터 형식입니다.');
      }
    } else {
      throw Exception('사용자 정보 가져오기 실패: ${response.statusCode}');
    }
  }
   */

  Future<void> submitMealRecord() async {
    if (_selectedMealType == null || _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the ingredients you want")),
      );
      return;
    }

    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse('https://forkcast.onrender.com/user/health'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('사용자 정보 가져오기 실패: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      print('🔵 받은 사용자 데이터: $decoded');

      if (decoded is! List || decoded.isEmpty) {
        throw Exception('빈 리스트 또는 잘못된 데이터 형식입니다.');
      }

      final Map<String, dynamic> first = decoded[0];
      final int age = 20; //_calculateAge(first['birthDate'])
      final String gender = "female"; //first['gender'] ?? 'unknown'
      final int height = 170; //first['height']
      final int weight = 60; //first['weight']

      final List<String> diseases = decoded
          .map<String>((item) => item['disease']['name'].toString())
          .toList();

      final List<String> ingredients = _notesController.text.trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final Map<String, dynamic> requestBody = {
        "user_info": {
          "age": age,
          "gender": gender,
          "height": height,
          "weight": weight,
          "allergy": "gluten",
          "disease": diseases,
          "ingredients": ingredients,
        },
        "meal_type": _selectedMealType,
        "consumed_so_far": {},
      };

      print("📤 전송 데이터: ${jsonEncode(requestBody)}");

      final aiResponse = await http.post(
        Uri.parse('http://34.64.249.244:7860/generate_diet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (aiResponse.statusCode == 200) {
        final aiData = jsonDecode(aiResponse.body);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecommendedMeal(data: aiData),
            ),
          );
        }
      } else {
        throw Exception('AI 오류: ${aiResponse.statusCode}');
      }
    } catch (e) {
      print("❌ 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("에러: $e")),
      );
    }
  }

  int _calculateAge(String birthdate) {
    final birth = DateTime.parse(birthdate);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Align(
          alignment: Alignment.centerLeft, // 텍스트를 왼쪽으로 정렬
          child: const Text(
            "Today's meal record",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Meal Type", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _mealTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _selectedMealType == type,
                  showCheckmark: false,
                  selectedColor: primaryColor.withOpacity(0.3),
                  onSelected: (selected) {
                    setState(() {
                      _selectedMealType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text("Record your meal", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What did you have?",
                filled: true,
                fillColor: secondColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await submitMealRecord();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류 발생: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("record", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
