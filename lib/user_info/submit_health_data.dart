import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:solution_challenge/get_access_token.dart';
import 'package:solution_challenge/home.dart';
import 'package:http/http.dart' as http;

class CheckUserHealthPage extends StatefulWidget {
  const CheckUserHealthPage({Key? key, this.initialData}) : super(key: key); //initialData는 한 페이지로 입력, 수정을 할 때 사용
  final Map<String, dynamic>? initialData;

  @override
  State<CheckUserHealthPage> createState() => _CheckUserHealthPageState();
}

class _CheckUserHealthPageState extends State<CheckUserHealthPage> {
  int gender = -1;
  DateTime selectedDate = DateTime.now();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final diseaseController = TextEditingController();
  final proteinController = TextEditingController();
  final sugarController = TextEditingController();
  final sodiumController = TextEditingController();
  final notesController = TextEditingController();

  final primaryColor = const Color(0xFF20A090);
  final secondColor = const Color(0xFFE8F3F1);
  final genders = ['Male', 'Female', 'Other'];

  Future<void> submit() async {
    final url = Uri.parse('https://forkcast.onrender.com/user/health');
    final token = await getAccessToken();
    print(token);
    final userData = {
      "birthdate": selectedDate.toIso8601String().split("T")[0],
      "gender": gender == 0 ? "MALE" : gender == 1 ? "FEMALE" : "OTHER",
      "height": double.tryParse(heightController.text) ?? 0,
      "weight": double.tryParse(weightController.text) ?? 0,
      "diseaseName": diseaseController.text.trim(),
      "proteinLimit": int.tryParse(proteinController.text) ?? 0,
      "sugarLimit": int.tryParse(sugarController.text) ?? 0,
      "sodiumLimit": int.tryParse(sodiumController.text) ?? 0,
      "notes": notesController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization' : 'Bearer $token',
        },
        body: jsonEncode(userData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        print("전송 실패: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("예외 발생: $e");
    }
  }

  Widget buildInputField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: secondColor,
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Enter Your Information",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text("BirthDate", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2026),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: secondColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  width: double.infinity,
                  child: Text(
                    '${selectedDate.year} - ${selectedDate.month} - ${selectedDate.day}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              buildInputField("Height", heightController, keyboardType: TextInputType.number),
              buildInputField("Weight", weightController, keyboardType: TextInputType.number),
              const Text("Gender", style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8,
                children: List.generate(genders.length, (index) {
                  return ChoiceChip(
                    label: Text(genders[index]),
                    selected: gender == index,
                    showCheckmark: false,
                    selectedColor: primaryColor.withOpacity(0.3),
                    onSelected: (selected) {
                      setState(() => gender = selected ? index : -1);
                    },
                  );
                }),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                height: 2,
                color: primaryColor,
              ),
              buildInputField("Disease", diseaseController),
              buildInputField("Protein (g)", proteinController, keyboardType: TextInputType.number),
              buildInputField("Sugar (g)", sugarController, keyboardType: TextInputType.number),
              buildInputField("Sodium (mg)", sodiumController, keyboardType: TextInputType.number),
              buildInputField("Notes", notesController, maxLines: 3, hint: "Enter any notes here..."),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: submit,
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
}