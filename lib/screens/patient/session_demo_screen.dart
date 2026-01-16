import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

  final Map<String, String> _trainingTypes = {'Squat': 'squat'};
  final Map<String, String> _formOptions = {'Correct': 'correct', 'Incorrect': 'incorrect'};

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

  String _buildVideoPath() {
    final shortName = (_trainingTypes[_selectedTraining] ?? 'squat').toLowerCase();
    final formName = (_formOptions[_selectedForm] ?? 'correct').toLowerCase();
    // Strictly lowercase to match file system
    final videoPath = 'assets/videos/${shortName}_$formName.mp4';
    return videoPath;
  }

  Future<void> _initializeVideo() async {
    if (_isLoading) return;

    // Update UI to show loading state
    setState(() {
      _isLoading = true;
      _isVideoInitialized = false;
      _errorMessage = null;
    });

    try {
      // Explicitly dispose old controller to prevent memory leaks
      if (_videoController != null) {
        await _videoController!.dispose();
      }
      _videoController = null;

      // Small delay to allow disposal to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Build video path (strictly lowercase)
      final videoPath = _buildVideoPath();
      print('🎬 Video Path: $videoPath');

      // Create new controller from asset
      _videoController = VideoPlayerController.asset(videoPath);

      // Explicitly initialize and wait for completion
      try {
        await _videoController!.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('❌ Video initialization timeout for: $videoPath');
            throw Exception('Video initialization timeout after 15 seconds');
          },
        );
        print('✅ Video initialized successfully: $videoPath');
      } catch (initError) {
        print('❌ Initialization error for $videoPath: $initError');
        rethrow;
      }

      // Check if widget is still mounted before setState
      if (!mounted) {
        print('⚠️ Widget unmounted during initialization');
        return;
      }

      // Update UI with successful initialization
      setState(() {
        _isVideoInitialized = true;
        _isLoading = false;
        _errorMessage = null;
      });

      // Configure playback settings
      try {
        await _videoController!.setLooping(true);
        await _videoController!.play();
        print('▶️ Video playback started - looping enabled');
      } catch (playError) {
        print('❌ Playback error: $playError');
        throw Exception('Failed to start playback: $playError');
      }
    } catch (e, stackTrace) {
      // Log full error details for debugging
      print('❌ Video initialization failed');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = false;
        _isLoading = false;
        _errorMessage = 'Video playback failed. Check logs for details. Error: ${e.toString()}';
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
            'AI Fitness Trainer — Form Examples',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Dropdowns
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Training type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedTraining,
                      items: _trainingTypes.keys.toList(),
                      onChanged: (v) {
                        setState(() => _selectedTraining = v ?? 'Squat');
                        _initializeVideo();
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Form',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedForm,
                      items: _formOptions.keys.toList(),
                      onChanged: (v) {
                        setState(() => _selectedForm = v ?? 'Correct');
                        _initializeVideo();
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Example — $_selectedTraining · $_selectedForm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildVideoContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading video...', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
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
              Icon(Icons.info_outline, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Video Unavailable',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Device codec error',
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
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isVideoInitialized && _videoController != null && _videoController!.value.isInitialized) {
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
              backgroundColor: Colors.black54,
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: Icon(
                _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 64, color: isDark ? Colors.white30 : Colors.black26),
          const SizedBox(height: 16),
          Text('Ready to play', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeVideo,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Load Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
        onChanged: onChanged,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      ),
    );
  }
}
