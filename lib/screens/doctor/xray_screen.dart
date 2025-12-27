import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/theme_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_app_bar.dart';
// =============================================================================
// X-RAY ANALYSIS SCREEN - MEDICAL IMAGE ANALYSIS
// =============================================================================
// Purpose: Upload and analyze X-ray images with AI assistance
// Features:
// - Camera capture - Take X-ray photos directly
// - Gallery upload - Select images from device storage
// - Image preview with full-screen display
// - AI Analysis button with simulated processing
// - Results display (Normal/Abnormal with confidence scores)
// - Mock AI recommendations based on analysis
// Technical Details:
// - Max image size: 10MB
// - Image quality: 85%
// - Supported sources: Camera, Gallery
// - Simulated analysis time: 3 seconds
// =============================================================================

/// X-Ray Analysis Screen for Doctor
class XrayScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const XrayScreen({super.key, this.onBack});

  @override
  State<XrayScreen> createState() => _XrayScreenState();
}

class _XrayScreenState extends State<XrayScreen> {
  File? _xrayImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _analysisStatus; // 'normal' or 'abnormal'
  

  Future<void> _pickXrayFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        final fileSize = await pickedFile.length();
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(
                'File size exceeds 10MB limit',
                'حجم الملف يتجاوز حد 10 ميجابايت',
              )),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _xrayImage = File(pickedFile.path);
          _analysisResult = null;
          _analysisStatus = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(
              'X-ray image uploaded successfully',
              'تم تحميل صورة الأشعة بنجاح',
            )),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            'Error picking image: $e',
            'خطأ في اختيار الصورة: $e',
          )),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureXrayWithCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        final fileSize = await pickedFile.length();
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(
                'File size exceeds 10MB limit',
                'حجم الملف يتجاوز حد 10 ميجابايت',
              )),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _xrayImage = File(pickedFile.path);
          _analysisResult = null;
          _analysisStatus = null;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(
              'X-ray image captured successfully',
              'تم التقاط صورة الأشعة بنجاح',
            )),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            'Error capturing image: $e',
            'خطأ في التقاط الصورة: $e',
          )),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  

  Future<void> _analyzeXray() async {
    if (_xrayImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(
            'Please upload or capture an X-ray image first',
            'يرجى تحميل أو التقاط صورة أشعة أولاً',
          )),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    // Simulate AI analysis - placeholder for later implementation
    await Future.delayed(const Duration(seconds: 3));

    // Mock AI response (random normal/abnormal for demo)
    final isNormal = DateTime.now().millisecond % 2 == 0;

    setState(() {
      _isAnalyzing = false;
      _analysisStatus = isNormal ? 'normal' : 'abnormal';
      _analysisResult = isNormal
          ? t(
              'The X-ray appears to be NORMAL. No significant abnormalities detected.',
              'تبدو الأشعة طبيعية. لم يتم الكشف عن أي تشوهات كبيرة.',
            )
          : t(
              'The X-ray appears to be ABNORMAL. Potential issues detected. Please review with patient.',
              'تبدو الأشعة غير طبيعية. تم الكشف عن مشاكل محتملة. يرجى المراجعة مع المريض.',
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: t('X-Ray Analysis', 'تحليل الأشعة السينية'),
        onBack: widget.onBack,
      ),
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Instructions
            Text(
              t('X-Ray Upload & Analysis', 'تحميل وتحليل الأشعة السينية'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t(
                'Upload or capture an X-ray image for AI-powered analysis',
                'قم بتحميل أو التقاط صورة أشعة لتحليل مدعوم بالذكاء الاصطناعي',
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 30),

            // Image Upload/Capture Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _xrayImage != null
                      ? const Color(0xFF00BCD4)
                      : (isDark ? Colors.white12 : Colors.grey[300]!),
                  width: 2,
                ),
              ),
              child: _xrayImage != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _xrayImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 300,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t('X-Ray Image Selected', 'تم اختيار صورة الأشعة'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _captureXrayWithCamera,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(t('Retake', 'إعادة التقاط')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00BCD4),
                                  side: const BorderSide(color: Color(0xFF00BCD4)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickXrayFromGallery,
                                icon: const Icon(Icons.image),
                                label: Text(t('Change', 'تغيير')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00BCD4),
                                  side: const BorderSide(color: Color(0xFF00BCD4)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          size: 80,
                          color: const Color(0xFF00BCD4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t('Upload X-Ray Image', 'قم بتحميل صورة الأشعة السينية'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('Choose from gallery or capture with camera', 'اختر من المعرض أو التقط باستخدام الكاميرا'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _captureXrayWithCamera,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0D1117)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.camera_alt,
                                        color: Color(0xFF00BCD4),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        t('Camera', 'الكاميرا'),
                                        style: const TextStyle(
                                          color: Color(0xFF00BCD4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickXrayFromGallery,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0D1117)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.image,
                                        color: Color(0xFF00BCD4),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        t('Gallery', 'المعرض'),
                                        style: const TextStyle(
                                          color: Color(0xFF00BCD4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 30),

            // Analyze Button
            if (_xrayImage != null)
              GradientButton(
                text: _isAnalyzing
                    ? t('Analyzing...', 'جاري التحليل...')
                    : t('Analyze', 'تحليل'),
                onPressed: _isAnalyzing ? () {} : _analyzeXray,
              ),
            const SizedBox(height: 30),

            // Analysis Results
            if (_analysisResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: _analysisStatus == 'normal'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _analysisStatus == 'normal'
                        ? Colors.green
                        : Colors.red,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _analysisStatus == 'normal'
                              ? Icons.check_circle
                              : Icons.warning_rounded,
                          color: _analysisStatus == 'normal'
                              ? Colors.green
                              : Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _analysisStatus == 'normal'
                                ? t('NORMAL', 'طبيعي')
                                : t('ABNORMAL', 'غير طبيعي'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _analysisStatus == 'normal'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _analysisResult!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0D1117)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t(
                          'AI-Powered Analysis v1.0 (Beta)\nAlways consult with medical professionals for final diagnosis.',
                          'تحليل مدعوم بالذكاء الاصطناعي v1.0 (إصدار تجريبي)\nتشاور دائماً مع المتخصصين الطبيين للتشخيص النهائي.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
