import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/doctor_patient_chat_service.dart';
import '../../utils/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';

class DoctorPatientChatScreen extends StatefulWidget {
  final DoctorPatientChatContext chatContext;
  final VoidCallback? onBack;

  const DoctorPatientChatScreen({
    super.key,
    required this.chatContext,
    this.onBack,
  });

  @override
  State<DoctorPatientChatScreen> createState() =>
      _DoctorPatientChatScreenState();
}

class _DoctorPatientChatScreenState extends State<DoctorPatientChatScreen> {
  final DoctorPatientChatService _chatService = DoctorPatientChatService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterSoundRecord _recorder = FlutterSoundRecord();

  bool _isSending = false;
  bool _isRecording = false;
  int _recordingDurationMs = 0;
  Timer? _recordingTimer;
  int _lastRenderedCount = 0;

  bool get _currentUserIsDoctor {
    return FirebaseAuth.instance.currentUser?.uid ==
        widget.chatContext.doctorId;
  }

  String get _peerName {
    return _currentUserIsDoctor
        ? widget.chatContext.patientName
        : widget.chatContext.doctorName;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendTextMessage(
        doctorId: widget.chatContext.doctorId,
        patientId: widget.chatContext.patientId,
        text: text,
      );
      _messageController.clear();
      _scrollToBottomSoon();
    } catch (e) {
      _showSnack(
        t('Unable to send message', 'تعذر إرسال الرسالة'),
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendImageMessage(
        doctorId: widget.chatContext.doctorId,
        patientId: widget.chatContext.patientId,
        imageFile: image,
      );
      _scrollToBottomSoon();
    } catch (e) {
      debugPrint('[DoctorPatientChatScreen] send image error: $e');
      _showSnack(
        '${t('Unable to send image', 'تعذر إرسال الصورة')}: $e',
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ── Voice recording ─────────────────────────────────────────
  Future<void> _startRecording() async {
    if (_isSending || _isRecording) return;

    // Request mic permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showSnack(
        t('Microphone permission required', 'مطلوب صلاحية الميكروفون'),
        Colors.redAccent,
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        path: path,
        encoder: AudioEncoder.AAC,
        bitRate: 128000,
        samplingRate: 44100,
      );

      setState(() {
        _isRecording = true;
        _recordingDurationMs = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) {
          setState(() => _recordingDurationMs += 100);
        }
      });
    } catch (e) {
      debugPrint('[VoiceRecording] start error: $e');
      _showSnack(
        t('Failed to start recording', 'فشل بدء التسجيل'),
        Colors.redAccent,
      );
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    final duration = _recordingDurationMs;

    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path == null || duration < 500) {
        // Too short, discard
        return;
      }

      setState(() => _isSending = true);

      await _chatService.sendVoiceMessage(
        doctorId: widget.chatContext.doctorId,
        patientId: widget.chatContext.patientId,
        filePath: path,
        durationMs: duration,
      );
      _scrollToBottomSoon();
    } catch (e) {
      debugPrint('[VoiceRecording] send error: $e');
      _showSnack(
        t('Failed to send voice note', 'فشل إرسال الرسالة الصوتية'),
        Colors.redAccent,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    if (mounted) setState(() => _isRecording = false);
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: _peerName,
        onBack: widget.onBack,
      ),
      backgroundColor:
          isDark ? AppTheme.bg(isDark) : const Color(0xFFF5F9FC),
      body: Column(
        children: [
          _chatHeader(isDark),
          Expanded(
            child: StreamBuilder<List<DoctorPatientChatMessage>>(
              stream: _chatService.watchMessages(
                doctorId: widget.chatContext.doctorId,
                patientId: widget.chatContext.patientId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    reverse: true,
                    itemCount: 5,
                    itemBuilder: (_, i) => _SkeletonBubble(fromMe: i.isEven),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        t('Unable to load chat', 'تعذر تحميل المحادثة'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? const [];
                if (messages.length != _lastRenderedCount) {
                  _lastRenderedCount = messages.length;
                  _scrollToBottomSoon();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      t('No messages yet. Start the conversation.',
                          'لا توجد رسائل بعد. ابدأ المحادثة.'),
                      style: TextStyle(
                        color: AppTheme.sub(isDark),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId ==
                        FirebaseAuth.instance.currentUser?.uid;
                    return _messageBubble(message, isMine, isDark);
                  },
                );
              },
            ),
          ),
          _composer(isDark),
        ],
      ),
    );
  }

  Widget _chatHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFDCE9F2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.12),
            child:
                const Icon(Icons.chat_bubble_outline, color: Color(0xFF00BCD4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _peerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF12344D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUserIsDoctor
                      ? t('Patient chat', 'محادثة مع المريض')
                      : t('Assigned doctor chat', 'محادثة مع الطبيب المعالج'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.sub(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(
    DoctorPatientChatMessage message,
    bool isMine,
    bool isDark,
  ) {
    final bubbleColor = isMine
        ? const Color(0xFF00BCD4)
        : (AppTheme.card(isDark));
    final textColor =
        isMine ? Colors.white : (AppTheme.text(isDark));

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isMine
              ? null
              : Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFDCE9F2),
                ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.sub(isDark),
                  ),
                ),
              ),
            if (message.isVoice) _VoicePlayerWidget(
              message: message,
              isMine: isMine,
              isDark: isDark,
            ),
            if (message.isImage) _buildImage(message, isDark, textColor),
            if (!message.isVoice && message.text.trim().isNotEmpty) ...[
              if (message.isImage) const SizedBox(height: 8),
              Text(
                message.text,
                style: TextStyle(color: textColor, height: 1.35),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _formatTime(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? Colors.white70
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(
    DoctorPatientChatMessage message,
    bool isDark,
    Color textColor,
  ) {
    return FutureBuilder<Uint8List?>(
      future: _resolveImageBytes(message),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 220,
            height: 220,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _imageUnavailable(isDark, textColor);
        }

        return GestureDetector(
          onTap: () => _openImageViewer(bytes),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              _memoryImage(bytes, isDark, textColor),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t('Tap to open', 'اضغط للفتح'),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Uint8List?> _resolveImageBytes(
      DoctorPatientChatMessage message) async {
    if (message.imageBase64.isNotEmpty) {
      try {
        return base64Decode(message.imageBase64);
      } catch (_) {
        return null;
      }
    }

    if (message.imageUrl.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(message.imageUrl));
        if (res.statusCode == 200) return res.bodyBytes;
      } catch (_) {}
    }

    if (message.imagePath.isEmpty) return null;

    try {
      final bucket = message.imageBucket.trim();
      final ref = bucket.isNotEmpty
          ? FirebaseStorage.instanceFor(
              bucket: bucket.startsWith('gs://') ? bucket : 'gs://$bucket',
            ).ref(message.imagePath)
          : FirebaseStorage.instance.ref(message.imagePath);

      final bytes = await ref.getData(15 * 1024 * 1024);
      if (bytes != null && bytes.isNotEmpty) return bytes;

      final url = await ref.getDownloadURL();
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}

    return null;
  }

  Future<void> _openImageViewer(Uint8List imageBytes) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatImagePreviewScreen(
          imageBytes: imageBytes,
          onSave: _saveImageToDevice,
        ),
      ),
    );
  }

  Future<void> _saveImageToDevice(Uint8List imageBytes) async {
    try {
      if (!await _ensureSavePermission()) {
        _showSnack(
          t('Permission required to save image', 'مطلوب صلاحية لحفظ الصورة'),
          Colors.redAccent,
        );
        return;
      }

      await Gal.putImageBytes(imageBytes);
      _showSnack(
        t('Image saved successfully', 'تم حفظ الصورة بنجاح'),
        Colors.green,
      );
    } catch (e) {
      _showSnack(
        '${t('Unable to save image', 'تعذر حفظ الصورة')}: $e',
        Colors.redAccent,
      );
    }
  }

  Future<bool> _ensureSavePermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return true;
    }

    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;

      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;

      final manage = await Permission.manageExternalStorage.request();
      return manage.isGranted;
    }

    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) return true;

    return false;
  }

  Widget _memoryImage(Uint8List bytes, bool isDark, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        bytes,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageUnavailable(isDark, textColor),
      ),
    );
  }

  Widget _imageUnavailable(bool isDark, Color textColor) {
    return Container(
      width: 220,
      height: 120,
      color: isDark ? Colors.black26 : Colors.black12,
      alignment: Alignment.center,
      child: Text(
        t('Image unavailable', 'تعذر تحميل الصورة'),
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _composer(bool isDark) {
    // Recording UI
    if (_isRecording) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: AppTheme.card(isDark),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFDCE9F2),
              ),
            ),
          ),
          child: Row(
            children: [
              // Cancel button
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
              const SizedBox(width: 8),
              // Recording indicator
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordingDurationMs),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text(isDark),
                ),
              ),
              const Spacer(),
              Text(
                t('Recording...', 'جاري التسجيل...'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.sub(isDark),
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF00BCD4),
                child: IconButton(
                  onPressed: _stopAndSendRecording,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal composer
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: AppTheme.card(isDark),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFDCE9F2),
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _isSending ? null : _pickAndSendImage,
              icon: const Icon(Icons.image_outlined),
              color: const Color(0xFF00BCD4),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: t('Write a message...', 'اكتب رسالة...'),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.bg(isDark)
                      : const Color(0xFFF5F9FC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Mic button
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopAndSendRecording(),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF00BCD4).withValues(alpha: 0.12),
                child: Icon(
                  Icons.mic,
                  color: _isSending ? Colors.grey : const Color(0xFF00BCD4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF00BCD4),
              child: IconButton(
                onPressed: _isSending ? null : _sendText,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return DateFormat('h:mm a').format(dateTime);
  }
}

class _ChatImagePreviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<void> Function(Uint8List imageBytes) onSave;

  const _ChatImagePreviewScreen({
    required this.imageBytes,
    required this.onSave,
  });

  @override
  State<_ChatImagePreviewScreen> createState() =>
      _ChatImagePreviewScreenState();
}

class _ChatImagePreviewScreenState extends State<_ChatImagePreviewScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                    });
                    await widget.onSave(widget.imageBytes);
                    if (mounted) {
                      setState(() {
                        _saving = false;
                      });
                    }
                  },
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _SkeletonBubble extends StatefulWidget {
  final bool fromMe;
  const _SkeletonBubble({required this.fromMe});

  @override
  State<_SkeletonBubble> createState() => _SkeletonBubbleState();
}

class _SkeletonBubbleState extends State<_SkeletonBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF21262D) : Colors.grey.shade200;
    final shimmer = isDark ? const Color(0xFF30363D) : Colors.grey.shade300;

    return Align(
      alignment: widget.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final color = Color.lerp(base, shimmer, _anim.value)!;
            return Container(
              width: 160 + (widget.fromMe ? 0 : 40),
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(widget.fromMe ? 14 : 2),
                  bottomRight: Radius.circular(widget.fromMe ? 2 : 14),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Voice player widget for voice note messages
// ═══════════════════════════════════════════════════════════════════
class _VoicePlayerWidget extends StatefulWidget {
  final DoctorPatientChatMessage message;
  final bool isMine;
  final bool isDark;

  const _VoicePlayerWidget({
    required this.message,
    required this.isMine,
    required this.isDark,
  });

  @override
  State<_VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<_VoicePlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _downloadedUrl;

  @override
  void initState() {
    super.initState();
    _duration = Duration(milliseconds: widget.message.voiceDurationMs);

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted && dur.inMilliseconds > 0) {
        setState(() => _duration = dur);
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    debugPrint('[VoicePlayer] _togglePlay called. isPlaying: $_isPlaying, hasBase64: ${widget.message.imageBase64.isNotEmpty}, hasUrl: ${_downloadedUrl != null}');
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (_downloadedUrl != null || widget.message.imageBase64.isNotEmpty) {
      if (widget.message.imageBase64.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/voice_${widget.message.id}.m4a');
          debugPrint('[VoicePlayer] decoding base64 to local file: ${file.path}');
          if (!file.existsSync()) {
            final bytes = base64Decode(widget.message.imageBase64);
            await file.writeAsBytes(bytes);
            debugPrint('[VoicePlayer] wrote file, size: ${bytes.length} bytes');
          } else {
            debugPrint('[VoicePlayer] file already exists');
          }
          await _player.play(DeviceFileSource(file.path));
          debugPrint('[VoicePlayer] play called successfully');
        } catch (e) {
          debugPrint('[VoicePlayer] error playing base64 file: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        await _player.resume();
      }
      return;
    }

    // Download and play
    setState(() => _isLoading = true);
    try {
      debugPrint('[VoicePlayer] trying to download from Firebase Storage: ${widget.message.voicePath}');
      final bucket = widget.message.voiceBucket.trim();
      final ref = bucket.isNotEmpty
          ? FirebaseStorage.instanceFor(
              bucket: bucket.startsWith('gs://') ? bucket : 'gs://$bucket',
            ).ref(widget.message.voicePath)
          : FirebaseStorage.instance.ref(widget.message.voicePath);

      final url = await ref.getDownloadURL();
      _downloadedUrl = url;
      debugPrint('[VoicePlayer] downloaded URL: $url');
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('[VoicePlayer] storage error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isMine ? Colors.white : const Color(0xFF00BCD4);
    final barBg = widget.isMine
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFF00BCD4).withValues(alpha: 0.2);
    final barActive = widget.isMine ? Colors.white : const Color(0xFF00BCD4);
    final textColor = widget.isMine
        ? Colors.white70
        : (widget.isDark ? Colors.white54 : Colors.black45);

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _isLoading ? null : _togglePlay,
          child: _isLoading
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                )
              : Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 36,
                  color: iconColor,
                ),
        ),
        const SizedBox(width: 8),
        // Progress bar + duration
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: barBg,
                  valueColor: AlwaysStoppedAnimation<Color>(barActive),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isPlaying || _position.inMilliseconds > 0
                    ? '${_fmt(_position)} / ${_fmt(_duration)}'
                    : _fmt(_duration),
                style: TextStyle(fontSize: 11, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
