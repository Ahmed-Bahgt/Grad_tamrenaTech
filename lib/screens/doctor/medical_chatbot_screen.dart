// =============================================================================
// MEDICAL CHATBOT SCREEN - AI MEDICAL ASSISTANT
// =============================================================================
// Purpose: Interactive AI chatbot for medical queries and assistance
// Features:
// - Real-time chat interface with message bubbles
// - Camera button - Take photos directly for analysis
// - Gallery button - Upload images from device
// - AI responses for: Pain management, rehab protocols, exercises
// - Typing indicator with animated dots
// - Message history with timestamps
// - Image upload and simulated AI image analysis
// AI Capabilities:
// - Contextual medical responses based on keywords
// - Visual analysis of uploaded medical images
// - Treatment protocol recommendations
// =============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widgets/custom_app_bar.dart';
import '../../utils/theme_provider.dart';

/// Medical Chatbot Screen for Doctor
class MedicalChatbotScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const MedicalChatbotScreen({super.key, this.onBack});

  @override
  State<MedicalChatbotScreen> createState() => _MedicalChatbotScreenState();
}

class _MedicalChatbotScreenState extends State<MedicalChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: t(
        'Hello Doctor! I\'m your medical AI assistant. How can I help you today?',
        'مرحباً دكتور! أنا مساعدك الطبي الذكي. كيف يمكنني مساعدتك اليوم؟',
      ),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _generateResponse(text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    if (lowerMessage.contains('pain') || lowerMessage.contains('ألم')) {
      return t(
        'For pain management, consider: 1) Rest and ice therapy, 2) Anti-inflammatory medication if appropriate, 3) Gentle stretching exercises. Would you like more specific guidance?',
        'لإدارة الألم، ضع في اعتبارك: 1) الراحة والعلاج بالثلج، 2) الأدوية المضادة للالتهابات إذا كانت مناسبة، 3) تمارين التمدد اللطيفة. هل تريد إرشادات أكثر تحديداً؟',
      );
    } else if (lowerMessage.contains('rehab') ||
        lowerMessage.contains('تأهيل')) {
      return t(
        'Rehabilitation protocols typically involve: Progressive loading, Range of motion exercises, Strength training, and Functional movement patterns. What specific area are you treating?',
        'بروتوكولات إعادة التأهيل تتضمن عادةً: التحميل التدريجي، تمارين نطاق الحركة، تدريب القوة، وأنماط الحركة الوظيفية. ما هي المنطقة المحددة التي تعالجها؟',
      );
    } else if (lowerMessage.contains('exercise') ||
        lowerMessage.contains('تمرين')) {
      return t(
        'I can help recommend exercises based on the condition. For best results, consider: Patient\'s current mobility, Pain levels, Treatment goals, and Stage of recovery. What\'s the primary concern?',
        'يمكنني المساعدة في التوصية بالتمارين بناءً على الحالة. للحصول على أفضل النتائج، ضع في اعتبارك: الحركة الحالية للمريض، مستويات الألم، أهداف العلاج، ومرحلة التعافي. ما هو القلق الأساسي؟',
      );
    } else {
      return t(
        'I understand. As a medical AI assistant, I can help with treatment protocols, exercise recommendations, rehabilitation plans, and medical queries. How can I assist you further?',
        'أفهم ذلك. كمساعد طبي ذكي، يمكنني المساعدة في بروتوكولات العلاج، توصيات التمارين، خطط إعادة التأهيل، والاستفسارات الطبية. كيف يمكنني مساعدتك أكثر؟',
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: t('Sent an image', 'تم إرسال صورة'),
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: photo.path,
          ));
          _isTyping = true;
        });

        _scrollToBottom();

        // Simulate AI analyzing the image
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: t(
                  'I\'ve analyzed the image. It appears to show a clinical presentation. Please provide more context about what you\'d like me to evaluate.',
                  'لقد قمت بتحليل الصورة. يبدو أنها تُظهر عرضاً سريرياً. يرجى تقديم مزيد من السياق حول ما تريد مني تقييمه.',
                ),
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isTyping = false;
            });
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t('Failed to take photo', 'فشل التقاط الصورة'))),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: t('Sent an image', 'تم إرسال صورة'),
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: image.path,
          ));
          _isTyping = true;
        });

        _scrollToBottom();

        // Simulate AI analyzing the image
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: t(
                  'Image received and analyzed. Based on the visual information, I can provide insights. What specific aspect would you like me to focus on?',
                  'تم استلام الصورة وتحليلها. بناءً على المعلومات البصرية، يمكنني تقديم رؤى. ما هو الجانب المحدد الذي تريد مني التركيز عليه؟',
                ),
                isUser: false,
                timestamp: DateTime.now(),
              ));
              _isTyping = false;
            });
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(t('Failed to pick image', 'فشل اختيار الصورة'))),
        );
      }
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: t('Medical Chatbot', 'الدردشة الطبية'),
        onBack: widget.onBack,
      ),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(message: message, isDark: isDark);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF161B22) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(delay: 0),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 200),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                // Camera Button
                IconButton(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF00BCD4)),
                  tooltip: t('Take Photo', 'التقاط صورة'),
                ),
                // Gallery Button
                IconButton(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo, color: Color(0xFF00BCD4)),
                  tooltip: t('Upload Image', 'رفع صورة'),
                ),
                const SizedBox(width: 8),
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: t('Type a message...', 'اكتب رسالة...'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                    ),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                    tooltip: t('Send', 'إرسال'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
              child: const Icon(Icons.smart_toy,
                  color: Color(0xFF00BCD4), size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF00BCD4)
                        : (isDark ? const Color(0xFF161B22) : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(message.imagePath!),
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
              child:
                  const Icon(Icons.person, color: Color(0xFF00BCD4), size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF00BCD4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });
}
