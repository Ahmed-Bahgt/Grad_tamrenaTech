import 'package:flutter/material.dart';
import '../../utils/theme_provider.dart';
import 'session_demo_screen.dart';
import 'session_live_stream_screen.dart';
import 'session_upload_video_screen.dart';

/// Start Session Screen - Main hub with 3 tabs for session training
class StartSessionScreen extends StatefulWidget {
  final String planName;
  final VoidCallback? onBack;

  const StartSessionScreen({
    super.key,
    required this.planName,
    this.onBack,
  });

  @override
  State<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends State<StartSessionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('Today\'s Session', 'جلسة اليوم')),
            Text(
              widget.planName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.video_library),
              text: t('Demo', 'عرض توضيحي'),
            ),
            Tab(
              icon: const Icon(Icons.videocam),
              text: t('Live Stream', 'بث مباشر'),
            ),
            Tab(
              icon: const Icon(Icons.upload_file),
              text: t('Upload Video', 'رفع فيديو'),
            ),
          ],
        ),
      ),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Demo
          SessionDemoScreen(onBack: widget.onBack),

          // Tab 2: Live Stream
          SessionLiveStreamScreen(onBack: widget.onBack),

          // Tab 3: Upload Video
          SessionUploadVideoScreen(onBack: widget.onBack),
        ],
      ),
    );
  }
}
