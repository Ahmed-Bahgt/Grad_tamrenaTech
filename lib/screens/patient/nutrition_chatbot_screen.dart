import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:tamren_tech/services/edamam_service.dart';
import 'package:tamren_tech/services/gemini_service.dart';
import 'package:tamren_tech/widgets/custom_app_bar.dart';

class NutritionChatbotScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const NutritionChatbotScreen({super.key, this.onBack});

  @override
  State<NutritionChatbotScreen> createState() => _NutritionChatbotScreenState();
}

class _NutritionChatbotScreenState extends State<NutritionChatbotScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _gemini = GeminiService();
  final EdamamService _edamam = EdamamService();
  final TextEditingController _messageController = TextEditingController();

  File? _imageFile;
  String? _ingredients;
  NutritionResult? _nutrition;
  bool _isAnalyzing = false;
  bool _isSending = false;
  String? _error;
  ChatSession? _chat;
  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() {
        _imageFile = File(picked.path);
        _ingredients = null;
        _nutrition = null;
        _chat = null;
        _messages.clear();
        _error = null;
      });
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      _showError('Please select an image first.');
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _nutrition = null;
      _ingredients = null;
    });
    try {
      final ingredients =
          await _gemini.extractIngredientsFromImageFile(_imageFile!);
      if (!mounted) return;

      if (ingredients.isEmpty) {
        _showError('No ingredients detected. Try a clearer image.');
        return;
      }

      final nutrition = await _edamam.getNutritionFacts(ingredients);
      if (!mounted) return;

      if (nutrition == null) {
        _showError('Nutrition analysis failed.');
        return;
      }

      final contextText = _buildContext(ingredients, nutrition);
      _chat = _gemini.startChat(contextText);

      setState(() {
        _ingredients = ingredients;
        _nutrition = nutrition;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Analysis failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  String _buildContext(String ingredients, NutritionResult nutrition) {
    final buffer = StringBuffer();
    buffer.writeln('You are a concise nutrition assistant.');
    buffer.writeln('INGREDIENTS: $ingredients');
    buffer.writeln('NUTRITION_FACTS:');

    for (final entry in nutrition.nutrients.entries) {
      final n = entry.value;
      buffer.writeln('${n.label}: ${n.quantity.toStringAsFixed(1)} ${n.unit}');
    }
    return buffer.toString();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_chat == null) {
      _showError('Analyze an image first to start the chat.');
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(role: MessageRole.user, text: text));
      _messageController.clear();
    });

    try {
      final reply = await _gemini.sendChatMessage(_chat!, text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: MessageRole.assistant, text: reply));
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Chat failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
      _isAnalyzing = false;
      _isSending = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CustomAppBar(title: 'Nutrition Assistant', onBack: widget.onBack),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCard(isDark),
              const SizedBox(height: 16),
              _buildActionButtons(),
              if (_isAnalyzing) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ],
              if (_ingredients != null || _nutrition != null) ...[
                const SizedBox(height: 16),
                _buildResultsCard(isDark),
              ],
              const SizedBox(height: 16),
              _buildChatSection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: _imageFile == null
          ? Column(
              children: [
                Icon(Icons.image, size: 64, color: Colors.teal.shade400),
                const SizedBox(height: 8),
                Text(
                  'Pick a meal photo to analyze',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _imageFile!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isAnalyzing ? null : _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick Image'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeImage,
            icon: const Icon(Icons.analytics),
            label: const Text('Analyze'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_ingredients != null) ...[
            const Text(
              'Ingredients (from image):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _ingredients!,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_nutrition != null) ...[
            const Text(
              'Key Nutrition (estimated):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _macroChips(isDark),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _macroChips(bool isDark) {
    final n = _nutrition;
    if (n == null) return [];

    Widget chip(String label, double? value, String unit) {
      return Chip(
        label: Text('$label: ${value?.toStringAsFixed(1) ?? '-'} $unit'),
        backgroundColor: isDark ? Colors.white12 : Colors.grey[100],
      );
    }

    return [
      chip('Calories', n.calories, 'kcal'),
      chip('Protein', n.protein, 'g'),
      chip('Carbs', n.carbs, 'g'),
      chip('Fat', n.fat, 'g'),
      chip('Fiber', n.fiber, 'g'),
      chip('Sodium', n.sodium, 'mg'),
    ];
  }

  Widget _buildChatSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Chatbot',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 320),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[300]!,
            ),
          ),
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Analyze an image, then ask questions about the meal. You can ask about macros, diet suitability, or healthier swaps.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.role == MessageRole.user;
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.teal.withOpacity(0.15)
                              : (isDark ? Colors.white10 : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask about nutrition... ',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, size: 18),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum MessageRole { user, assistant }

class _ChatMessage {
  final MessageRole role;
  final String text;
  _ChatMessage({required this.role, required this.text});
}
