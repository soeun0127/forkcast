import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendedMeal extends StatefulWidget {
  final Map<String, dynamic> data;

  const RecommendedMeal({super.key, required this.data});

  @override
  State<RecommendedMeal> createState() => _RecommendedMealState();
}

class _RecommendedMealState extends State<RecommendedMeal> {
  Map<String, dynamic>? _meal;
  Map<String, dynamic>? _nutrition;
  List<dynamic>? _conflicts;

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _meal = widget.data['diet']?['meal1']; // diet → meal1
    _nutrition = widget.data['nutrition'];
    _conflicts = widget.data['conflicts'];
  }

  Future<void> _addMeal(String input) async {
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://34.64.249.244:7860/generate_diet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_input': input}),
      );

      if (response.statusCode == 200) {
        final newData = jsonDecode(response.body);
        setState(() {
          _meal = newData['diet']?['meal1'];
          _nutrition = newData['nutrition'];
          _conflicts = newData['conflicts'];
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

  Widget _buildMealCard() {
    if (_meal == null) return const Text("추천 식단이 없습니다.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_meal!['dish'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Text("🥗 Menu", style: const TextStyle(fontWeight: FontWeight.bold)),
        ...(_meal!['menu'] as List<dynamic>).map((item) => Text("• $item")),

        const SizedBox(height: 12),
        Text("📝 Notes", style: const TextStyle(fontWeight: FontWeight.bold)),
        ...(_meal!['notes'] as List<dynamic>).map((item) => Text("• $item")),

        const SizedBox(height: 12),
        Text("🍽 Nutrition", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("Calories: ${_meal!['calories']} kcal"),
        Text("Protein: ${_meal!['protein']} g"),
        Text("Carbs: ${_meal!['carbs']} g"),
        Text("Fat: ${_meal!['fat']} g"),
      ],
    );
  }

  Widget _buildNutritionSection() {
    if (_nutrition == null || _nutrition!.isEmpty) {
      return const Text("No nutrition info available.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text("🍎 Nutrition per Ingredient",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._nutrition!.entries.map((entry) {
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ${item['name'] ?? entry.key}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("  - Calories: ${item['calories']} kcal"),
                Text("  - Protein: ${item['protein']} g"),
                Text("  - Fat: ${item['fat']} g"),
                Text("  - Carbohydrates: ${item['carbohydrates']} g"),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildConflictSection() {
    if (_conflicts == null || _conflicts!.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text("⚠️ Conflicting Ingredients",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _conflicts!
              .map((item) => Chip(
            label: Text(item.toString()),
            backgroundColor: Colors.red.shade100,
            labelStyle: const TextStyle(color: Colors.red),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text("Want to add a dish? Type it here!",
            style: TextStyle(fontWeight: FontWeight.bold)),
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
            if (input.isNotEmpty) _addMeal(input);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1AB098),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Add Meal", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Meal")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMealCard(),
              ),
            ),
            _buildNutritionSection(),
            _buildConflictSection(),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }
}
