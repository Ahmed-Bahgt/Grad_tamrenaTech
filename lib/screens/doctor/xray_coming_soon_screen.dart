import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// X-Ray Analysis Screen - Picks an image and sends to FastAPI
class XrayComingSoonScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const XrayComingSoonScreen({super.key, this.onBack});

  @override
  State<XrayComingSoonScreen> createState() => _XrayComingSoonScreenState();
}

class _XrayComingSoonScreenState extends State<XrayComingSoonScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _isLoading = false;
  String? _prediction;
  String? _probability;
  String? _error;

  Future<void> _pickImage() async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _image = picked;
          _prediction = null;
          _probability = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image.')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _prediction = null;
      _probability = null;
    });
    try {
      final uri = Uri.parse('http://192.168.1.66:8000/predict');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _image!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final body = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(body);
        setState(() {
          _prediction = data['prediction']?.toString();
          _probability = data['raw_probability_percent']?.toString();
        });
      } else {
        setState(() {
          _error = 'Server error (${streamedResponse.statusCode})';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${streamedResponse.statusCode}'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed. Please try again.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _resultColor() {
    if (_prediction == null) return const Color(0xFF00BCD4);
    final p = _prediction!.toLowerCase();
    if (p.contains('positive')) return Colors.red;
    if (p.contains('negative')) return Colors.green;
    return const Color(0xFF00BCD4);
  }

  String _resultStatus() {
    if (_prediction == null) return 'Result';
    final p = _prediction!.toLowerCase();
    if (p.contains('positive')) return 'Fracture Detected';
    if (p.contains('negative')) return 'Normal';
    return 'Result';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFBFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
        title: const Text(
          'X-Ray Analysis',
          style: TextStyle(
            color: Color(0xFF00BCD4),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!.call();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image preview or placeholder
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B22) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_image!.path),
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          children: [
                            Icon(
                              Icons.image_search,
                              size: 100,
                              color: const Color(0xFF00BCD4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select an X-ray image to analyze',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick from Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00BCD4),
                      side: const BorderSide(color: Color(0xFF00BCD4)),
                    ),
                    onPressed: _isLoading ? null : _pickImage,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.science),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        (_image != null && !_isLoading) ? _analyzeImage : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Loading indicator
              if (_isLoading) const CircularProgressIndicator(),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              // Results
              if (_prediction != null || _probability != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: _resultColor().withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _resultColor()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resultStatus(),
                        style: TextStyle(
                          color: _resultColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_prediction != null)
                        Text(
                          'Prediction: ${_prediction!}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      if (_probability != null)
                        Text(
                          'Probability: ${_probability!}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
