import 'package:flutter/material.dart';
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

  final Map<String, String> _trainingTypes = {
    'Squat': 'squat',
    'Lunge': 'lunge',
    'Deadlift': 'deadlift',
  };

  final Map<String, String> _formOptions = {
    'Correct': 'correct',
    'Incorrect': 'incorrect',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortName = _trainingTypes[_selectedTraining] ?? 'squat';
    final formName = _formOptions[_selectedForm] ?? 'correct';
    final videoPath = 'assets/examples/${shortName}_$formName.mp4';

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
                    _buildDropdown(value: _selectedTraining, items: _trainingTypes.keys.toList(), onChanged: (value) => setState(() => _selectedTraining = value ?? 'Squat'), isDark: isDark),
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
                    _buildDropdown(value: _selectedForm, items: _formOptions.keys.toList(), onChanged: (value) => setState(() => _selectedForm = value ?? 'Correct'), isDark: isDark),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 64, color: isDark ? Colors.white30 : Colors.black26),
                  const SizedBox(height: 16),
                  Text(t('Video: $videoPath', 'فيديو: $videoPath'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF64B5F6).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF64B5F6).withOpacity(0.3))),
                    child: Text(t('Add video files to assets/examples/\n(e.g., squat_correct.mp4)', 'أضف ملفات الفيديو إلى assets/examples/\n(مثل squat_correct.mp4)'), style: const TextStyle(fontSize: 11, color: Color(0xFF64B5F6)), textAlign: TextAlign.center),
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
