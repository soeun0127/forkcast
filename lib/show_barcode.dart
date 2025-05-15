import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'get_access_token.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BarcodeResultPage extends StatefulWidget {
  final String barcode;
  const BarcodeResultPage({super.key, required this.barcode});

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();
}

class _BarcodeResultPageState extends State<BarcodeResultPage> {
  Map<String, dynamic>? itemData;
  bool isLoading = true;
  Map<String, dynamic>? _healthData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchItemData();
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
            _healthData = decoded[0];
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> fetchItemData() async {
    await fetchHealthData();
    final url = Uri.parse('https://solution-challenge-9bby.onrender.com/barcode');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': widget.barcode,
          'disease_name': _healthData?['disease']['name']?.toString()
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          itemData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Widget buildInfoCard(String label, String value, {IconData? icon}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: const Color(0xFF1AB098)) : null,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1AB098);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Result"),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemData == null
          ? const Center(child: Text("No data found."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📦 ${itemData!['itemName']}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            buildInfoCard("Calories", "${itemData!['calories']} kcal", icon: Icons.local_fire_department),
            buildInfoCard("Protein", "${itemData!['protein']} g", icon: Icons.fitness_center), // 🥚
            buildInfoCard("Sugar", "${itemData!['sugar']} g", icon: LucideIcons.candy), // 🍬
            buildInfoCard("Sodium", "${itemData!['sodium']} mg", icon: LucideIcons.zap), // 🧂

            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("⚠️ Notes", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(itemData!['notes'] ?? "", style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
