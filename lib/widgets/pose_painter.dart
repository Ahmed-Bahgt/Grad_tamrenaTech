import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Custom painter to draw pose skeleton and reference lines/angles
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final double? hipAngle;
  final double? kneeAngle;
  final double? ankleAngle;
  final bool drawReferences;
  final String? selectedSide; // 'left' or 'right'

  PosePainter({
    required this.poses,
    required this.imageSize,
    this.hipAngle,
    this.kneeAngle,
    this.ankleAngle,
    this.drawReferences = false,
    this.selectedSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final pose = poses.first;
    final landmarks = pose.landmarks;

    // Calculate scale factors
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    // Paints
    final landmarkPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final connectionPaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final refPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw connections first (so they appear behind landmarks)
    _drawConnections(canvas, landmarks, scaleX, scaleY, connectionPaint);

    // Draw only focused landmarks based on selected side
    if (selectedSide != null) {
      // Draw exactly 7 joints: shoulder, elbow, wrist, hip, knee, ankle, toe (footIndex)
      final side = selectedSide == 'left'
          ? [
              PoseLandmarkType.leftShoulder,
              PoseLandmarkType.leftElbow,
              PoseLandmarkType.leftWrist,
              PoseLandmarkType.leftHip,
              PoseLandmarkType.leftKnee,
              PoseLandmarkType.leftAnkle,
              PoseLandmarkType.leftFootIndex,
            ]
          : [
              PoseLandmarkType.rightShoulder,
              PoseLandmarkType.rightElbow,
              PoseLandmarkType.rightWrist,
              PoseLandmarkType.rightHip,
              PoseLandmarkType.rightKnee,
              PoseLandmarkType.rightAnkle,
              PoseLandmarkType.rightFootIndex,
            ];

      for (final type in side) {
        final landmark = landmarks[type];
        if (landmark == null) continue;
        final x = landmark.x * scaleX;
        final y = landmark.y * scaleY;
        canvas.drawCircle(Offset(x, y), 6, landmarkPaint);
      }
    }

    if (drawReferences) {
      _drawReferenceLinesAndAngles(canvas, size, landmarks, scaleX, scaleY, refPaint);
    }
  }

  void _drawConnections(
    Canvas canvas,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    double scaleX,
    double scaleY,
    Paint paint,
  ) {
    if (selectedSide == null) return;

    // Only draw connections for the selected side
    final connections = selectedSide == 'left'
        ? [
            // Left arm
            [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
            [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
            // Left leg
            [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
            [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
            [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
            [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex],
          ]
        : [
            // Right arm
            [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
            [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
            // Right leg
            [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
            [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
            [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
            [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex],
          ];

    for (final connection in connections) {
      final start = landmarks[connection[0]];
      final end = landmarks[connection[1]];

      if (start != null && end != null) {
        final startX = start.x * scaleX;
        final startY = start.y * scaleY;
        final endX = end.x * scaleX;
        final endY = end.y * scaleY;

        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );
      }
    }
  }

  void _drawReferenceLinesAndAngles(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, PoseLandmark> lm,
    double scaleX,
    double scaleY,
    Paint refPaint,
  ) {
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftFoot = lm[PoseLandmarkType.leftFootIndex] ?? lm[PoseLandmarkType.leftHeel];
    final rightFoot = lm[PoseLandmarkType.rightFootIndex] ?? lm[PoseLandmarkType.rightHeel];

    if (leftShoulder == null || rightShoulder == null || leftFoot == null || rightFoot == null) return;

    final leftSpan = (leftFoot.y - leftShoulder.y).abs();
    final rightSpan = (rightFoot.y - rightShoulder.y).abs();
    final useLeft = leftSpan >= rightSpan;

    final hip = lm[useLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = lm[useLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = lm[useLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];

    if (hip == null || knee == null || ankle == null) return;

    final hipX = hip.x * scaleX;
    final kneeX = knee.x * scaleX;
    final ankleX = ankle.x * scaleX;

    // Angle labels near joints
    const textStyle = TextStyle(
      color: Colors.lightGreenAccent,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    void drawAngle(double? angle, double x, double y) {
      if (angle == null) return;
      final tp = TextPainter(
        text: TextSpan(text: angle.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + 8, y - 16));
    }

    drawAngle(hipAngle, hipX, hip.y * scaleY);
    drawAngle(kneeAngle, kneeX, knee.y * scaleY);
    drawAngle(ankleAngle, ankleX, ankle.y * scaleY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.hipAngle != hipAngle ||
        oldDelegate.kneeAngle != kneeAngle ||
        oldDelegate.ankleAngle != ankleAngle ||
        oldDelegate.drawReferences != drawReferences ||
        oldDelegate.selectedSide != selectedSide;
  }
}
