import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../services/gemini_service.dart';

class DoctorChatScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorChatScreen({
    required this.patientId,
    required this.patientName,
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  late GeminiService _geminiService;
  late ChatSession _chatSession;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String? _patientAge;
  String? _patientSymptoms;
  String? _patientHistory;
  bool _isPatientInfoComplete = false;
  bool _isLoading = false;
  bool _showPatientForm = true;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _initializeChat();
  }

  void _initializeChat() {
    final systemContext = '''You are a clinical decision support AI for physicians.
You provide evidence-based medical guidance for doctors treating patients.
Always be precise, clinical, and reference medical best practices.
Format responses with clear sections for diagnoses, investigations, and next steps.''';

    _chatSession = _geminiService.startChat(systemContext);
  }

  void _submitPatientInfo() {
    if ((_patientAge?.isEmpty ?? true) ||
        (_patientSymptoms?.isEmpty ?? true) ||
        (_patientHistory?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all patient information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isPatientInfoComplete = true;
      _showPatientForm = false;
    });

    _addMessage(
      'System',
      'Patient info recorded:\n✓ Age: $_patientAge\n✓ Symptoms: $_patientSymptoms\n✓ History: $_patientHistory',
      isSystem: true,
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    _addMessage('Doctor', message);

    setState(() => _isLoading = true);

    try {
      final prompt = '''PATIENT CONTEXT:
Age: ${_patientAge ?? 'Not specified'}
Symptoms: ${_patientSymptoms ?? 'Not specified'}
Medical History: ${_patientHistory ?? 'Not specified'}

Doctor's Clinical Question: $message

Respond with:
1. TOP 3 DIFFERENTIAL DIAGNOSES (with brief rationale)
2. KEY INVESTIGATIONS TO ORDER
3. RED FLAGS TO WATCH
4. RECOMMENDED NEXT STEPS''';

      final response = await _geminiService.sendChatMessage(
        _chatSession,
        prompt,
      );

      _addMessage('AI Assistant', response);
      _scrollToBottom();
    } catch (e) {
      _addMessage('Error', '❌ Failed to get response: ${e.toString()}',
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMessage(
    String sender,
    String text, {
    bool isSystem = false,
    bool isError = false,
  }) {
    setState(() {
      _messages.add(
        ChatMessage(
          sender: sender,
          text: text,
          timestamp: DateTime.now(),
          isSystem: isSystem,
          isError: isError,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showPatientForm
          ? AppBar(
              title: const Text('Patient Information'),
              elevation: 0,
              backgroundColor: Colors.blue.shade700,
              automaticallyImplyLeading: false,
            )
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Medical AI Assistant'),
                  Text(
                    'Patient: ${widget.patientName} | Age: $_patientAge',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
              elevation: 0,
              backgroundColor: Colors.blue.shade700,
            ),
      body: Column(
        children: [
          if (_showPatientForm) _buildPatientInfoForm(),
          Expanded(
            child: _messages.isEmpty && _isPatientInfoComplete
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(_messages[index]),
                  ),
          ),
          if (_isPatientInfoComplete) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPatientInfoForm() {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Enter Patient Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Patient Age',
                hintText: 'e.g., 45',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => _patientAge = value,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Symptoms',
                hintText: 'e.g., Fever, cough, chest pain',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.medical_services),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              onChanged: (value) => _patientSymptoms = value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Medical History',
                hintText: 'e.g., Diabetes, Hypertension',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.history),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              onChanged: (value) => _patientHistory = value,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitPatientInfo,
                icon: const Icon(Icons.check_circle),
                label: const Text('Start Consultation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start asking clinical questions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isDoctor = message.sender == 'Doctor';
    final isSystem = message.isSystem;
    final isError = message.isError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSystem
                ? Colors.grey.shade100
                : isError
                    ? Colors.red.shade100
                    : isDoctor
                        ? Colors.blue.shade500
                        : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: isError
                ? Border.all(color: Colors.red.shade300)
                : isSystem
                    ? Border.all(color: Colors.grey.shade300)
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.sender,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isError
                      ? Colors.red.shade700
                      : isSystem
                          ? Colors.grey.shade600
                          : isDoctor
                              ? Colors.white
                              : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isError
                      ? Colors.red.shade800
                      : isSystem
                          ? Colors.grey.shade700
                          : isDoctor
                              ? Colors.white
                              : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isError
                      ? Colors.red.shade600
                      : isSystem
                          ? Colors.grey.shade500
                          : isDoctor
                              ? Colors.white70
                              : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask clinical questions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade700,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              enabled: !_isLoading,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            mini: true,
            backgroundColor: Colors.blue.shade700,
            disabledElevation: 0,
            tooltip: 'Send message',
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isSystem;
  final bool isError;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
    this.isError = false,
  });
}