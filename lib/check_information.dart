import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/get_access_token.dart';

class CheckUserInfoPage extends StatefulWidget {
  const CheckUserInfoPage({Key? key}) : super(key: key);

  @override
  State<CheckUserInfoPage> createState() => _CheckUserInfoPageState();
}

class _CheckUserInfoPageState extends State<CheckUserInfoPage> {
  Map<String, dynamic>? _healthData;
  bool _loading = true;
  final primaryColor = const Color(0xFF20A090);
  final secondColor = const Color(0xFFE8F3F1);

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


  Widget buildInfoTile(String label, String? value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: secondColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value ?? "Not provided", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your Health Information",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              buildInfoTile("Disease ID", _healthData?['diseaseId']?.toString()),
              buildInfoTile("Protein Limit (g)", _healthData?['proteinLimit']?.toString()),
              buildInfoTile("Sugar Limit (g)", _healthData?['sugarLimit']?.toString()),
              buildInfoTile("Sodium Limit (mg)", _healthData?['sodiumLimit']?.toString()),
              buildInfoTile("Notes", _healthData?['notes']),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
