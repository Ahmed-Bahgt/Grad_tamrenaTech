import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/theme_provider.dart';
import '../../utils/squat_logic.dart';
import '../../utils/squat_processor.dart';
import '../../utils/pose_analyzer.dart';
import '../../widgets/pose_painter.dart';
import '../../utils/patient_profile_manager.dart';

/// Live Stream Screen matching Live_Stream.py logic
class SessionLiveStreamScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SessionLiveStreamScreen({super.key, this.onBack});

  @override
  State<SessionLiveStreamScreen> createState() =>
      _SessionLiveStreamScreenState();
}

class _SessionLiveStreamScreenState extends State<SessionLiveStreamScreen> {
  String _selectedMode = 'Beginner';
  int _targetReps = 10;
  int _targetSets = 3;
  String _assignedExercise = '';
  bool _isStreamActive = false;
  bool _isProcessing = false;
  bool _calibrating = false;
  int _calibrationCounter = 0;
  List<Pose> _poses = [];

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  PoseDetector? _poseDetector;
  late SquatProcessor _squatProcessor;
  SquatResult? _lastResult;
  String? _selectedSide; // 'left' or 'right' based on shoulder-to-foot span
  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAssignedPlan();
    _initializeProcessor();
    _initializeCamera();
    _initializePoseDetectorAsync();
  }

  void _loadAssignedPlan() {
    final profile = PatientProfileManager();
    final type = profile.exerciseType;
    final sets = profile.exerciseSets;
    final reps = profile.exerciseReps;
    final mode = profile.exerciseMode;

    setState(() {
      _assignedExercise = type;
      if (reps > 0) _targetReps = reps;
      if (sets > 0) _targetSets = sets;
      if (mode.isNotEmpty) {
        _selectedMode = mode;
      }
    });
  }

  @override
  void dispose() {
    // Set flags to prevent further processing
    _isProcessing = true;
    _isStreamActive = false;

    // Clean up resources synchronously
    // Note: stopImageStream is async but we can't await in dispose
    // The _isStreamActive flag will prevent new frames from being processed
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _initializePoseDetectorAsync() async {
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      );
      _poseDetector = PoseDetector(options: options);
      if (mounted) {
        setState(() {}); // Notify that pose detector is ready
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Pose detector error: $e');
      }
    }
  }

  void _initializeProcessor() {
    final thresholds = _selectedMode == 'Beginner'
        ? PoseThresholdConfig.beginner()
        : PoseThresholdConfig.pro();
    _squatProcessor = SquatProcessor(
      thresholds: thresholds,
      targetReps: _targetReps,
      targetSets: _targetSets,
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        _showPermissionDeniedDialog();
        return;
      }

      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        _showErrorDialog('No cameras available');
        return;
      }

      // Initialize with first camera (usually back camera)
      _cameraController = CameraController(
        _availableCameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      _showErrorDialog('Camera error: $e');
    }
  }

  Future<void> _startSession() async {
    if (!_isCameraInitialized) return;

    _initializeProcessor();
    _squatProcessor.reset();

    setState(() {
      _isStreamActive = true;
      _calibrating = true;
      _calibrationCounter = 0;
      _lastResult = null;
      _poses = [];
    });

    await _cameraController!.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || _poseDetector == null || !_isStreamActive) return;
    _isProcessing = true;

    try {
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) {
        if (mounted) {
          setState(() {
            _poses = [];
            _lastResult = SquatResult(
              correctReps: _lastResult?.correctReps ?? 0,
              incorrectReps: _lastResult?.incorrectReps ?? 0,
              currentSet: _lastResult?.currentSet ?? 0,
              feedback: 'No person detected',
              isRepCounted: false,
              kneeAngle: 0,
              hipAngle: 0,
              ankleAngle: 0,
              currentState: null,
              sessionComplete: false,
              jointsDetected: false,
              displayMessage: 'No person detected',
              waitingForReset: false,
              messageTimer: 0,
            );
          });
        }
        _isProcessing = false;
        return;
      }

      // Calibration/visibility gating - check offset angle first
      if (_calibrating) {
        final pose = poses.first;
        final nose = pose.landmarks[PoseLandmarkType.nose];
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
        final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

        // Check offset angle (posture alignment)
        if (nose != null && leftShoulder != null && rightShoulder != null) {
          final offsetAngle = _calculateOffsetAngle(
            leftShoulder.x,
            leftShoulder.y,
            rightShoulder.x,
            rightShoulder.y,
            nose.x,
            nose.y,
          );

          if (offsetAngle > 50) {
            // Posture not aligned - ask to turn
            _calibrationCounter = 0;
            _selectedSide = null; // Clear selected side
            if (mounted) {
              setState(() {
                _poses = poses;
                _lastResult = SquatResult(
                  correctReps: 0,
                  incorrectReps: 0,
                  currentSet: 0,
                  feedback: '',
                  isRepCounted: false,
                  kneeAngle: 0,
                  hipAngle: 0,
                  ankleAngle: 0,
                  currentState: null,
                  sessionComplete: false,
                  jointsDetected: false,
                  displayMessage: 'POSTURE NOT ALIGNED!!! (TURN LEFT or RIGHT)',
                  waitingForReset: false,
                  messageTimer: 0,
                );
              });
            }
            _isProcessing = false;
            return;
          } else {
            // Posture aligned - determine side immediately for skeleton display
            _determineSelectedSide(poses.first);
          }
        }

        // Check if nose (head) and at least one ankle (foot) are visible on screen
        // ML Kit returns pixel coordinates; remove 0..1 bounds and rely on likelihood
        final bool noseVisible = nose != null && (nose.likelihood) > 0.5;
        final bool lVisible = leftAnkle != null && (leftAnkle.likelihood) > 0.5;
        final bool rVisible =
            rightAnkle != null && (rightAnkle.likelihood) > 0.5;

        String calibMessage;
        // Only proceed if head AND at least one foot are visible
        if (noseVisible && (lVisible || rVisible)) {
          _calibrationCounter = (_calibrationCounter + 1).clamp(0, 30);
          calibMessage = 'PERFECT! HOLD POSITION...';
          if (_calibrationCounter >= 30) {
            _calibrating = false;
            // Don't return here - continue to process the frame
          }
        } else {
          _calibrationCounter = 0;
          if (!noseVisible) {
            calibMessage = 'MOVE YOUR HEAD INTO FRAME';
          } else if (!lVisible && !rVisible) {
            calibMessage = 'MOVE AT LEAST ONE FOOT INTO FRAME';
          } else {
            calibMessage = 'PLEASE STAND IN FRAME';
          }
        }

        // If still calibrating, show calibration message and progress bar
        if (_calibrating) {
          if (mounted) {
            setState(() {
              _poses = poses;
              _lastResult = SquatResult(
                correctReps: _lastResult?.correctReps ?? 0,
                incorrectReps: _lastResult?.incorrectReps ?? 0,
                currentSet: _lastResult?.currentSet ?? 0,
                feedback: '',
                isRepCounted: false,
                kneeAngle: _lastResult?.kneeAngle ?? 0,
                hipAngle: _lastResult?.hipAngle ?? 0,
                ankleAngle: _lastResult?.ankleAngle ?? 0,
                currentState: _lastResult?.currentState,
                sessionComplete: false,
                jointsDetected: true,
                displayMessage: calibMessage,
                waitingForReset: _lastResult?.waitingForReset ?? false,
                messageTimer: _lastResult?.messageTimer ?? 0,
              );
            });
          }
          _isProcessing = false;
          return;
        }
      }

      // Process frame with squat processor (after calibration)
      final pResult = _squatProcessor.processFrame(poses.first);
      final result = _mapProcessorResult(pResult);
      debugPrint(
          '[SquatProcessor] correct=${result.correctReps}, incorrect=${result.incorrectReps}, feedback=${result.feedback}, kneeAngle=${result.kneeAngle.toStringAsFixed(1)}');

      if (mounted) {
        setState(() {
          _poses = poses;
          _lastResult = result;
        });
      }

      if (result.sessionComplete) {
        await _stopSession();
      }
    } catch (e) {
      debugPrint('[SessionLiveStream] Error: $e');
    }

    _isProcessing = false;
  }

  Future<void> _stopSession() async {
    // Prevent further frame processing
    _isProcessing = true;

    try {
      // Stop the image stream
      await _cameraController?.stopImageStream();

      // Small delay to ensure the last frame processing completes
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('[SessionLiveStream] Error stopping camera: $e');
    }

    if (mounted) {
      setState(() {
        _isStreamActive = false;
      });
      _showSummaryDialog();
    }
  }

  InputImage? _convertToInputImage(CameraImage image) {
    try {
      // Concatenate YUV420 planes into single byte list
      final bytesBuilder = BytesBuilder(copy: false);
      for (final Plane plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final bytes = bytesBuilder.toBytes();

      // Use camera sensor orientation for rotation
      final sensor = _cameraController?.description.sensorOrientation;
      final rotation = InputImageRotationValue.fromRawValue(sensor ?? 0);
      if (rotation == null) return null;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      return null;
    }
  }

  SquatResult _mapProcessorResult(SquatProcessResult r) {
    return SquatResult(
      correctReps: r.correctReps,
      incorrectReps: r.incorrectReps,
      currentSet: r.currentSet,
      feedback: r.feedback,
      isRepCounted: r.isRepCounted,
      hipAngle: r.hipAngle,
      kneeAngle: r.kneeAngle,
      ankleAngle: r.ankleAngle,
      currentState: r.currentState,
      sessionComplete: _squatProcessor.sessionComplete,
      jointsDetected: true,
      displayMessage: '',
      waitingForReset: false,
      messageTimer: 0,
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('Enable camera access in settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  double _calculateOffsetAngle(double lShoulderX, double lShoulderY,
      double rShoulderX, double rShoulderY, double noseX, double noseY) {
    final p1X = lShoulderX - noseX;
    final p1Y = lShoulderY - noseY;
    final p2X = rShoulderX - noseX;
    final p2Y = rShoulderY - noseY;

    final dot = p1X * p2X + p1Y * p2Y;
    final norm1 = sqrt(p1X * p1X + p1Y * p1Y);
    final norm2 = sqrt(p2X * p2X + p2Y * p2Y);
    if (norm1 == 0 || norm2 == 0) return 0;

    final cosTheta = (dot / (norm1 * norm2)).clamp(-1.0, 1.0);
    return (180 / pi) * acos(cosTheta);
  }

  void _determineSelectedSide(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftFoot = pose.landmarks[PoseLandmarkType.leftFootIndex];
    final rightFoot = pose.landmarks[PoseLandmarkType.rightFootIndex];

    if (leftShoulder != null &&
        rightShoulder != null &&
        leftFoot != null &&
        rightFoot != null) {
      final leftSpan = (leftFoot.y - leftShoulder.y).abs();
      final rightSpan = (rightFoot.y - rightShoulder.y).abs();
      _selectedSide = leftSpan >= rightSpan ? 'left' : 'right';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isStreamActive) {
      return _buildStreamingView(isDark);
    }

    return _buildSetupView(isDark);
  }

  Widget _buildStreamingView(bool isDark) {
    final result = _lastResult;
    final isWaiting = result?.waitingForReset ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        if (_isCameraInitialized && _cameraController != null)
          CameraPreview(_cameraController!)
        else
          Container(color: Colors.black),

        // Skeleton overlay - show when posture is aligned (selectedSide is set)
        if (_poses.isNotEmpty &&
            (result?.jointsDetected ?? false) &&
            _selectedSide != null)
          Positioned.fill(
            child: CustomPaint(
              painter: PosePainter(
                poses: _poses,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                hipAngle: result?.hipAngle,
                kneeAngle: result?.kneeAngle,
                ankleAngle: result?.ankleAngle,
                drawReferences: true,
                selectedSide: _selectedSide,
              ),
            ),
          ),

        // Top-right counters (CORRECT/INCORRECT/SET)
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBadge('CORRECT: ${result?.correctReps ?? 0}', Colors.green),
              const SizedBox(height: 8),
              _buildBadge(
                  'INCORRECT: ${result?.incorrectReps ?? 0}', Colors.red),
              const SizedBox(height: 8),
              _buildBadge('SET: ${result?.currentSet ?? 0} / $_targetSets',
                  Colors.blue),
            ],
          ),
        ),

        // Posture alignment warning (if angle too high)
        if ((result?.displayMessage ?? '').contains('POSTURE NOT ALIGNED'))
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result!.displayMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Calibration progress bar (during calibration phase)
        if (_calibrating)
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              (_calibrationCounter / 30).clamp(0.0, 1.0),
                          child: Container(
                            color: _calibrationCounter >= 30
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_calibrationCounter / 30 * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Feedback messages at BOTTOM (LOWER YOUR HIPS, BEND FORWARD, etc.)
        if (!_calibrating &&
            result != null &&
            result.feedback.isNotEmpty &&
            !result.feedback.contains('Good form') &&
            !isWaiting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: _getFeedbackColor(result.feedback),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  result.feedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Angle labels (displayed on skeleton)
        if ((result?.jointsDetected ?? false) && !isWaiting && !_calibrating)
          Positioned(
            right: 20,
            bottom: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Current State Indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStateColor(result?.currentState),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'State: ${result?.currentState ?? "?"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hip: ${result!.hipAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.lightGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Knee: ${result.kneeAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.lightGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ankle: ${result.ankleAngle.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.lightGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Freeze message (central, during reset phase)
        if (isWaiting && (result?.displayMessage ?? '').isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result!.displayMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Camera toggle button (top right)
        if (_availableCameras.length > 1)
          Positioned(
            top: 20,
            right: 20,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _toggleCamera,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

        // Start/Stop button
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _stopSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'End Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getFeedbackColor(String feedback) {
    if (feedback.contains('BEND')) return const Color(0xFF0099FF);
    if (feedback.contains('LOWER')) return Colors.yellow;
    if (feedback.contains('KNEE FALLING') || feedback.contains('DEEP')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  Color _getStateColor(String? state) {
    switch (state) {
      case 's1':
        return Colors.green;
      case 's2':
        return Colors.orange;
      case 's3':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showSummaryDialog() {
    if (!mounted) return;

    final correctReps = _squatProcessor.totalCorrectReps;
    final incorrectReps = _squatProcessor.totalIncorrectReps;
    final totalReps = correctReps + incorrectReps;
    final accuracy = totalReps > 0
        ? (correctReps / totalReps * 100).toStringAsFixed(1)
        : '0.0';

    // Check if session was successfully completed (all sets done)
    final sessionCompleted = _squatProcessor.sessionComplete;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Session Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correct: $correctReps'),
              Text('Incorrect: $incorrectReps'),
              Text('Total: $totalReps'),
              Text('Accuracy: $accuracy%'),
              Text(
                  'Sets: ${(_squatProcessor.currentSet - 1).clamp(1, _targetSets)}/$_targetSets'),
              if (sessionCompleted)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    '✅ Session Completed!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save session to Firestore and increment completedSessions if session was completed
                if (sessionCompleted) {
                  await _saveSessionToFirestore(
                    correctReps: correctReps,
                    incorrectReps: incorrectReps,
                    accuracyPercentage: double.parse(accuracy),
                  );
                  await _incrementCompletedSessions();
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Save completed session data to Firestore
  /// Stores: correctReps, wrongReps, accuracyPercentage, timestamp
  /// Location: /Patients/{patientId}/Sessions/{sessionId}
  Future<void> _saveSessionToFirestore({
    required int correctReps,
    required int incorrectReps,
    required double accuracyPercentage,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final patientId = user.uid;
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = DateTime.now();

      // Save session data to /Patients/{patientId}/Sessions/{sessionId}
      debugPrint(
          '[SessionLiveStream] Saving session for patientId: $patientId');
      debugPrint(
          '[SessionLiveStream] Session Data: correct=$correctReps, wrong=$incorrectReps, accuracy=$accuracyPercentage%');

      await FirebaseFirestore.instance
          .collection('Patients')
          .doc(patientId)
          .collection('Sessions')
          .doc(sessionId)
          .set({
        'sessionId': sessionId,
        'patientId': patientId,
        'correctReps': correctReps,
        'wrongReps': incorrectReps,
        'totalReps': correctReps + incorrectReps,
        'accuracyPercentage': accuracyPercentage,
        'timestamp': timestamp.toIso8601String(),
        'exerciseType': 'Squat', // Current exercise type
        'sets': _squatProcessor.currentSet - 1,
        'targetSets': _targetSets,
        'mode': _selectedMode, // Beginner/Pro
      });

      debugPrint('[SessionLiveStream] Session saved successfully: $sessionId');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session saved successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[SessionLiveStream] Error saving session to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save session'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Increment the completedSessions counter for the current patient in Firestore
  Future<void> _incrementCompletedSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final patientRef =
          FirebaseFirestore.instance.collection('patients').doc(user.uid);

      // Get current completedSessions count
      final snapshot = await patientRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final currentCompleted =
          (data?['completedSessions'] as num?)?.toInt() ?? 0;

      // Increment by 1
      await patientRef.update({
        'completedSessions': currentCompleted + 1,
        'lastSession': DateTime.now().toIso8601String(),
      });

      debugPrint(
          '[SessionLiveStream] Incremented completedSessions: ${currentCompleted + 1}');
    } catch (e) {
      debugPrint(
          '[SessionLiveStream] Error incrementing completedSessions: $e');
    }
  }

  /// Toggle between front and back cameras
  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2) {
      _showErrorDialog('Only one camera available');
      return;
    }

    try {
      // Stop image stream if active
      final wasStreamActive = _isStreamActive;
      if (wasStreamActive) {
        await _cameraController?.stopImageStream();
      }

      // Dispose current controller
      await _cameraController?.dispose();

      // Switch to next camera
      _currentCameraIndex =
          (_currentCameraIndex + 1) % _availableCameras.length;

      // Initialize new camera
      _cameraController = CameraController(
        _availableCameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Restart image stream if it was active
      if (wasStreamActive) {
        await _cameraController!.startImageStream(_processImage);
      }

      debugPrint(
          '[SessionLiveStream] Switched to camera: ${_availableCameras[_currentCameraIndex].name}');
    } catch (e) {
      debugPrint('[SessionLiveStream] Error switching camera: $e');
      _showErrorDialog('Failed to switch camera: $e');
    }
  }

  Widget _buildSetupView(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Show message if no plan assigned
          if (_assignedExercise.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1F26) : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t('Doctor didn\'t set a rehabilitation plan yet',
                          'لم يحدد الطبيب خطة إعادة تأهيل بعد'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.orange[300] : Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[50],
              border: Border(
                  bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('Workout Settings', 'إعدادات التمرين'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _modeButton(
                            'Beginner',
                            _selectedMode == 'Beginner',
                            null)), // Always locked for patients
                    const SizedBox(width: 12),
                    Expanded(
                        child: _modeButton('Pro', _selectedMode == 'Pro',
                            null)), // Always locked for patients
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildDropdown(
                            t('Reps per Set', 'التكرارات'),
                            _targetReps,
                            20,
                            null)), // Always locked for patients
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildDropdown(
                            t('Total Sets', 'المجموعات'),
                            _targetSets,
                            10,
                            null)), // Always locked for patients
                  ],
                ),
              ],
            ),
          ),

          // Camera preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 400,
                        color: Colors.black12,
                        child: _isCameraInitialized && _cameraController != null
                            ? CameraPreview(_cameraController!)
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                        t('Initializing camera...',
                                            'جاري تهيئة الكاميرا...'),
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    // Camera toggle button
                    if (_isCameraInitialized && _availableCameras.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: _toggleCamera,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.flip_camera_android,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isCameraInitialized ? _startSession : null,
                    child: Text(t('Start Session', 'بدء الجلسة'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF64B5F6).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('📷 Camera Requirements', '📷 متطلبات الكاميرا'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64B5F6))),
                  const SizedBox(height: 8),
                  Text(
                    t('• Good lighting\n• Full body visible (head to feet)\n• 2-3 meters from camera\n• Stable position',
                        '• إضاءة جيدة\n• الجسم مرئي بالكامل (من الرأس إلى القدمين)\n• 2-3 أمتار من الكاميرا\n• موضع ثابت'),
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, bool isSelected, VoidCallback? onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF64B5F6)
              : (isDark ? const Color(0xFF1C1F26) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF64B5F6)
                  : (isDark ? Colors.white12 : Colors.grey[300]!)),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                    fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildDropdown(
      String label, int value, int max, Function(int)? onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87, fontSize: 14),
            onChanged:
                isDisabled ? null : (v) => v != null ? onChanged(v) : null,
            items: List.generate(max, (i) => i + 1)
                .map((n) =>
                    DropdownMenuItem(value: n, child: Text(n.toString())))
                .toList(),
          ),
        ),
      ],
    );
  }
}
