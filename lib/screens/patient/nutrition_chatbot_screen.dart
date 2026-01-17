// =============================================================================
// NUTRITION CHATBOT SCREEN - AI FOOD ANALYSIS
// =============================================================================
// Purpose: AI-powered nutrition assistant with food photo analysis
// Features:
// - Upload food photos via camera or gallery
// - Extract ingredients using Gemini Vision
// - Get nutrition facts from Edamam API
// - Display nutrition facts table with Daily Values
// - Per-ingredient breakdown
// - Chat interface with AI nutritionist
// =============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart'
    show ChatSession;
import '../../utils/theme_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/edamam_service.dart';

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
  final List<ChatMessage> _messages = [];

  late GeminiService _geminiService;
  late EdamamService _edamamService;

  bool _isAnalyzing = false;
  ChatSession? _chatSession;
  String? _currentIngredientsText;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _edamamService = EdamamService();

    // Welcome message
    _addMessage(
      ChatMessage(
        text: t(
          'Hello! I\'m your nutrition assistant. Upload a photo of your meal, and I\'ll analyze its calories and nutritional content!',
          'مرحباً! أنا مساعدك الغذائي. قم بتحميل صورة لوجبتك، وسأقوم بتحليل السعرات الحرارية والمحتوى الغذائي!',
        ),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
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
        _addMessage(
          ChatMessage(
            text: t('Analyzing this meal...', 'تحليل هذه الوجبة...'),
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: image.path,
          ),
        );
        _analyzeImage(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(t('Error selecting image', 'خطأ في اختيار الصورة'))),
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
        _addMessage(
          ChatMessage(
            text: t('Analyzing this meal...', 'تحليل هذه الوجبة...'),
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: image.path,
          ),
        );
        _analyzeImage(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(t('Error capturing image', 'خطأ في التقاط الصورة'))),
      );
    }
  }

  Future<void> _analyzeImage(String imagePath) async {
    setState(() => _isAnalyzing = true);

    try {
      // Step 1: Extract ingredients using Gemini Vision
      debugPrint('[Nutrition] 🔍 Extracting ingredients from image...');
      final ingredientsText =
          await _geminiService.extractIngredientsFromImageFile(File(imagePath));

      if (!mounted) return;

      debugPrint('[Nutrition] ✓ Detected ingredients: $ingredientsText');
      _currentIngredientsText = ingredientsText;

      // Step 2: Get nutrition facts from Edamam API
      debugPrint('[Nutrition] 📊 Calling Edamam API...');
      final result = await _edamamService.getNutritionFacts(ingredientsText);

      if (!mounted) return;

      if (result == null) {
        throw Exception(
            'Edamam could not parse the ingredients. Ensure quantities are included.');
      }

      debugPrint('[Nutrition] ✓ Got nutrition facts');

      // Step 3: Display nutrition facts
      final nutritionMessage = _buildNutritionFactsMessage(result);
      _addMessage(
        ChatMessage(
          text: nutritionMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      // Step 4: Initialize chat with nutrition context
      _initializeChatSession(ingredientsText, result);

      // Step 5: Generate initial AI assessment
      await _generateInitialAssessment();

      setState(() => _isAnalyzing = false);
    } catch (e) {
      debugPrint('[Nutrition] ❌ Error: $e');
      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      final errorMsg = e.toString();
      String displayMessage;

      // Check if it's a quota error
      if (errorMsg.contains('quota') ||
          errorMsg.contains('429') ||
          errorMsg.contains('RESOURCE_EXHAUSTED')) {
        displayMessage = t(
          'API quota exceeded. Please wait a moment and try again with a different meal.',
          'تم تجاوز حد API. يرجى الانتظار قليلاً والمحاولة مجدداً بوجبة مختلفة.',
        );
      } else if (errorMsg.contains('Network') ||
          errorMsg.contains('connection')) {
        displayMessage = t(
          'Network error. Please check your internet connection.',
          'خطأ في الشبكة. يرجى التحقق من اتصالك بالإنترنت.',
        );
      } else {
        displayMessage = t(
          'Sorry, I couldn\'t analyze the meal. Please try with another image.',
          'عذراً، لم أتمكن من تحليل الوجبة. يرجى محاولة صورة أخرى.',
        );
      }

      _addMessage(
        ChatMessage(
          text: displayMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  String _buildNutritionFactsMessage(NutritionResult result) {
    final buffer = StringBuffer();

    buffer.write('🍽️ ${t("Detected Ingredients", "المكونات المكتشفة")}:\n');
    if (_currentIngredientsText != null) {
      buffer.write('$_currentIngredientsText\n\n');
    }

    buffer.write('📊 ${t("Nutrition Facts", "الحقائق الغذائية")}:\n');

    // Macronutrients with Daily Value %
    final nutrientMap = [
      ('ENERC_KCAL', '⚡ Calories', 'kcal'),
      ('PROCNT', '🥩 Protein', 'g'),
      ('CHOCDF', '🍞 Carbs', 'g'),
      ('FAT', '🧈 Fat', 'g'),
      ('FIBTG', '🌾 Fiber', 'g'),
      ('NA', '🧂 Sodium', 'mg'),
    ];

    for (final (code, emoji, unit) in nutrientMap) {
      final nutrient = result.nutrients[code];
      if (nutrient != null && nutrient.quantity > 0) {
        final dv = nutrient.dailyValuePercent;
        buffer.write(
            '$emoji ${nutrient.label}: ${nutrient.quantity.toStringAsFixed(1)} $unit');
        if (dv > 0) {
          buffer.write(' (${dv.toStringAsFixed(0)}%)');
        }
        buffer.write('\n');
      }
    }

    // Per-ingredient breakdown
    if (result.ingredients.isNotEmpty) {
      buffer
          .write('\n📈 ${t("Per-Ingredient Breakdown", "تفصيل المكونات")}:\n');
      for (final ing in result.ingredients.take(5)) {
        buffer.write('• ${ing.name}: ');
        if (ing.calories > 0) {
          buffer.write('${ing.calories.toStringAsFixed(0)} cal, ');
        }
        buffer.write(
            'P:${ing.protein.toStringAsFixed(1)}g C:${ing.carbs.toStringAsFixed(1)}g F:${ing.fat.toStringAsFixed(1)}g\n');
      }
    }

    return buffer.toString();
  }

  void _initializeChatSession(String ingredients, NutritionResult result) {
    final nutritionSummary = _buildNutritionSummaryForContext(result);

    final systemContext =
        '''You are a professional nutritionist and health advisor.

INGREDIENTS DETECTED:
$ingredients

NUTRITION FACTS:
$nutritionSummary

USER CONTEXT:
The user just uploaded a food photo. Use the nutrition data above to provide personalized advice.

YOUR ROLE:
1. Assess the meal's nutritional balance
2. Highlight nutritional strengths
3. Point out nutritional concerns
4. Recommend improvements or alternative foods
5. Answer detailed questions about the meal

Be friendly, evidence-based, and provide actionable recommendations.''';

    _chatSession = _geminiService.startChat(systemContext);
  }

  String _buildNutritionSummaryForContext(NutritionResult result) {
    final buffer = StringBuffer();

    if (result.calories != null) {
      buffer.write('Calories: ${result.calories!.toStringAsFixed(0)} kcal\n');
    }
    if (result.protein != null) {
      buffer.write('Protein: ${result.protein!.toStringAsFixed(1)}g\n');
    }
    if (result.carbs != null) {
      buffer.write('Carbs: ${result.carbs!.toStringAsFixed(1)}g\n');
    }
    if (result.fat != null) {
      buffer.write('Fat: ${result.fat!.toStringAsFixed(1)}g\n');
    }
    if (result.fiber != null) {
      buffer.write('Fiber: ${result.fiber!.toStringAsFixed(1)}g\n');
    }
    if (result.sodium != null) {
      buffer.write('Sodium: ${result.sodium!.toStringAsFixed(0)}mg\n');
    }

    return buffer.toString();
  }

  Future<void> _generateInitialAssessment() async {
    if (_chatSession == null) return;

    try {
      debugPrint('[Nutrition] 💬 Generating initial assessment...');
      final response = await _geminiService.sendChatMessage(
        _chatSession!,
        'Based on the nutrition data above, provide a brief 2-3 sentence assessment of this meal and one key recommendation.',
      );

      if (!mounted) return;

      _addMessage(
        ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[Nutrition] ❌ Error generating assessment: $e');
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isAnalyzing) return;

    _addMessage(
      ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _messageController.clear();
    _generateChatResponse(text);
  }

  Future<void> _generateChatResponse(String userMessage) async {
    setState(() => _isAnalyzing = true);

    try {
      // If no chat session, create a general nutrition chatbot
      if (_chatSession == null) {
        const systemContext =
            '''You are a professional nutritionist and health advisor.
Provide helpful, evidence-based nutrition and wellness advice.
Be friendly, professional, and provide actionable recommendations.''';

        _chatSession = _geminiService.startChat(systemContext);
      }

      debugPrint('[Nutrition] 💬 Sending: $userMessage');
      final response = await _geminiService.sendChatMessage(
        _chatSession!,
        userMessage,
      );

      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      _addMessage(
        ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('[Nutrition] ❌ Error: $errorMsg');
      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      // Check if it's a quota error
      String displayMessage;
      if (errorMsg.contains('quotaExceeded') ||
          errorMsg.contains('quota') ||
          errorMsg.contains('429') ||
          errorMsg.contains('Quota exceeded')) {
        displayMessage = t(
          'API quota exceeded. Please wait a moment and try again, or upload a new meal.',
          'تم تجاوز حد API. يرجى الانتظار قليلاً والمحاولة مجدداً، أو حمّل وجبة جديدة.',
        );
      } else if (errorMsg.contains('Network') ||
          errorMsg.contains('connection')) {
        displayMessage = t(
          'Network error. Please check your internet connection and try again.',
          'خطأ في الشبكة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.',
        );
      } else {
        displayMessage = t(
          'Sorry, I couldn\'t generate a response. Please try again.',
          'عذراً، لم أتمكن من إنشاء رد. يرجى المحاولة مجدداً.',
        );
      }

      _addMessage(
        ChatMessage(
          text: displayMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
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
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
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
              child: const Icon(Icons.restaurant_menu,
                  color: Color(0xFF8BC34A), size: 24),
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
                return _ChatBubble(
                  message: _messages[index],
                  isDark: isDark,
                );
              },
            ),
          ),

          // Input area
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
                  onPressed: _isAnalyzing ? null : _captureImageWithCamera,
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF8BC34A)),
                  tooltip: t('Take Photo', 'التقاط صورة'),
                ),
                IconButton(
                  onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                  icon:
                      const Icon(Icons.photo_library, color: Color(0xFF8BC34A)),
                  tooltip: t('Gallery', 'المعرض'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isAnalyzing,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText:
                          t('Ask about nutrition...', 'اسأل عن التغذية...'),
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
                    onPressed: _isAnalyzing ? null : _sendMessage,
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
            child: const Icon(Icons.restaurant_menu,
                color: Color(0xFF8BC34A), size: 18),
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

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _ChatBubble({required this.message, required this.isDark});

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
              backgroundColor: const Color(0xFF8BC34A).withValues(alpha: 0.2),
              child: const Icon(Icons.restaurant_menu,
                  color: Color(0xFF8BC34A), size: 18),
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
              child:
                  const Icon(Icons.person, color: Color(0xFF8BC34A), size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
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

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
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
