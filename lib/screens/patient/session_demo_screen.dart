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
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    setState(() => _isVideoInitialized = false);

    final videoPath = _buildVideoPath();

    // Dispose old controller if exists so we don't leak resources when switching videos
    _videoController?.dispose();

    try {
      _videoController = VideoPlayerController.asset(videoPath);
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController!.play();
      // Loop the video
      _videoController!.setLooping(true);
    } catch (e) {
      debugPrint('Error loading video: $e');
      setState(() {
        _isVideoInitialized = false;
      });
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
            t('AI Fitness Trainer — Form Examples', 'مدرب اللياقة الذكي - أمثلة على الوضعية'),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Training type', 'نوع التمرين'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    _buildDropdown(value: _selectedTraining, items: _trainingTypes.keys.toList(), onChanged: (value) {
                      setState(() => _selectedTraining = value ?? 'Squat');
                      _initializeVideo();
                    }, isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Form', 'الوضعية'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    _buildDropdown(value: _selectedForm, items: _formOptions.keys.toList(), onChanged: (value) {
                      setState(() => _selectedForm = value ?? 'Correct');
                      _initializeVideo();
                    }, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(t('Example — $_selectedTraining · $_selectedForm', 'مثال — $_selectedTraining · $_selectedForm'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!)),
            child: _isVideoInitialized && _videoController != null
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      FloatingActionButton(
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
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline, size: 64, color: isDark ? Colors.white30 : Colors.black26),
                        const SizedBox(height: 16),
                        Text(t('Loading video...', 'جاري تحميل الفيديو...'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                          onPressed: _initializeVideo,
                          icon: const Icon(Icons.play_circle_fill, size: 18),
                          label: Text(t('Preview video', 'معاينة الفيديو')), 
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF64B5F6).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF64B5F6).withOpacity(0.3))),
                          child: Text(t('Ensure video files exist in assets/\n(squat_correct.mp4, squat_incorrect.mp4, etc.)', 'تأكد من وجود ملفات الفيديو في مجلد assets/'), style: const TextStyle(fontSize: 11, color: Color(0xFF64B5F6)), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!)),
      child: DropdownButton<String>(value: value, isExpanded: true, underline: const SizedBox(), dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14), onChanged: onChanged, items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList()),
    );
  }
}
