// =============================================================================
// NUTRITION SCREEN - IMAGE-BASED FOOD ANALYSIS
// =============================================================================
// Purpose: Dedicated screen for analyzing food photos and viewing nutrition
// Features:
// - Upload food photos for analysis
// - Display comprehensive nutrition facts
// - Per-ingredient breakdown
// - Quick nutritionist recommendations
// =============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/theme_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/edamam_service.dart';

class NutritionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const NutritionScreen({super.key, this.onBack});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  late GeminiService _geminiService;
  late EdamamService _edamamService;

  bool _isAnalyzing = false;
  NutritionResult? _currentResult;
  String? _currentIngredientsText;
  File? _currentImageFile;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _edamamService = EdamamService();
  }

  @override
  void dispose() {
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
    setState(() {
      _isAnalyzing = true;
      _currentImageFile = File(imagePath);
    });

    try {
      // Step 1: Extract ingredients
      debugPrint('[Nutrition] 🔍 Extracting ingredients from image...');
      final ingredientsText =
          await _geminiService.extractIngredientsFromImageFile(File(imagePath));

      if (!mounted) return;

      debugPrint('[Nutrition] ✓ Detected ingredients: $ingredientsText');
      _currentIngredientsText = ingredientsText;

      // Step 2: Get nutrition facts
      debugPrint('[Nutrition] 📊 Calling Edamam API...');
      final result = await _edamamService.getNutritionFacts(ingredientsText);

      if (!mounted) return;

      if (result == null) {
        throw Exception(
            'Could not retrieve nutrition data. Ensure ingredients include quantities.');
      }

      _currentResult = result;
      debugPrint('[Nutrition] ✓ Got nutrition facts');

      setState(() => _isAnalyzing = false);
      _scrollToBottom();
    } catch (e) {
      debugPrint('[Nutrition] ❌ Error: $e');
      if (!mounted) return;

      setState(() => _isAnalyzing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            'Analysis failed: $e',
            'فشل التحليل: $e',
          )),
          duration: const Duration(seconds: 4),
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
              t('Food Analysis', 'تحليل الطعام'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            if (_currentImageFile != null) ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey[300]!,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _currentImageFile!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: isDark ? Colors.white30 : Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('Upload a food photo', 'قم بتحميل صورة طعام'),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _captureImageWithCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(t('Camera', 'الكاميرا')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: Text(t('Gallery', 'المعرض')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            if (_isAnalyzing) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF8BC34A),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('Analyzing...', 'جاري التحليل...'),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Results
            if (_currentResult != null && !_isAnalyzing) ...[
              const SizedBox(height: 24),
              _buildNutritionFactsCard(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionFactsCard(bool isDark) {
    final result = _currentResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ingredients
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Detected Ingredients', 'المكونات المكتشفة'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8BC34A),
                    ),
              ),
              const SizedBox(height: 12),
              if (_currentIngredientsText != null)
                Text(
                  _currentIngredientsText!,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nutrition Facts Table
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Nutrition Facts', 'الحقائق الغذائية'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8BC34A),
                    ),
              ),
              const SizedBox(height: 16),
              _buildNutrientRow(
                '⚡ Calories',
                result.calories?.toStringAsFixed(0) ?? 'N/A',
                'kcal',
                result.nutrients['ENERC_KCAL'],
                isDark,
              ),
              _buildNutrientRow(
                '🥩 Protein',
                result.protein?.toStringAsFixed(1) ?? 'N/A',
                'g',
                result.nutrients['PROCNT'],
                isDark,
              ),
              _buildNutrientRow(
                '🍞 Carbs',
                result.carbs?.toStringAsFixed(1) ?? 'N/A',
                'g',
                result.nutrients['CHOCDF'],
                isDark,
              ),
              _buildNutrientRow(
                '🧈 Fat',
                result.fat?.toStringAsFixed(1) ?? 'N/A',
                'g',
                result.nutrients['FAT'],
                isDark,
              ),
              _buildNutrientRow(
                '🌾 Fiber',
                result.fiber?.toStringAsFixed(1) ?? 'N/A',
                'g',
                result.nutrients['FIBTG'],
                isDark,
              ),
              _buildNutrientRow(
                '🧂 Sodium',
                result.sodium?.toStringAsFixed(0) ?? 'N/A',
                'mg',
                result.nutrients['NA'],
                isDark,
              ),
            ],
          ),
        ),

        // Per-ingredient breakdown
        if (result.ingredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Per-Ingredient Breakdown', 'تفصيل المكونات'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8BC34A),
                      ),
                ),
                const SizedBox(height: 12),
                ...result.ingredients.take(5).map((ing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ing.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ing.calories.toStringAsFixed(0)} cal • P: ${ing.protein.toStringAsFixed(1)}g C: ${ing.carbs.toStringAsFixed(1)}g F: ${ing.fat.toStringAsFixed(1)}g',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNutrientRow(
    String label,
    String value,
    String unit,
    NutrientData? nutrient,
    bool isDark,
  ) {
    final dv = nutrient?.dailyValuePercent ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value $unit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (dv > 0)
                Text(
                  '${dv.toStringAsFixed(0)}% DV',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
