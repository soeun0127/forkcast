import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BarcodeResultPage extends StatefulWidget {
  final String barcode;
  const BarcodeResultPage({super.key, required this.barcode});

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();
}

class _BarcodeResultPageState extends State<BarcodeResultPage> {
  Map<String, dynamic>? itemData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItemData();
  }

  Future<void> fetchItemData() async {
    final url = Uri.parse('https://solution-challenge-9bby.onrender.com');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': widget.barcode}),
      );

      if (response.statusCode == 200) {
        setState(() {
          itemData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load item');
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1AB098);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Result"),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : itemData == null
          ? const Center(child: Text("No data found."))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📦 Product: ${itemData!['itemName']}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("🔥 Calories: ${itemData!['calories']} kcal"),
            Text("💪 Protein: ${itemData!['protein']} g"),
            Text("🍬 Sugar: ${itemData!['sugar']} g"),
            Text("🧂 Sodium: ${itemData!['sodium']} mg"),
            const SizedBox(height: 24),
            Text("⚠️ Notes:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
            Text(itemData!['notes'] ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
