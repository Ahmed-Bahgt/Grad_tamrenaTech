import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Demo Screen - Shows example videos using YouTube (matching Demo.py)
class SessionDemoScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SessionDemoScreen({super.key, this.onBack});

  @override
  State<SessionDemoScreen> createState() => _SessionDemoScreenState();
}

class _SessionDemoScreenState extends State<SessionDemoScreen> {
  String _selectedTraining = 'Squat';
  String _selectedForm = 'Correct';
  YoutubePlayerController? _videoController;
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, String> _trainingTypes = {'Squat': 'squat'};
  final Map<String, String> _formOptions = {'Correct': 'correct', 'Incorrect': 'incorrect'};

  /// YouTube Video IDs mapping
  final Map<String, String> _videoIdMap = {
    'squat_correct': 'NjCrfSkrxDI',
    'squat_incorrect': 'rS-nhzFEeLg',
  };

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _getVideoId() {
    final shortName = (_trainingTypes[_selectedTraining] ?? 'squat').toLowerCase();
    final formName = (_formOptions[_selectedForm] ?? 'correct').toLowerCase();
    final key = '${shortName}_$formName';
    return _videoIdMap[key] ?? 'NjCrfSkrxDI'; // Default to correct squat
  }

  void _setupController() {
    final videoId = _getVideoId();
    _videoController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        loop: true,
        forceHD: false,
        useHybridComposition: true,
        controlsVisibleAtStart: false,
      ),
    );
  }

  Future<void> _loadSelectedVideo() async {
    if (_videoController == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final videoId = _getVideoId();
    try {
      _videoController!.load(videoId);
    } catch (e, stackTrace) {
      print('❌ Video load failed');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Video playback failed. Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                        _loadSelectedVideo();
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
                        _loadSelectedVideo();
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
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildVideoContent(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(bool isDark) {
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
                _errorMessage ?? 'Network error',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadSelectedVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_videoController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            YoutubePlayer(
              controller: _videoController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
            onPressed: _loadSelectedVideo,
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
