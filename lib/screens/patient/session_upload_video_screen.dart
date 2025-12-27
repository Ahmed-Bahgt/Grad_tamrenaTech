import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/theme_provider.dart';

/// Upload Video Screen - Offline video analysis
class SessionUploadVideoScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SessionUploadVideoScreen({super.key, this.onBack});

  @override
  State<SessionUploadVideoScreen> createState() =>
      _SessionUploadVideoScreenState();
}

class _SessionUploadVideoScreenState extends State<SessionUploadVideoScreen> {
  String? _selectedFile;
  String _selectedTraining = 'Squat';
  String _selectedMode = 'Beginner';
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  bool _processingComplete = false;

  static const int _maxFileSizeBytes = 300 * 1024 * 1024; // 300MB limit

  final List<String> _trainingTypes = ['Squat', 'Lunge', 'Deadlift'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Form Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Upload & Analyze', 'تحميل وتحليل'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Training Type Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Training Type', 'نوع التمرين'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1F26)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTraining,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor:
                            isDark ? const Color(0xFF161B22) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTraining = value);
                          }
                        },
                        items: _trainingTypes
                            .map((training) => DropdownMenuItem(
                                  value: training,
                                  child: Text(training),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mode Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Difficulty Mode', 'مستوى الصعوبة'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _modeButton('Beginner',
                              _selectedMode == 'Beginner',
                              () => setState(() => _selectedMode = 'Beginner')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _modeButton('Pro', _selectedMode == 'Pro',
                              () => setState(() => _selectedMode = 'Pro')),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Upload & Processing Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_isProcessing && !_processingComplete)
                  // Upload Button
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D1117)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey[300]!,
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: isDark
                                  ? Colors.white30
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t(
                                'Select Video File',
                                'اختر ملف الفيديو',
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t(
                                'MP4, MOV, AVI, MKV (Max 300MB)',
                                'MP4، MOV، AVI، MKV (الحد الأقصى 300 ميجابايت)',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // File Input Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: Text(
                            t(
                              _selectedFile != null
                                  ? 'Change File'
                                  : 'Choose File',
                              _selectedFile != null
                                  ? 'تغيير الملف'
                                  : 'اختر ملف',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF64B5F6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showFileSourceSheet,
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t(
                              'Selected: ${_fileNameFromPath(_selectedFile!)}',
                              'المحدد: ${_fileNameFromPath(_selectedFile!)}',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                else if (_isProcessing)
                  // Processing Progress
                  Column(
                    children: [
                      Text(
                        t('Processing Video...', 'معالجة الفيديو...'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _processingProgress,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF64B5F6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_processingProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1F26)
                              : Colors.grey[100],
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _statusRow(
                              'Training',
                              _selectedTraining,
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              'Mode',
                              _selectedMode,
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              'File',
                              _selectedFile != null
                                  ? _fileNameFromPath(_selectedFile!)
                                  : 'No file',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Processing Complete
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t(
                                'Analysis Complete!',
                                'اكتمل التحليل!',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(
                                'Your exercise analysis is ready to download',
                                'تحليل التمرين جاهز للتنزيل',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isProcessing = false;
                                  _processingComplete = false;
                                  _selectedFile = null;
                                  _processingProgress = 0.0;
                                });
                              },
                              style: OutlinedButton
                                  .styleFrom(
                                padding: const EdgeInsets
                                    .symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                ),
                              ),
                              child: Text(
                                t(
                                  'Upload Another',
                                  'تحميل آخر',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons
                                  .download_outlined),
                              label: Text(
                                t(
                                  'Download',
                                  'تحميل',
                                ),
                              ),
                              style: ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                    Colors.green,
                                padding: const EdgeInsets
                                    .symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(
                                    context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t(
                                        'Download feature coming soon',
                                        'جاري التنزيل...',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Analyze Button (only show when file selected and not processing)
          if (_selectedFile != null &&
              !_isProcessing &&
              !_processingComplete)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isProcessing = true;
                      _processingProgress = 0.0;
                    });
                    // Simulate processing with progress animation
                    Future.delayed(const Duration(milliseconds: 100),
                        () {
                      _simulateProcessing();
                    });
                  },
                  child: Text(
                    t('Analyze Video', 'تحليل الفيديو'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF64B5F6)
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    t(
                      '📹 Video Requirements',
                      '📹 متطلبات الفيديو',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64B5F6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(
                      '• Formats: MP4, MOV, AVI, MKV\n• Max size: 300MB\n• Clear view of full body\n• Minimum 30 seconds',
                      '• الصيغ: MP4، MOV، AVI، MKV\n• الحد الأقصى: 300 ميجابايت\n• عرض واضح للجسم بالكامل\n• 30 ثانية على الأقل',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white70
                          : Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFileSourceSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: Text(t('Pick from Gallery', 'اختر من المعرض')),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(t('Browse Files', 'تصفح الملفات')),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickFromFiles();
                },
              ),
              const SizedBox(height: 8),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  t('Max size 300MB • MP4/MOV/AVI/MKV', 'الحد الأقصى 300 ميجابايت • MP4/MOV/AVI/MKV'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await _handleSelectedFile(picked.path);
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _handleSelectedFile(path);
  }

  Future<void> _handleSelectedFile(String path) async {
    try {
      final file = File(path);
      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('File is larger than 300MB', 'الملف أكبر من 300 ميجابايت'),
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedFile = path;
        _isProcessing = false;
        _processingComplete = false;
        _processingProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Video selected: ${_fileNameFromPath(path)}', 'تم اختيار الفيديو: ${_fileNameFromPath(path)}'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Failed to load file', 'فشل تحميل الملف'),
          ),
        ),
      );
    }
  }

  String _fileNameFromPath(String path) {
    if (path.isEmpty) return 'video';
    final separatorIndex = path.lastIndexOf(Platform.pathSeparator);
    if (separatorIndex == -1) return path;
    return path.substring(separatorIndex + 1);
  }

  Widget _modeButton(String label, bool isSelected,
      VoidCallback onTap) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF64B5F6)
              : (isDark
                  ? const Color(0xFF1C1F26)
                  : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF64B5F6)
                : (isDark
                    ? Colors.white12
                    : Colors.grey[300]!),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusRow(
      String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color:
                isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _simulateProcessing() async {
    for (int i = 0; i <= 100; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        _processingProgress = i / 100;
      });
    }
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _processingComplete = true;
      });
    }
  }
}
