import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendedMeal extends StatefulWidget {
  final Map<String, dynamic> data;

  const RecommendedMeal({super.key, required this.data});

  @override
  State<RecommendedMeal> createState() => _RecommendedMealState();
}

class _RecommendedMealState extends State<RecommendedMeal> {
  late dynamic _meals; // String 또는 List 가능
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _meals = widget.data['diet'];
  }

  Future<void> _addMeal(String input) async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://34.64.249.244:7860/generate_diet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_input': input}),
      );

      if (response.statusCode == 200) {
        final newData = jsonDecode(response.body);
        setState(() {
          _meals = newData['diet'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 응답 오류: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
        _controller.clear();
      });
    }
  }

  Widget _buildMealItem(dynamic meal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal['name']?.toString() ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            "${meal['calories']?.toString() ?? '-'} cals / ${meal['amount']?.toString() ?? '-'}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMealContent() {
    if (_meals == null) {
      return const Text("추천 식단이 없습니다.");
    }

    // 문자열(줄글) 형태일 때
    if (_meals is String) {
      return Text(_meals, style: const TextStyle(fontSize: 16));
    }

    // 리스트 형태일 때
    if (_meals is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (_meals as List).map((meal) => _buildMealItem(meal)).toList(),
      );
    }

    // 알 수 없는 형태
    return const Text("식단 정보를 표시할 수 없습니다.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Meal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// 🥗 식단 카드
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMealContent(),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Want to add a dish? Type it here!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration.collapsed(
                  hintText: "e.g., Tuna salad with egg and rice...",
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () {
                final input = _controller.text.trim();
                if (input.isNotEmpty) {
                  _addMeal(input);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AB098),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Add Meal", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
