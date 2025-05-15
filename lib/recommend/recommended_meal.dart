import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/get_access_token.dart';
import 'package:solution_challenge/home.dart';

class RecommendedMeal extends StatefulWidget {
  final Map<String, dynamic> data;

  const RecommendedMeal({super.key, required this.data});

  @override
  State<RecommendedMeal> createState() => _RecommendedMealState();
}

class _RecommendedMealState extends State<RecommendedMeal> {
  Map<String, dynamic>? _meal;
  bool _loading = false;

  final Color primaryColor = const Color(0xFF20A090);
  final Color secondColor = const Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _meal = _parseMeal(widget.data);
  }

  Map<String, dynamic>? _parseMeal(Map<String, dynamic> data) {
    if (data.containsKey('error') && data['raw'] != null) {
      final String raw = data['raw'];
      final contentMatch = RegExp(r"content='```json\\n(.*)\\n```'", dotAll: true).firstMatch(raw);

      if (contentMatch != null) {
        final escapedJson = contentMatch.group(1);
        if (escapedJson != null) {
          try {
            // \n, \" 등을 실제 문자로 변환
            String unescaped = escapedJson
                .replaceAll(r'\n', '\n')
                .replaceAll(r'\"', '"');

            // ✅ "숫자+단위" 형태에서 숫자만 추출 (예: 30g → 30)
            unescaped = unescaped.replaceAllMapped(
              RegExp(r'(?<="(calories|protein|carbs|fat|sodium)"\s*:\s*)(\d+)([a-zA-Z]+)'),
                  (match) => '${match[2]}',
            );

            return jsonDecode(unescaped);
          } catch (e) {
            print("❌ JSON parsing error: $e");
          }
        }
      }
      return null;
    }
    return data;
  }

  Future<void> _submitDiet() async {
    final token = await getAccessToken();
    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      print("meal_type : ${_meal!['meal_type']}");
      print("notes : ${_meal!['menu']}");
      print("date : ${formattedDate}");

      final payload = {
        "date": formattedDate,
        "mealType": _meal!['meal_type'],
        "notes": _meal!['menu'],
      };

      final response = await http.post(
        Uri.parse('https://forkcast.onrender.com/diet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildMealCard() {
    if (_meal == null) return const Text("❗ No recommended meal found");

    final List<dynamic> menuItems = (_meal!['menu'] is List)
        ? _meal!['menu']
        : (_meal!['menu'] is String)
        ? [_meal!['menu']]
        : [];

    final List<dynamic> notesItems = (_meal!['notes'] is List)
        ? _meal!['notes']
        : (_meal!['notes'] is String)
        ? [_meal!['notes']]
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _meal!['dish'] ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Text("🥗 Menu", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        ...menuItems.map((item) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("• $item", style: const TextStyle(fontSize: 16)),
        )),

        const SizedBox(height: 20),
        Text("📝 Notes", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        ...notesItems.map((item) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("• $item", style: const TextStyle(fontSize: 16)),
        )),

        const SizedBox(height: 20),
        Text("🍽 Nutrition", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        Text("Calories: ${_meal!['calories']} kcal"),
        Text("Protein: ${_meal!['protein']} g"),
        Text("Carbs: ${_meal!['carbs']} g"),
        Text("Fat: ${_meal!['fat']} g"),
        Text("Sodium: ${_meal!['sodium']}mg")
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _loading || _meal == null ? null : _submitDiet,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Add to diet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondColor,
      appBar: AppBar(
        toolbarHeight: 80,
        title: Align(
          alignment: Alignment.centerLeft, // 텍스트를 왼쪽으로 정렬
          child: const Text(
            "Have a healthy meal",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMealCard(),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
}
