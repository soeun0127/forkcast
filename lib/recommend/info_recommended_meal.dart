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
  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner'];

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> submitMealRecord() async {
    if (_selectedMealType == null || _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the ingredients you want")),
      );
      return;
    }

    _showLoadingDialog();

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
      print("🔹 [USER DATA] 백엔드에서 받아온 사용자 데이터:");
      print(const JsonEncoder.withIndent('  ').convert(decoded));

      if (decoded is! List || decoded.isEmpty) {
        throw Exception('빈 리스트 또는 잘못된 데이터 형식입니다.');
      }

      final Map<String, dynamic> first = decoded[0];
      final int age = _calculateAge(first['user']['birthdate']);
      final String gender = first['user']['gender'] ?? 'unknown';
      final int height = first['user']['height'];
      final int weight = first['user']['weight'];
      final int? protein = first['proteinLimit'];
      final int? sugar = first['sugarLimit'];
      final int? sodium = first['sodiumLimit'];

      final String? diseases = first['disease']?['name'];
      if(diseases == null){
        throw Exception("질병 이름이 없음");
      }

      print("$age, $gender, $height, $weight, $diseases");

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
          "ingredients": ingredients,
          "disease": diseases, //diseases
        },
        "meal_type": _selectedMealType,
        "consumed_so_far": {
          "protein": 20,
          "fat": 5,
          "carbs": 30,
          "sodium": 40,
        }
      };

      print("🟢 [REQUEST BODY] AI 서버에 전송할 데이터:");
      print(const JsonEncoder.withIndent('  ').convert(requestBody));

      final aiResponse = await http.post(
        Uri.parse('http://34.82.141.225:8000/generate-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (context.mounted) Navigator.of(context).pop();

      if (aiResponse.statusCode == 200) {
        final aiData = jsonDecode(aiResponse.body);

        print("🟣 [AI RESPONSE] AI 서버에서 받은 추천 식단:");
        print(const JsonEncoder.withIndent('  ').convert(aiData));

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
      if (context.mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("에러: $e")),
      );
      print("에러 $e");
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
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Recommended Meal",
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
            const Text("Please enter the desired ingredients, separated by commas", style: TextStyle(fontSize: 16)),
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
                  await submitMealRecord();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Get Suggestion",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
