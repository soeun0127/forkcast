import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SimpleHelloPage extends StatefulWidget {
  const SimpleHelloPage({super.key});

  @override
  State<SimpleHelloPage> createState() => _SimpleHelloPageState();
}

class _SimpleHelloPageState extends State<SimpleHelloPage> {
  final TextEditingController _controller = TextEditingController();
  String? _responseMessage;
  bool _loading = false;

  Future<void> sendNameToBackend() async {
    final String name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _loading = true;
      _responseMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://34.64.214.63:5000/hello'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return; // 추가
        setState(() {
          _responseMessage = data['message'];
        });
      } else {
        if (!mounted) return; // 추가
        setState(() {
          _responseMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hello Sender')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your name:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "e.g., 혜린",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : sendNameToBackend,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send to Server"),
            ),
            const SizedBox(height: 32),
            if (_responseMessage != null)
              Text("📬 Response: $_responseMessage",
                  style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
