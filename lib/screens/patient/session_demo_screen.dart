import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../utils/theme_provider.dart';

/// Demo Screen - Shows example videos (matching Demo.py)
class SessionDemoScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SessionDemoScreen({super.key, this.onBack});

  @override
  State<SessionDemoScreen> createState() => _SessionDemoScreenState();
}

class _SessionDemoScreenState extends State<SessionDemoScreen> {
  String _selectedTraining = 'Squat';
  String _selectedForm = 'Correct';
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _trainingTypes = {
    'Squat': 'squat',
    'Lunge': 'lunge',
    'Deadlift': 'deadlift',
  };

  final Map<String, String> _formOptions = {
    'Correct': 'correct',
    'Incorrect': 'incorrect',
  };

  String _buildVideoPath() {
    final shortName = _trainingTypes[_selectedTraining] ?? 'squat';
    final formName = _formOptions[_selectedForm] ?? 'correct';
    return 'assets/${shortName}_$formName.mp4';
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_isLoading) return; // Prevent multiple simultaneous initializations

    setState(() {
      _isLoading = true;
      _isVideoInitialized = false;
      _errorMessage = null;
    });

    final videoPath = _buildVideoPath();

    try {
      // Dispose old controller first
      await _videoController?.pause();
      await _videoController?.dispose();
      _videoController = null;

      // Small delay to ensure cleanup completes
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new controller
      _videoController = VideoPlayerController.asset(videoPath);

      // Initialize with timeout
      await _videoController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
        _isLoading = false;
      });

      // Start playing
      await _videoController!.setLooping(true);
      await _videoController!.play();

      debugPrint('[DemoScreen] Video initialized successfully: $videoPath');
    } catch (e) {
      debugPrint('[DemoScreen] Error loading video: $e');
      debugPrint('[DemoScreen] Video path attempted: $videoPath');

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = false;
        _isLoading = false;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });

      // Clean up on error
      _videoController?.dispose();
      _videoController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('AI Fitness Trainer — Form Examples',
                'مدرب اللياقة الذكي - أمثلة على الوضعية'),
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Training type', 'نوع التمرين'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                        value: _selectedTraining,
                        items: _trainingTypes.keys.toList(),
                        onChanged: (value) {
                          setState(() => _selectedTraining = value ?? 'Squat');
                          _initializeVideo();
                        },
                        isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Form', 'الوضعية'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                        value: _selectedForm,
                        items: _formOptions.keys.toList(),
                        onChanged: (value) {
                          setState(() => _selectedForm = value ?? 'Correct');
                          _initializeVideo();
                        },
                        isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
              t('Example — $_selectedTraining · $_selectedForm',
                  'مثال — $_selectedTraining · $_selectedForm'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildVideoWidget(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoWidget(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              t('Loading video...', 'جاري تحميل الفيديو...'),
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                t('Failed to load video', 'فشل تحميل الفيديو'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: const Icon(Icons.refresh),
                label: Text(t('Retry', 'إعادة المحاولة')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isVideoInitialized &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          Positioned(
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              backgroundColor: Colors.black54,
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Default state - show play button
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            t('Tap to play video', 'اضغط لتشغيل الفيديو'),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeVideo,
            icon: const Icon(Icons.play_arrow),
            label: Text(t('Play Video', 'تشغيل الفيديو')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF64B5F6).withOpacity(0.3),
              ),
            ),
            child: Text(
              t('Video: ${_buildVideoPath()}', 'الفيديو: ${_buildVideoPath()}'),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64B5F6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      {required String value,
      required List<String> items,
      required Function(String?) onChanged,
      required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!)),
      child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 14),
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList()),
    );
  }
}
