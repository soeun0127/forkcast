import 'dart:math';
import 'package:flutter/material.dart';
import 'package:solution_challenge/home.dart';

class EditUserHealthPage extends StatefulWidget {
  const EditUserHealthPage({super.key});

  @override
  State<EditUserHealthPage> createState() => _EditUserHealthPage();
}

class _EditUserHealthPage extends State<EditUserHealthPage> {
  int? gender = -1;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF20A090);
    final secondColor = const Color(0xFFE8F3F1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Edit Your Information",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Text("disease", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: secondColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Protein (g)", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: secondColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Sugar (g)", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: secondColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Sodium (mg)", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: secondColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Notes", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: secondColor,
                    hintText: "Enter any notes here...",
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32), // 마지막 여백
              ],
            ),
          ),
        ),
      ),
    );
  }
}
