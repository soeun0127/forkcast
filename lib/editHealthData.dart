import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/home.dart';

class EditUserHealthPage extends StatefulWidget {
  const EditUserHealthPage({super.key});

  @override
  State<EditUserHealthPage> createState() => _EditUserHealthPage();
}

class _EditUserHealthPage extends State<EditUserHealthPage> {
  final diseaseController = TextEditingController();
  final proteinController = TextEditingController();
  final sugarController = TextEditingController();
  final sodiumController = TextEditingController();
  final notesController = TextEditingController();

  final primaryColor = const Color(0xFF20A090);
  final secondColor = const Color(0xFFE8F3F1);

  Future<void> updateHealthInfo() async {
    final url = Uri.parse('https://api/user/health'); // 실제 API 주소로 변경

    final data = {
      "diseaseId": int.tryParse(diseaseController.text) ?? 0,
      "proteinLimit": int.tryParse(proteinController.text) ?? 0,
      "sugarLimit": int.tryParse(sugarController.text) ?? 0,
      "sodiumLimit": int.tryParse(sodiumController.text) ?? 0,
      "notes": notesController.text.trim(),
    };

    try {
      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        print('PUT 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('예외 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Edit Your Information", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // 입력 필드들
              buildField("Disease", diseaseController),
              buildField("Protein (g)", proteinController, isNumber: true),
              buildField("Sugar (g)", sugarController, isNumber: true),
              buildField("Sodium (mg)", sodiumController, isNumber: true),
              buildField("Notes", notesController, maxLines: 3, hint: "Enter any notes here..."),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: updateHealthInfo,
                  child: const Text('Submit', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: secondColor,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
