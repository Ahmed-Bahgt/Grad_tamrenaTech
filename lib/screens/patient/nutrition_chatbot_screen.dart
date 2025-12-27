// =============================================================================
// NUTRITION CHATBOT SCREEN - AI FOOD ANALYSIS
// =============================================================================
// Purpose: AI-powered nutrition assistant for patients
// Features:
// - Upload food photos via camera or gallery
// - AI calorie detection and nutritional analysis
// - Chat interface with nutrition advice
// - Meal tracking and recommendations
// =============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/theme_provider.dart';

class NutritionChatbotScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const NutritionChatbotScreen({super.key, this.onBack});

  @override
  State<NutritionChatbotScreen> createState() => _NutritionChatbotScreenState();
}

class _NutritionChatbotScreenState extends State<NutritionChatbotScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<NutritionMessage> _messages = [];
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(NutritionMessage(
      text: t(
        'Hello! I\'m your nutrition assistant. Upload a photo of your meal, and I\'ll analyze its calories and nutritional content!',
        'مرحباً! أنا مساعدك الغذائي. قم بتحميل صورة لوجبتك، وسأقوم بتحليل السعرات الحرارية والمحتوى الغذائي!',
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        _addImageMessage(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Error selecting image', 'خطأ في اختيار الصورة'))),
      );
    }
  }

  Future<void> _captureImageWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        _addImageMessage(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Error capturing image', 'خطأ في التقاط الصورة'))),
      );
    }
  }

  void _addImageMessage(String imagePath) {
    setState(() {
      _messages.add(NutritionMessage(
        text: t('Analyzing this meal...', 'تحليل هذه الوجبة...'),
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ));
    });

    _scrollToBottom();
    _analyzeFood(imagePath);
  }

  Future<void> _analyzeFood(String imagePath) async {
    setState(() => _isAnalyzing = true);

    // Simulate AI analysis delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Mock AI analysis results
    final analysisResult = _generateMockAnalysis();

    setState(() {
      _messages.add(NutritionMessage(
        text: analysisResult,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isAnalyzing = false;
    });

    _scrollToBottom();
  }

  String _generateMockAnalysis() {
    final dishes = [
      {
        'name': t('Grilled Chicken Salad', 'سلطة دجاج مشوي'),
        'calories': '350',
        'protein': '42g',
        'carbs': '15g',
        'fats': '12g',
        'fiber': '8g',
      },
      {
        'name': t('Rice with Vegetables', 'أرز مع خضار'),
        'calories': '420',
        'protein': '12g',
        'carbs': '68g',
        'fats': '8g',
        'fiber': '6g',
      },
      {
        'name': t('Mixed Fruit Bowl', 'وعاء فواكه مشكلة'),
        'calories': '180',
        'protein': '2g',
        'carbs': '45g',
        'fats': '1g',
        'fiber': '7g',
      },
    ];

    final dish = dishes[DateTime.now().second % dishes.length];

    return t(
      '🍽️ Detected: ${dish['name']}\n\n'
      '📊 Nutritional Analysis:\n'
      '• Calories: ${dish['calories']} kcal\n'
      '• Protein: ${dish['protein']}\n'
      '• Carbs: ${dish['carbs']}\n'
      '• Fats: ${dish['fats']}\n'
      '• Fiber: ${dish['fiber']}\n\n'
      '💡 Recommendation: Great balanced meal! The protein content will help with muscle recovery.',
      '🍽️ تم الكشف: ${dish['name']}\n\n'
      '📊 التحليل الغذائي:\n'
      '• السعرات: ${dish['calories']} سعرة\n'
      '• البروتين: ${dish['protein']}\n'
      '• الكربوهيدرات: ${dish['carbs']}\n'
      '• الدهون: ${dish['fats']}\n'
      '• الألياف: ${dish['fiber']}\n\n'
      '💡 توصية: وجبة متوازنة رائعة! محتوى البروتين سيساعد في استعادة العضلات.',
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(NutritionMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });

    _scrollToBottom();
    _generateAIResponse(text);
  }

  Future<void> _generateAIResponse(String userMessage) async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    String response = '';
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('protein') || lowerMessage.contains('بروتين')) {
      response = t(
        'For muscle recovery, aim for 1.6-2.2g of protein per kg of body weight daily. Good sources include chicken, fish, eggs, and legumes.',
        'للتعافي العضلي، استهدف 1.6-2.2 جرام بروتين لكل كيلوجرام من وزن الجسم يومياً. المصادر الجيدة تشمل الدجاج والسمك والبيض والبقوليات.',
      );
    } else if (lowerMessage.contains('calorie') || lowerMessage.contains('سعرات')) {
      response = t(
        'Daily calorie needs vary by activity level. For recovery, maintain a balanced intake with adequate protein and nutrients.',
        'الاحتياجات اليومية من السعرات تختلف حسب مستوى النشاط. للتعافي، حافظ على تناول متوازن مع بروتين ومغذيات كافية.',
      );
    } else if (lowerMessage.contains('water') || lowerMessage.contains('ماء')) {
      response = t(
        'Aim for 8-10 glasses of water daily. Proper hydration is crucial for muscle recovery and overall health.',
        'استهدف 8-10 أكواب ماء يومياً. الترطيب المناسب ضروري للتعافي العضلي والصحة العامة.',
      );
    } else {
      response = t(
        'I can help you with meal analysis, nutrition advice, and dietary recommendations. Upload a food photo or ask me about nutrition!',
        'يمكنني مساعدتك في تحليل الوجبات ونصائح التغذية والتوصيات الغذائية. قم بتحميل صورة طعام أو اسألني عن التغذية!',
      );
    }

    setState(() {
      _messages.add(NutritionMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8BC34A)),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8BC34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu, color: Color(0xFF8BC34A), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              t('Nutrition AI', 'الذكاء الاصطناعي للتغذية'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isAnalyzing ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAnalyzing && index == _messages.length) {
                  return _buildTypingIndicator(isDark);
                }
                return _MessageBubble(
                  message: _messages[index],
                  isDark: isDark,
                );
              },
            ),
          ),

          // Upload actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                IconButton(
                  onPressed: _captureImageWithCamera,
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF8BC34A)),
                  tooltip: t('Take Photo', 'التقاط صورة'),
                ),
                IconButton(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library, color: Color(0xFF8BC34A)),
                  tooltip: t('Gallery', 'المعرض'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: t('Ask about nutrition...', 'اسأل عن التغذية...'),
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8BC34A), Color(0xFF689F38)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF8BC34A).withValues(alpha: 0.2),
            child: const Icon(Icons.restaurant_menu, color: Color(0xFF8BC34A), size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final NutritionMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF8BC34A).withValues(alpha: 0.2),
              child: const Icon(Icons.restaurant_menu, color: Color(0xFF8BC34A), size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF8BC34A)
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
              backgroundColor: const Color(0xFF8BC34A).withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: Color(0xFF8BC34A), size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
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
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF8BC34A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class NutritionMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  NutritionMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });
}
