import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/get_access_token.dart';

class TodayMealRecordPage extends StatefulWidget {
  const TodayMealRecordPage({super.key});

  @override
  State<TodayMealRecordPage> createState() => _TodayMealRecordPageState();
}

class _TodayMealRecordPageState extends State<TodayMealRecordPage> {
  final Color primaryColor = const Color(0xFF20A090);
  final Color secondColor = const Color(0xFFEAF4F0);
  final TextEditingController _notesController = TextEditingController();

  String? _selectedMealType;
  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner'];

  Future<void> submitMealRecord() async {
    if (_selectedMealType == null || _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    final now = DateTime.now();
    final formattedDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final body = {
      "date": formattedDate,
      "mealType": _selectedMealType,
      "notes": _notesController.text.trim(),
    };

    final token = await getAccessToken();
    final url = Uri.parse('https://forkcast.onrender.com/diet');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Meal recorded successfully")),
        );
        Navigator.pop(context);
      } else {
        print("전송 실패: ${response.statusCode} ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A server error has occurred")),
        );
      }
    } catch (e) {
      print("예외 발생: $e");
    }
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
                onPressed: submitMealRecord,
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
