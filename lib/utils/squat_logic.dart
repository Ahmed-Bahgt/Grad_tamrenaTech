import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Dart port of process_frame_squat.py / thresholds.py / utils.py
/// Mirrors the state machine, thresholds, freeze/reset flow, and feedback.
class SquatLogic {
  final SquatMode mode;
  final int targetReps;
  final int targetSets;

  late final SquatThresholds _thresholds;

  // Counters
  int _setCount = 0;
  int _squatCount = 0; // correct reps
  int _improperCount = 0; // incorrect reps

  // State machine
  List<String> _stateSeq = [];
  String? _currentState;

  // Freeze/reset logic
  bool _waitingForReset = false;
  int _messageTimer = 0; // frames (~30fps, Python uses 90)
  String? _freezeMessage;

  // Feedback flags (DISPLAY_TEXT in Python, length 4 used)
  Map<int, bool> _displayText = {0: false, 1: false, 2: false, 3: false};
  bool _lowerHips = false;
  bool _incorrectPosture = false;

  // Visibility and meta
  // Retained for reference; not used after relaxing stream gating
  static const double _visibilityThresh = 0.5;
  String _displayMessage = '';

  SquatLogic({
    required this.mode,
    required this.targetReps,
    required this.targetSets,
  }) {
    _thresholds = mode == SquatMode.beginner
        ? SquatThresholds.beginner()
        : SquatThresholds.pro();
  }

  void reset() {
    _setCount = 0;
    _squatCount = 0;
    _improperCount = 0;
    _stateSeq = [];
    _currentState = null;
    _waitingForReset = false;
    _messageTimer = 0;
    _freezeMessage = null;
    _displayText = {0: false, 1: false, 2: false, 3: false};
    _lowerHips = false;
    _incorrectPosture = false;
    _displayMessage = '';
  }

  SquatResult processFrame(Pose pose) {
    final lm = pose.landmarks;
    if (lm.isEmpty) {
      _displayMessage = 'No person detected';
      return _emptyResult(jointsDetected: false, displayMessage: _displayMessage);
    }

    // Landmarks we need (dict_features)
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final rightHip = lm[PoseLandmarkType.rightHip];
    final leftKnee = lm[PoseLandmarkType.leftKnee];
    final rightKnee = lm[PoseLandmarkType.rightKnee];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];
    final rightAnkle = lm[PoseLandmarkType.rightAnkle];
    final leftFoot = lm[PoseLandmarkType.leftFootIndex];
    final rightFoot = lm[PoseLandmarkType.rightFootIndex];
    final nose = lm[PoseLandmarkType.nose];

    if ([
      leftShoulder,
      rightShoulder,
      leftHip,
      rightHip,
      leftKnee,
      rightKnee,
      leftAnkle,
      rightAnkle,
      leftFoot,
      rightFoot,
      nose,
    ].any((e) => e == null)) {
      _displayMessage = 'Full body not visible';
      return _emptyResult(jointsDetected: false, displayMessage: _displayMessage);
    }

    // Posture alignment check (offset angle between shoulders w.r.t nose)
    final offsetAngle = _findAngle(
      _Point(leftShoulder!.x, leftShoulder.y),
      _Point(rightShoulder!.x, rightShoulder.y),
      _Point(nose!.x, nose.y),
    );

    if (offsetAngle > _thresholds.offsetThresh) {
      _displayMessage = 'POSTURE NOT ALIGNED PROPERLY!!! (TURN LEFT or RIGHT)';
      return _buildResult(
        hipAngle: 0,
        kneeAngle: 0,
        ankleAngle: 0,
        jointsDetected: true,
        displayMessage: _displayMessage,
        repCounted: false,
        sessionComplete: _setCount >= targetSets,
      );
    }

    // Freeze/reset timer handling (skip counting while waiting)
    if (_waitingForReset) {
      if (_messageTimer > 0) {
        _messageTimer -= 1;
      }
      if (_messageTimer <= 0) {
        _waitingForReset = false;
        _messageTimer = 0;
        _squatCount = 0;
        _improperCount = 0;
        _setCount = (_setCount + 1).clamp(0, targetSets);
      }
    }

    // Choose side with bigger shoulder-to-foot span
    final leftSpan = (leftFoot!.y - leftShoulder.y).abs();
    final rightSpan = (rightFoot!.y - rightShoulder.y).abs();
    final useLeft = leftSpan >= rightSpan;

    final shoulder = useLeft ? leftShoulder : rightShoulder;
    final hip = useLeft ? leftHip! : rightHip!;
    final knee = useLeft ? leftKnee! : rightKnee!;
    final ankle = useLeft ? leftAnkle! : rightAnkle!;

    // Basic presence check (avoid over-filtering by likelihood in stream mode)
    // We already gated camera visibility during calibration, so proceed here.
    // If any key joint is missing, return early.
    // Landmarks are non-null here with ML Kit; this guard silences analyzer
    if (knee == null) {
      _displayMessage = 'Full body not visible';
      return _emptyResult(jointsDetected: false, displayMessage: _displayMessage);
    }

    // Angles (vertical reference, matching Python)
    final hipAngle = _findAngle(
      _Point(shoulder.x, shoulder.y),
      _Point(hip.x, 0),
      _Point(hip.x, hip.y),
    );
    final kneeAngle = _findAngle(
      _Point(hip.x, hip.y),
      _Point(knee.x, 0),
      _Point(knee.x, knee.y),
    );
    final ankleAngle = _findAngle(
      _Point(knee.x, knee.y),
      _Point(ankle.x, 0),
      _Point(ankle.x, ankle.y),
    );

    // Feedback flags reset each frame
    _displayText = {0: false, 1: false, 2: false, 3: false};
    _lowerHips = false;

    // State machine & counting (only if not waiting)
    bool repCounted = false;
    if (!_waitingForReset) {
      _currentState = _getState(kneeAngle.toInt());
      _updateStateSequence(_currentState);

      if (_currentState == 's1') {
        // Check for complete sequence: should have s2 and s3
        if (_stateSeq.contains('s2') &&
            _stateSeq.contains('s3') &&
            !_incorrectPosture) {
          _squatCount += 1;
          repCounted = true;
          debugPrint('[SquatLogic] ✅ CORRECT REP #$_squatCount, state_seq=$_stateSeq');
        } else if (_stateSeq.contains('s2') && !_stateSeq.contains('s3')) {
          // Incomplete squat - only went to transition, not full depth
          _improperCount += 1;
          repCounted = true;
          debugPrint('[SquatLogic] ❌ INCORRECT (incomplete) #$_improperCount, state_seq=$_stateSeq');
        } else if (_incorrectPosture) {
          _improperCount += 1;
          repCounted = true;
          debugPrint('[SquatLogic] ❌ INCORRECT (posture) #$_improperCount');
        }

        _stateSeq = [];
        _incorrectPosture = false;

        final totalReps = _squatCount + _improperCount;
        if (totalReps >= targetReps) {
          _waitingForReset = true;
          _messageTimer = 90; // ~3 seconds at 30 fps
          final nextSet = _setCount + 1;
          if (nextSet >= targetSets) {
            _freezeMessage = 'Whole Training is Done!';
          } else {
            _freezeMessage = 'Well Done! Set $nextSet Finished';
          }
          debugPrint('[SquatLogic] 🔄 FREEZE: totalReps=$totalReps, nextSet=$nextSet');
        }
      }
    }

    // Feedback (DISPLAY_TEXT and LOWER_HIPS) - ONLY when NOT waiting for reset
    if (!_waitingForReset) {
      if (hipAngle > _thresholds.hipThreshMax) {
        _displayText[0] = true; // BEND FORWARD
        debugPrint('[SquatLogic] FEEDBACK: BEND FORWARD (hip=$hipAngle)');
      } else if (hipAngle < _thresholds.hipThreshMin &&
          _stateSeq.where((s) => s == 's2').length == 1) {
        _displayText[1] = true; // BEND BACKWARDS
        debugPrint('[SquatLogic] FEEDBACK: BEND BACKWARDS (hip=$hipAngle)');
      }

      if (kneeAngle > _thresholds.kneeThreshMin &&
          kneeAngle < _thresholds.kneeThreshMid &&
          _stateSeq.where((s) => s == 's2').length == 1) {
        _lowerHips = true;
        debugPrint('[SquatLogic] FEEDBACK: LOWER YOUR HIPS (knee=$kneeAngle in s2)');
      } else if (kneeAngle > _thresholds.kneeThreshMax) {
        _displayText[3] = true; // SQUAT TOO DEEP
        _incorrectPosture = true;
        debugPrint('[SquatLogic] FEEDBACK: SQUAT TOO DEEP (knee=$kneeAngle)');
      }

      if (ankleAngle > _thresholds.ankleThresh) {
        _displayText[2] = true; // KNEE FALLING OVER TOE
        _incorrectPosture = true;
        debugPrint('[SquatLogic] FEEDBACK: KNEE FALLING OVER TOE (ankle=$ankleAngle)');
      }

      if (_stateSeq.contains('s3')) {
        _lowerHips = false;
      }
    }

    final sessionComplete = _setCount >= targetSets && !_waitingForReset;
    final message = _waitingForReset ? _freezeMessage : _displayMessage;

    return _buildResult(
      hipAngle: hipAngle,
      kneeAngle: kneeAngle,
      ankleAngle: ankleAngle,
      jointsDetected: true,
      displayMessage: message,
      repCounted: repCounted,
      sessionComplete: sessionComplete,
    );
  }

  SquatResult _emptyResult({
    required bool jointsDetected,
    String? displayMessage,
  }) {
    return SquatResult(
      correctReps: _squatCount,
      incorrectReps: _improperCount,
      currentSet: _setCount,
      feedback: _generateFeedback(),
      isRepCounted: false,
      hipAngle: 0,
      kneeAngle: 0,
      ankleAngle: 0,
      currentState: _currentState,
      sessionComplete: _setCount >= targetSets,
      jointsDetected: jointsDetected,
      displayMessage: displayMessage,
      waitingForReset: _waitingForReset,
      messageTimer: _messageTimer,
    );
  }

  SquatResult _buildResult({
    required double hipAngle,
    required double kneeAngle,
    required double ankleAngle,
    required bool jointsDetected,
    String? displayMessage,
    required bool repCounted,
    required bool sessionComplete,
  }) {
    return SquatResult(
      correctReps: _squatCount,
      incorrectReps: _improperCount,
      currentSet: _setCount,
      feedback: _generateFeedback(),
      isRepCounted: repCounted,
      hipAngle: hipAngle,
      kneeAngle: kneeAngle,
      ankleAngle: ankleAngle,
      currentState: _currentState,
      sessionComplete: sessionComplete,
      jointsDetected: jointsDetected,
      displayMessage: displayMessage,
      waitingForReset: _waitingForReset,
      messageTimer: _messageTimer,
    );
  }

  String? _getState(int kneeAngle) {
    if (kneeAngle >= _thresholds.normalMin && kneeAngle <= _thresholds.normalMax) {
      return 's1';
    } else if (kneeAngle >= _thresholds.transMin && kneeAngle <= _thresholds.transMax) {
      return 's2';
    } else if (kneeAngle >= _thresholds.passMin && kneeAngle <= _thresholds.passMax) {
      return 's3';
    }
    return null;
  }

  void _updateStateSequence(String? state) {
    if (state == null) return;

    if (state == 's2') {
      final s2Count = _stateSeq.where((s) => s == 's2').length;
      final hasS3 = _stateSeq.contains('s3');
      if ((!hasS3 && s2Count == 0) || (hasS3 && s2Count == 1)) {
        _stateSeq.add(state);
      }
    } else if (state == 's3') {
      if (!_stateSeq.contains(state) && _stateSeq.contains('s2')) {
        _stateSeq.add(state);
      }
    }
  }

  double _findAngle(_Point p1, _Point p2, _Point refPt) {
    final p1Ref = _Point(p1.x - refPt.x, p1.y - refPt.y);
    final p2Ref = _Point(p2.x - refPt.x, p2.y - refPt.y);

    final dot = p1Ref.x * p2Ref.x + p1Ref.y * p2Ref.y;
    final norm1 = sqrt(p1Ref.x * p1Ref.x + p1Ref.y * p1Ref.y);
    final norm2 = sqrt(p2Ref.x * p2Ref.x + p2Ref.y * p2Ref.y);
    if (norm1 == 0 || norm2 == 0) return 0;

    final cosTheta = (dot / (norm1 * norm2)).clamp(-1.0, 1.0);
    return (180 / pi) * acos(cosTheta);
  }

  String _generateFeedback() {
    if (_displayText[0] == true) return 'BEND FORWARD';
    if (_displayText[1] == true) return 'BEND BACKWARDS';
    if (_displayText[2] == true) return 'KNEE FALLING OVER TOE';
    if (_displayText[3] == true) return 'SQUAT TOO DEEP';
    if (_lowerHips) return 'LOWER YOUR HIPS';
    if (_waitingForReset && _freezeMessage != null) return _freezeMessage!;
    return 'Good form';
  }
}

class SquatResult {
  final int correctReps;
  final int incorrectReps;
  final int currentSet;
  final String feedback;
  final bool isRepCounted;
  final double kneeAngle;
  final double hipAngle;
  final double ankleAngle;
  final String? currentState;
  final bool sessionComplete;
  final bool jointsDetected;
  final String? displayMessage;
  final bool waitingForReset;
  final int messageTimer;

  const SquatResult({
    required this.correctReps,
    required this.incorrectReps,
    required this.currentSet,
    required this.feedback,
    required this.isRepCounted,
    required this.kneeAngle,
    required this.hipAngle,
    required this.ankleAngle,
    required this.currentState,
    required this.sessionComplete,
    required this.jointsDetected,
    required this.displayMessage,
    required this.waitingForReset,
    required this.messageTimer,
  });
}

class SquatThresholds {
  final int normalMin, normalMax;
  final int transMin, transMax;
  final int passMin, passMax;
  final int hipThreshMin, hipThreshMax;
  final int ankleThresh;
  final int kneeThreshMin, kneeThreshMid, kneeThreshMax;
  final double offsetThresh;

  SquatThresholds.beginner()
      : normalMin = 0,
        normalMax = 30,
        transMin = 35,
        transMax = 65,
        passMin = 70,
        passMax = 95,
        hipThreshMin = 10,
        hipThreshMax = 60,
        ankleThresh = 45,
        kneeThreshMin = 50,
        kneeThreshMid = 70,
        kneeThreshMax = 95,
        offsetThresh = 50;

  SquatThresholds.pro()
      : normalMin = 0,
        normalMax = 30,
        transMin = 35,
        transMax = 65,
        passMin = 80,
        passMax = 95,
        hipThreshMin = 15,
        hipThreshMax = 50,
        ankleThresh = 30,
        kneeThreshMin = 50,
        kneeThreshMid = 80,
        kneeThreshMax = 95,
        offsetThresh = 50;
}

enum SquatMode { beginner, pro }

class _Point {
  final double x, y;
  const _Point(this.x, this.y);
}
