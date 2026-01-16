// =============================================================================
// PATIENT REPORTS SCREEN - VIEW ALL SESSION REPORTS FOR A PATIENT
// =============================================================================
// Purpose: Display all completed sessions for a patient with summary details
// Features:
// - StreamBuilder to fetch all sessions from /Patients/{patientId}/Sessions
// - Display each session as a Card with Date, Correct/Wrong reps, Accuracy
// - Tap on session to view full summary in AlertDialog
// - Sort sessions by date (newest first)
// - Show visual progress bar for accuracy
// Data Structure:
// - Reads from: /Patients/{patientId}/Sessions/{sessionId}
// - Contains: correctReps, wrongReps, accuracyPercentage, timestamp
// =============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';

/// Patient Reports Screen - View all sessions for a patient
class PatientReportsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final VoidCallback? onBack;

  const PatientReportsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.onBack,
  });

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  late Stream<QuerySnapshot> _sessionsStream;

  @override
  void initState() {
    super.initState();
    debugPrint('[PatientReports] Loading sessions for patient: ${widget.patientId}');
    debugPrint('[PatientReports] Patient name: ${widget.patientName}');
    // Initialize stream to fetch sessions from Firestore
    _sessionsStream = FirebaseFirestore.instance
        .collection('Patients')
        .doc(widget.patientId)
        .collection('Sessions')
        .orderBy('timestamp', descending: true) // Newest first
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.patientName} - Session Reports',
        onBack: widget.onBack ?? () => Navigator.pop(context),
      ),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sessionsStream,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            debugPrint('[PatientReports] Error loading sessions: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading sessions',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // No sessions state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint('[PatientReports] No sessions found for patient: ${widget.patientId}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sessions yet',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions recorded for this patient yet.',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Sessions list
          final sessions = snapshot.data!.docs;
          debugPrint('[PatientReports] Found ${sessions.length} sessions for patient: ${widget.patientId}');
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final sessionDoc = sessions[index];
              final data = sessionDoc.data() as Map<String, dynamic>;

              return _buildSessionCard(
                context: context,
                isDark: isDark,
                sessionData: data,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionCard({
    required BuildContext context,
    required bool isDark,
    required Map<String, dynamic> sessionData,
  }) {
    final correctReps = sessionData['correctReps'] as int? ?? 0;
    final wrongReps = sessionData['wrongReps'] as int? ?? 0;
    final totalReps = sessionData['totalReps'] as int? ?? (correctReps + wrongReps);
    final accuracy = sessionData['accuracyPercentage'] as double? ?? 0.0;
    final timestampStr = sessionData['timestamp'] as String? ?? '';
    final exerciseType = sessionData['exerciseType'] as String? ?? 'Squat';

    // Parse timestamp
    final timestamp = timestampStr.isNotEmpty
        ? DateTime.parse(timestampStr)
        : DateTime.now();
    final formattedDate = _formatDate(timestamp);
    final formattedTime = _formatTime(timestamp);

    return GestureDetector(
      onTap: () => _showSessionSummaryDialog(
        context: context,
        isDark: isDark,
        sessionData: sessionData,
        formattedDate: formattedDate,
        formattedTime: formattedTime,
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Exercise type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF64B5F6).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      exerciseType,
                      style: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Correct vs Wrong Reps
              Row(
                children: [
                  Expanded(
                    child: _buildRepsBadge(
                      label: 'Correct',
                      value: correctReps,
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRepsBadge(
                      label: 'Incorrect',
                      value: wrongReps,
                      color: Colors.red,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Accuracy Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accuracy',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${accuracy.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: accuracy / 100,
                      minHeight: 8,
                      backgroundColor:
                          isDark ? Colors.white12 : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getAccuracyColor(accuracy),
                      ),
                    ),
                  ),
                ],
              ),

              // Total Reps
              const SizedBox(height: 12),
              Text(
                'Total Reps: $totalReps',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 11,
                ),
              ),

              // Tap to view details hint
              const SizedBox(height: 8),
              Text(
                'Tap to view full details →',
                style: TextStyle(
                  color: const Color(0xFF64B5F6).withOpacity(0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepsBadge({
    required String label,
    required int value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionSummaryDialog({
    required BuildContext context,
    required bool isDark,
    required Map<String, dynamic> sessionData,
    required String formattedDate,
    required String formattedTime,
  }) {
    final correctReps = sessionData['correctReps'] as int? ?? 0;
    final wrongReps = sessionData['wrongReps'] as int? ?? 0;
    final totalReps = correctReps + wrongReps;
    final accuracy = sessionData['accuracyPercentage'] as double? ?? 0.0;
    final exerciseType = sessionData['exerciseType'] as String? ?? 'Squat';
    final sets = sessionData['sets'] as int? ?? 0;
    final targetSets = sessionData['targetSets'] as int? ?? 0;
    final mode = sessionData['mode'] as String? ?? 'Beginner';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Summary - $exerciseType'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Time
              _buildSummaryRow('Date', formattedDate),
              _buildSummaryRow('Time', formattedTime),
              const Divider(height: 16),

              // Exercise Details
              _buildSummaryRow('Exercise', exerciseType),
              _buildSummaryRow('Mode', mode),
              _buildSummaryRow('Sets Completed', '$sets/$targetSets'),
              const Divider(height: 16),

              // Performance Metrics
              _buildSummaryRow(
                'Correct Reps',
                correctReps.toString(),
                valueColor: Colors.green,
              ),
              _buildSummaryRow(
                'Incorrect Reps',
                wrongReps.toString(),
                valueColor: Colors.red,
              ),
              _buildSummaryRow('Total Reps', totalReps.toString()),
              _buildSummaryRow(
                'Accuracy',
                '${accuracy.toStringAsFixed(1)}%',
                valueColor: _getAccuracyColor(accuracy),
              ),
              const Divider(height: 16),

              // Summary Assessment
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF64B5F6).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generateAssessment(
                        correctReps: correctReps,
                        totalReps: totalReps,
                        accuracy: accuracy,
                        sets: sets,
                        targetSets: targetSets,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _generateAssessment({
    required int correctReps,
    required int totalReps,
    required double accuracy,
    required int sets,
    required int targetSets,
  }) {
    final buffer = StringBuffer();

    // Performance assessment
    if (accuracy >= 90) {
      buffer.writeln('✅ Excellent form consistency! Strong performance.');
    } else if (accuracy >= 75) {
      buffer.writeln('✅ Good form! Keep practicing for better consistency.');
    } else if (accuracy >= 60) {
      buffer.writeln('⚠️ Average form. Focus on proper technique.');
    } else {
      buffer.writeln('⚠️ Form needs improvement. Consider reducing reps/sets.');
    }

    buffer.writeln();

    // Volume assessment
    if (sets == targetSets) {
      buffer.writeln('✅ Completed all target sets.');
    } else if (sets > 0) {
      buffer.writeln('⚠️ Did not complete all target sets.');
    }

    buffer.writeln();

    // Recommendations
    buffer.write('💡 ');
    if (accuracy >= 80 && sets == targetSets) {
      buffer.write(
        'Great progress! Consider increasing difficulty in next session.',
      );
    } else if (accuracy < 70) {
      buffer.write('Focus on form over volume. Watch the demo videos.');
    } else {
      buffer.write('Keep up the consistent work!');
    }

    return buffer.toString().trim();
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.green;
    if (accuracy >= 75) return Colors.lightGreen;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }
}
