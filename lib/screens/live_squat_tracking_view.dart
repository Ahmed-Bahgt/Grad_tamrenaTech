import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/squat_logic.dart';
import '../widgets/pose_painter.dart';
import '../services/database_service.dart';
// Removed unused FirestoreRepository import

/// Live squat session page: camera stream -> ML Kit pose -> SquatLogic -> overlay
class LiveSquatSessionPage extends StatefulWidget {
  const LiveSquatSessionPage({super.key});

  @override
  State<LiveSquatSessionPage> createState() => _LiveSquatSessionPageState();
}

class _LiveSquatSessionPageState extends State<LiveSquatSessionPage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  bool _sessionActive = false;

  late final SquatLogic _squatLogic;
  SquatResult? _currentResult;
  List<Pose> _poses = [];
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _squatLogic = SquatLogic(mode: SquatMode.beginner, targetReps: 10, targetSets: 3);
    _initPoseDetector();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _initPoseDetector() async {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required')),
        );
      }
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    await _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _poseDetector == null || !_sessionActive) return;
    _isProcessing = true;

    try {
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) {
        setState(() {
          _poses = const [];
          _currentResult = _currentResult?.copyWith(
            jointsDetected: false,
            displayMessage: 'No person detected',
          );
        });
        _isProcessing = false;
        return;
      }

      final result = _squatLogic.processFrame(poses.first);
      if (!mounted) {
        _isProcessing = false;
        return;
      }

      setState(() {
        _poses = poses;
        _currentResult = result;
      });
    } catch (e) {
      debugPrint('[LiveSquatTrackingView] frame error: $e');
    }

    _isProcessing = false;
  }

  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final rotation = _inputImageRotation();
      if (rotation == null) return null;

      // Robust YUV420 -> bytes (Y, U, V planes concatenation)
      final bytes = _yuv420ToBytes(image);

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('[LiveSquatSession] conversion error: $e');
      return null;
    }
  }

  // Explicit rotation fix: use camera sensor orientation (per ML Kit guidance)
  InputImageRotation? _inputImageRotation() {
    if (_cameraController == null) return null;
    final sensor = _cameraController!.description.sensorOrientation;
    return InputImageRotationValue.fromRawValue(sensor);
  }

  // Convert CameraImage (YUV420) to a single byte array for ML Kit
  Uint8List _yuv420ToBytes(CameraImage image) {
    final bytesBuilder = BytesBuilder(copy: false);
    for (final Plane plane in image.planes) {
      bytesBuilder.add(plane.bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Widget build(BuildContext context) {
    final previewReady = _cameraController?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Squat Tracking'),
        backgroundColor: Colors.black,
      ),
      body: previewReady
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                if (_poses.isNotEmpty && (_currentResult?.jointsDetected ?? false))
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PosePainter(
                        poses: _poses,
                        imageSize: Size(
                          _cameraController!.value.previewSize!.height,
                          _cameraController!.value.previewSize!.width,
                        ),
                      ),
                    ),
                  ),
                // Minimal overlay: only display message when needed
                if ((_currentResult?.displayMessage ?? '').isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _currentResult!.displayMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildControlButton(),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  // Removed HUD and counters to keep UI minimal

  Widget _buildControlButton() {
    return ElevatedButton(
      onPressed: _sessionActive ? _endSession : _startSession,
      style: ElevatedButton.styleFrom(
        backgroundColor: _sessionActive ? Colors.red : Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        _sessionActive ? 'End Session' : 'Start Session',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _startSession() {
    _squatLogic.reset();
    setState(() {
      _sessionActive = true;
      _currentResult = null;
    });
  }

  void _endSession() {
    setState(() {
      _sessionActive = false;
    });
    sendReportToFirebase();
    _showSummaryDialog();
  }

  Future<void> sendReportToFirebase() async {
    if (_currentResult == null) return;

    final totalReps = _currentResult!.correctReps + _currentResult!.incorrectReps;
    final accuracy = totalReps > 0
        ? (_currentResult!.correctReps / totalReps * 100).toStringAsFixed(1)
        : '0.0';

    debugPrint('SQUAT SESSION REPORT');
    debugPrint('Correct: ${_currentResult!.correctReps}');
    debugPrint('Incorrect: ${_currentResult!.incorrectReps}');
    debugPrint('Total: $totalReps');
    debugPrint('Accuracy: $accuracy%');
    debugPrint('Sets: ${_currentResult!.currentSet}/${_squatLogic.targetSets}');
    debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');

    // Persist session under current user if signed in
    await _dbService.logWorkout(
      result: _currentResult!,
      targetSets: _squatLogic.targetSets,
    );
  }

  void _showSummaryDialog() {
    if (!mounted || _currentResult == null) return;
    final totalReps = _currentResult!.correctReps + _currentResult!.incorrectReps;
    final accuracy = totalReps > 0
        ? (_currentResult!.correctReps / totalReps * 100).toStringAsFixed(1)
        : '0.0';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Session Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correct reps: ${_currentResult!.correctReps}'),
              Text('Incorrect reps: ${_currentResult!.incorrectReps}'),
              Text('Total reps: $totalReps'),
              Text('Accuracy: $accuracy%'),
              Text('Sets: ${_currentResult!.currentSet}/${_squatLogic.targetSets}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

extension on SquatResult {
  SquatResult copyWith({
    bool? jointsDetected,
    String? displayMessage,
    bool? waitingForReset,
    int? messageTimer,
  }) {
    return SquatResult(
      correctReps: correctReps,
      incorrectReps: incorrectReps,
      currentSet: currentSet,
      feedback: feedback,
      isRepCounted: isRepCounted,
      kneeAngle: kneeAngle,
      hipAngle: hipAngle,
      ankleAngle: ankleAngle,
      currentState: currentState,
      sessionComplete: sessionComplete,
      jointsDetected: jointsDetected ?? this.jointsDetected,
      displayMessage: displayMessage ?? this.displayMessage,
      waitingForReset: waitingForReset ?? this.waitingForReset,
      messageTimer: messageTimer ?? this.messageTimer,
    );
  }
}
