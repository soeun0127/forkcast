import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/get_access_token.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;

  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Map<String, dynamic>? post;
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPost();
  }

  Future<void> fetchPost() async {
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('https://forkcast.onrender.com/community/posts/${widget.postId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        post = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('게시물 불러오기 실패: ${response.statusCode}');
    }
  }

  Future<void> submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('https://forkcast.onrender.com/community/posts/${widget.postId}/comment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 201) {
      // 댓글 성공 시 새 댓글 반영
      _commentController.clear();
      fetchPost(); // 댓글 다시 불러오기
    } else {
      print('댓글 등록 실패: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Detail")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : post == null
          ? const Center(child: Text('Unable to load post'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post!['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Author: ${post!['user']['name']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text(post!['content']),
            const SizedBox(height: 12),
            Text('Posted on: ${post!['createdAt'].substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 32),
            const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: post!['comments'].length,
                itemBuilder: (context, index) {
                  final comment = post!['comments'][index];
                  return ListTile(
                    title: Text(comment['content']),
                    subtitle: Text(comment['user']['name']),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: submitComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20A090),
                  ),
                  child: const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
