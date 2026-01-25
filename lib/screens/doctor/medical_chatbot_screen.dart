import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class MedicalChatbotScreen extends StatefulWidget {
  const MedicalChatbotScreen({super.key});

  @override
  State<MedicalChatbotScreen> createState() => _MedicalChatbotScreenState();
}

class _MedicalChatbotScreenState extends State<MedicalChatbotScreen> { 

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  
  List<Map<String, String>> _messages = [
    {
      'role': 'system',
      'content': 'You are a professional medical assistant specialized in physiotherapy. Provide structured analysis for patients.'
    }
  ];

  
  void _startNewChat() {
    setState(() {
      _messages = [
        {'role': 'system', 'content': 'You are a professional medical assistant.'}
      ];
      _ageController.clear();
      _symptomsController.clear();
      _historyController.clear();
      _chatController.clear();
    });
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty && _messages.length > 1) return;
    
    setState(() {
      _isLoading = true;
      if (_messages.length == 1) {
        String initialData = "Age: ${_ageController.text}, Symptoms: ${_symptomsController.text}, History: ${_historyController.text}. Question: ${_chatController.text}";
        _messages.add({'role': 'user', 'content': initialData});
      } else {
        _messages.add({'role': 'user', 'content': _chatController.text});
      }
    });

    _chatController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl),
        headers: {'Authorization': 'Bearer ${ApiConfig.apiKey}', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': ApiConfig.model,
          'messages': _messages,
          'temperature': ApiConfig.temperature,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': decoded['choices'][0]['message']['content']
          });
        });
      } else {
        _showSnackBar('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Connection Error: $e');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Medical Assistant'), backgroundColor: const Color(0xFF102027), foregroundColor: Colors.white),
      
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF102027)),
              child: Center(child: Text('Chat History', style: TextStyle(color: Colors.white, fontSize: 20))),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Patient Chat'),
              onTap: () {
                _startNewChat();
                Navigator.pop(context);
              },
            ),
            const Divider(),
          ],
        ),
      ),
      
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                if (_messages[index]['role'] == 'system') return const SizedBox.shrink();
                bool isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: MarkdownBody(data: _messages[index]['content']!),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading) const LinearProgressIndicator(),

          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildSmallInput('Age', _ageController),
                  _buildSmallInput('Symptoms', _symptomsController),
                  _buildSmallInput('History', _historyController),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(hintText: 'Type your question...', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF102027)), onPressed: _isLoading ? null : _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder())),
    );
  }
}