import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solution_challenge/get_access_token.dart';
import '../calendar.dart';
import '../home.dart';
import '../profile.dart';
import 'new_post.dart';
import 'post_detail.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<dynamic> posts = [];
  bool isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final String? token = await getAccessToken();
    final response = await http.get(
      Uri.parse('https://forkcast.onrender.com/community/posts'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        posts = data;
        isLoading = false;
      });
    } else {
      setState(() {
        posts = [];
        isLoading = false;
      });
      print('게시물 불러오기 실패: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Community",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(
        child: Text(
          'no posts',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: posts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final post = posts[index];
          final user = post['user'] ?? {};
          return InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(postId: post['id']),
                ),
              );
              if (result == true) {
                fetchPosts(); // ✅ 댓글 달린 경우도 반영
              }
            },
            child: Card(
              color: const Color(0xFFEAF4F0),
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${user['name'] ?? '익명'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(post['content'] ?? ''),
                    const SizedBox(height: 8),
                    Text(
                      post['createdAt']?.substring(0, 10) ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPostPage()),
          );
          if (result == true) {
            fetchPosts(); // ✅ 작성 후 목록 새로고침
          }
        },
        backgroundColor: const Color(0xFF20A090),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1AB098),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
            } else if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityPage()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}
