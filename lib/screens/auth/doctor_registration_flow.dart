import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/auth_service.dart';
import '../../utils/theme_provider.dart';
import '../../utils/responsive_utils.dart';

class DoctorRegistrationFlowPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onDoctorLogin;

  const DoctorRegistrationFlowPage({
    super.key,
    required this.onBack,
    required this.onDoctorLogin,
  });

  @override
  State<DoctorRegistrationFlowPage> createState() => _DoctorRegistrationFlowPageState();
}

class _DoctorRegistrationFlowPageState extends State<DoctorRegistrationFlowPage> {
  final _authService = AuthService();

  // Primary info
  final _primaryFormKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Graduation
  final _gradDateCtrl = TextEditingController();
  File? _certificateFile;
  String? _certificateUploadedUrl;
  bool _uploadingCertificate = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Qualifications
  final List<_QualificationItem> _qualifications = [];
  int? _uploadingQualificationIndex;

  // Cloudinary configuration (unsigned preset)
  static const String _cloudName = 'drcaukx3q';
  static const String _uploadPreset = 'tamren_preset';

  bool _submitting = false;

  int _pageIndex = 0; // 0=Primary,1=Graduation,2=Qualifications

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _gradDateCtrl.dispose();
    for (final q in _qualifications) {
      q.nameCtrl.dispose();
    }
    super.dispose();
  }

  void _goNext() {
    setState(() => _pageIndex += 1);
  }

  void _goBack() {
    if (_pageIndex == 0) {
      widget.onBack();
    } else {
      setState(() => _pageIndex -= 1);
    }
  }

  // Actions
  Future<void> _pickGradDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      _gradDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _pickCertificateFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
    if (picked != null) {
      setState(() => _certificateFile = File(picked.path));
    }
  }

  Future<void> _pickCertificateFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) setState(() => _certificateFile = File(path));
    }
  }

  void _addQualification() {
    setState(() {
      _qualifications.add(_QualificationItem());
    });
  }

  void _removeQualification(int index) {
    setState(() {
      _qualifications.removeAt(index);
    });
  }

  void _editCertificate() {
    setState(() {
      _certificateFile = null;
      _certificateUploadedUrl = null;
    });
  }

  Future<void> _uploadCertificateStandalone() async {
    if (_certificateFile == null) {
      _showSnack(t('Select a certificate file first.', 'اختر ملف الشهادة أولاً.'));
      return;
    }
    setState(() => _uploadingCertificate = true);
    try {
      final url = await _uploadCertificateToCloudinary(_certificateFile!);
      _certificateUploadedUrl = url;
      _showSnack(t('Certificate uploaded successfully.', 'تم رفع الشهادة بنجاح.'));
    } catch (e) {
      _showSnack(t('Certificate upload failed. Try again.', 'فشل رفع الشهادة. حاول مجدداً.'));
      debugPrint('⚠️ Certificate upload (standalone) failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingCertificate = false);
    }
  }

  Future<void> _uploadQualificationStandalone(int index) async {
    if (index < 0 || index >= _qualifications.length) return;
    final item = _qualifications[index];
    if (item.file == null) {
      _showSnack(t('Select a qualification file first.', 'اختر ملف المؤهل أولاً.'));
      return;
    }

    setState(() => _uploadingQualificationIndex = index);
    try {
      final url = await _uploadCertificateToCloudinary(item.file!);
      item.uploadedUrl = url;
      _showSnack(t('Qualification uploaded successfully.', 'تم رفع المؤهل بنجاح.'));
    } catch (e) {
      _showSnack(t('Qualification upload failed. Try again.', 'فشل رفع المؤهل. حاول مجدداً.'));
      debugPrint('⚠️ Qualification upload (standalone) failed: $e');
    } finally {
      if (mounted) setState(() => _uploadingQualificationIndex = null);
    }
  }

  Future<void> _pickQualificationImage(int index) async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
    if (picked != null) {
      setState(() => _qualifications[index].file = File(picked.path));
    }
  }

  Future<void> _pickQualificationFileAny(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) setState(() => _qualifications[index].file = File(path));
    }
  }

  Future<String> _uploadCertificateToCloudinary(File file) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      throw Exception('Cloudinary upload failed with status ${streamed.statusCode}');
    }

    final bytes = await streamed.stream.toBytes();
    final body = String.fromCharCodes(bytes);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final url = decoded['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary response missing secure_url');
    }
    return url;
  }

  Future<void> _submit() async {
    if (!(_primaryFormKey.currentState?.validate() ?? false)) {
      _showSnack(t('Please complete primary info correctly.', 'يرجى إكمال المعلومات الأساسية بشكل صحيح.'));
      return;
    }
    if (_gradDateCtrl.text.trim().isEmpty || _certificateFile == null) {
      _showSnack(t('Provide graduation date and certificate.', 'أدخل تاريخ التخرج وحمّل الشهادة.'));
      return;
    }

    setState(() => _submitting = true);
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      debugPrint('🔥 Firebase: User created with UID: ${userCredential.user!.uid}');

      // Send email verification
      await userCredential.user?.sendEmailVerification();
      debugPrint('🔥 Firebase: Email verification sent');

      bool uploadWarning = false;

      // Upload certificate
      String? certificateUrl = _certificateUploadedUrl;
      if (certificateUrl == null && _certificateFile != null) {
        debugPrint('🔥 Cloudinary: Uploading doctor certificate...');
        try {
          certificateUrl = await _uploadCertificateToCloudinary(_certificateFile!);
          debugPrint('🔥 Cloudinary: Certificate uploaded to: $certificateUrl');
        } catch (e) {
          uploadWarning = true;
          debugPrint('⚠️ Certificate upload failed: $e');
        }
      }

      // Upload qualifications
      List<Map<String, String>>? uploadedQualifications;
      if (_qualifications.isNotEmpty) {
        uploadedQualifications = [];
        for (final q in _qualifications.where((q) => q.nameCtrl.text.trim().isNotEmpty)) {
          String? url = q.uploadedUrl;
          if (url == null && q.file != null) {
            try {
              url = await _uploadCertificateToCloudinary(q.file!);
            } catch (e) {
              uploadWarning = true;
              debugPrint('⚠️ Qualification upload failed: $e');
            }
          }
          uploadedQualifications.add({
            'name': q.nameCtrl.text.trim(),
            if (url != null) 'url': url,
          });
        }
      }

      // Save to Firestore
      final data = RegistrationData(
        role: RegistrationRole.doctor,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phoneNumber: '', // No phone number
        graduationDate: _gradDateCtrl.text.trim(),
        certificateFile: _certificateFile,
        qualifications: _qualifications
            .where((q) => q.nameCtrl.text.trim().isNotEmpty)
            .map((q) => QualificationInput(name: q.nameCtrl.text.trim(), file: q.file))
            .toList(),
      );

      await _authService.saveProfile(
        uid: userCredential.user!.uid,
        data: data,
        certificateUrl: certificateUrl,
        qualifications: uploadedQualifications,
      );

      // Mirror certificate URL into doctors collection
      if (certificateUrl != null) {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(userCredential.user!.uid)
            .set({'certificateUrl': certificateUrl}, SetOptions(merge: true));
      }

      debugPrint('🔥 Firebase: ✅ Registration complete');

      if (!mounted) return;
      final baseMsg = t('Registration successful! Please verify your email.', 'تم التسجيل بنجاح! يرجى تأكيد بريدك الإلكتروني.');
      if (uploadWarning) {
        _showSnack('$baseMsg ${t('Some files could not be uploaded. You can upload them later.', 'تعذر رفع بعض الملفات. يمكنك رفعها لاحقاً.') }');
      } else {
        _showSnack(baseMsg);
      }
      // Sign out the user so they can log in
      await FirebaseAuth.instance.signOut();
      // Navigate to doctor login (delayed to let UI settle)
      Future.microtask(widget.onDoctorLogin);
    } on FirebaseAuthException catch (e) {
      final msg = '[${e.code}] ${e.message ?? "Unknown Firebase error"}';
      _showSnack(msg);
      debugPrint('❌ Submit Error: $msg');
    } catch (e) {
      _showSnack(e.toString());
      debugPrint('❌ Submit Error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Create Account', 'إنشاء حساب')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      ),
      body: Column(
        children: [
          // Modern progress header for 3 steps (Primary → Graduation → Qualifications)
          _ProgressHeader(currentIndex: _pageIndex.clamp(0, 2), isDark: isDark),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _pageIndex,
              children: [
                _PrimaryInfoScreen(
                  formKey: _primaryFormKey,
                  firstNameCtrl: _firstNameCtrl,
                  lastNameCtrl: _lastNameCtrl,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  confirmPasswordCtrl: _confirmPasswordCtrl,
                  showPassword: _showPassword,
                  showConfirmPassword: _showConfirmPassword,
                  onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                  onToggleConfirmPassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  onNext: () {
                    if (_primaryFormKey.currentState?.validate() ?? false) _goNext();
                  },
                ),
                _GraduationScreen(
                  gradDateCtrl: _gradDateCtrl,
                  certificateFile: _certificateFile,
                  uploadedUrl: _certificateUploadedUrl,
                  uploading: _uploadingCertificate,
                  isDark: isDark,
                  onPickDate: _pickGradDate,
                  onPickPhoto: _pickCertificateFromGallery,
                  onPickFile: _pickCertificateFile,
                  onUpload: _uploadCertificateStandalone,
                  onEdit: _editCertificate,
                  onNext: () {
                    if (_gradDateCtrl.text.isEmpty) {
                      _showSnack(t('Please enter graduation date.', 'يرجى إدخال تاريخ التخرج.'));
                    } else if (_certificateUploadedUrl == null) {
                      _showSnack(t('Please upload the graduation certificate.', 'يرجى رفع شهادة التخرج.'));
                    } else {
                      _goNext();
                    }
                  },
                ),
                _QualificationsScreen(
                  items: _qualifications,
                  isDark: isDark,
                  uploadingIndex: _uploadingQualificationIndex,
                  onAdd: _addQualification,
                  onDelete: _removeQualification,
                  onPickPhoto: _pickQualificationImage,
                  onPickFile: _pickQualificationFileAny,
                  onUpload: _uploadQualificationStandalone,
                  onNext: _submit,
                  submitting: _submitting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _PrimaryInfoScreen extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final VoidCallback onNext;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const _PrimaryInfoScreen({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.onNext,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.padding(context, 16);
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: firstNameCtrl,
              decoration: InputDecoration(labelText: t('First Name', 'الاسم الأول')),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('Required', 'مطلوب') : null,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            TextFormField(
              controller: lastNameCtrl,
              decoration: InputDecoration(labelText: t('Last Name', 'اسم العائلة')),
              validator: (v) => (v == null || v.trim().isEmpty) ? t('Required', 'مطلوب') : null,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t('Email', 'البريد الإلكتروني')),
              validator: (v) => (v == null || !v.contains('@')) ? t('Enter a valid email', 'أدخل بريدًا صالحًا') : null,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            TextFormField(
              controller: passwordCtrl,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: t('Password', 'كلمة المرور'),
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? t('Password must be 6+ chars', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل') : null,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            TextFormField(
              controller: confirmPasswordCtrl,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: t('Confirm Password', 'تأكيد كلمة المرور'),
                suffixIcon: IconButton(
                  icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleConfirmPassword,
                ),
              ),
              validator: (v) => (v != passwordCtrl.text) ? t('Passwords do not match', 'كلمتا المرور غير متطابقتين') : null,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            SizedBox(
              height: ResponsiveUtils.buttonHeight(context),
              width: double.infinity,
              child: ElevatedButton(onPressed: onNext, child: Text(t('Next', 'التالي'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraduationScreen extends StatelessWidget {
  final TextEditingController gradDateCtrl;
  final File? certificateFile;
  final String? uploadedUrl;
  final bool uploading;
  final bool isDark;
  final VoidCallback onPickDate;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickFile;
  final VoidCallback onUpload;
  final VoidCallback onEdit;
  final VoidCallback onNext;

  const _GraduationScreen({
    required this.gradDateCtrl,
    required this.certificateFile,
    required this.uploadedUrl,
    required this.uploading,
    required this.isDark,
    required this.onPickDate,
    required this.onPickPhoto,
    required this.onPickFile,
    required this.onUpload,
    required this.onEdit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.padding(context, 16);
    return Padding(
      padding: EdgeInsets.all(padding),
      child: ListView(
        children: [
          TextFormField(
            controller: gradDateCtrl,
            readOnly: true,
            onTap: onPickDate,
            decoration: InputDecoration(
              labelText: t('Graduation Date', 'تاريخ التخرج'),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(t('Graduation Certificate', 'شهادة التخرج'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: ResponsiveUtils.fontSize(context, 14))),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: Text(t('Photo', 'صورة')),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(t('File', 'ملف')),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Container(
            height: ResponsiveUtils.height(context) * 0.2,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: certificateFile != null ? Colors.green : (isDark ? Colors.white24 : Colors.grey[300]!)),
            ),
            child: certificateFile != null
                ? Center(child: Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
                    child: Text(certificateFile!.uri.pathSegments.last, textAlign: TextAlign.center, style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 12))),
                  ))
                : Center(child: Text(t('No file selected', 'لم يتم اختيار ملف'), style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 14)))),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          if (uploadedUrl != null) ...[
            SizedBox(
              height: ResponsiveUtils.buttonHeight(context),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: Text(t('Edit', 'تعديل')),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          ],
          SizedBox(
            height: ResponsiveUtils.buttonHeight(context),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!uploading && certificateFile != null) ? onUpload : null,
              icon: const Icon(Icons.cloud_upload),
              label: Text(
                uploading
                    ? t('Uploading...', 'جارٍ الرفع...')
                    : (uploadedUrl != null
                        ? t('Re-upload', 'إعادة رفع')
                        : t('Upload', 'رفع')),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          SizedBox(
            height: ResponsiveUtils.buttonHeight(context),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: uploadedUrl != null ? onNext : null,
              child: Text(t('Next', 'التالي')),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualificationsScreen extends StatelessWidget {
  final List<_QualificationItem> items;
  final bool isDark;
  final int? uploadingIndex;
  final VoidCallback onAdd;
  final void Function(int index) onDelete;
  final void Function(int index) onPickPhoto;
  final void Function(int index) onPickFile;
  final Future<void> Function(int index) onUpload;
  final VoidCallback onNext;
  final bool submitting;

  const _QualificationsScreen({
    required this.items,
    required this.isDark,
    required this.uploadingIndex,
    required this.onAdd,
    required this.onDelete,
    required this.onPickPhoto,
    required this.onPickFile,
    required this.onUpload,
    required this.onNext,
    required this.submitting,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.padding(context, 16);
    return Padding(
      padding: EdgeInsets.all(padding),
      child: ListView(
        children: [
          SizedBox(
            height: ResponsiveUtils.buttonHeight(context),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('Add Qualification', 'إضافة مؤهل')),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!)),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.padding(context, 12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: item.nameCtrl,
                            decoration: InputDecoration(labelText: t('Qualification Name', 'اسم المؤهل')),
                          ),
                        ),
                        IconButton(onPressed: () => onDelete(index), icon: const Icon(Icons.delete_outline, color: Colors.red)),
                        IconButton(onPressed: () => item.toggleEdit(), icon: const Icon(Icons.edit_outlined)),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: ResponsiveUtils.buttonHeight(context),
                          child: ElevatedButton.icon(
                            onPressed: () => onPickPhoto(index),
                            icon: const Icon(Icons.photo_library),
                            label: Text(t('Photo', 'صورة')),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        SizedBox(
                          height: ResponsiveUtils.buttonHeight(context),
                          child: OutlinedButton.icon(
                            onPressed: () => onPickFile(index),
                            icon: const Icon(Icons.attach_file),
                            label: Text(t('File', 'ملف')),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                        SizedBox(
                          height: ResponsiveUtils.buttonHeight(context),
                          child: ElevatedButton.icon(
                            onPressed: (item.file != null && uploadingIndex != index)
                                ? () => onUpload(index)
                                : null,
                            icon: const Icon(Icons.cloud_upload),
                            label: Text(
                              uploadingIndex == index
                                  ? t('Uploading...', 'جارٍ الرفع...')
                                  : (item.uploadedUrl != null
                                      ? t('Re-upload', 'إعادة الرفع')
                                      : t('Upload', 'رفع')),
                            ),
                          ),
                        ),
                        if (item.file != null) ...[
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            t('File: ', 'الملف: ') + item.file!.uri.pathSegments.last,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 12)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: submitting ? null : onNext,
            child: submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t('Return to Login', 'العودة لتسجيل الدخول')),
          ),
        ],
      ),
    );
  }
}

class _QualificationItem {
  final TextEditingController nameCtrl = TextEditingController();
  File? file;
  String? uploadedUrl;
  bool isEditing = true;
  void toggleEdit() {
    isEditing = !isEditing;
  }
}

class _ProgressHeader extends StatelessWidget {
  final int currentIndex; // 0..2
  final bool isDark;

  const _ProgressHeader({required this.currentIndex, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hPadding = ResponsiveUtils.padding(context, 16);
    final vPadding = ResponsiveUtils.padding(context, 12);
    final labels = [
      t('Primary', 'أساسي'),
      t('Graduation', 'التخرج'),
      t('Qualifications', 'المؤهلات'),
    ];
    const icons = [
      Icons.person_outline,
      Icons.school_outlined,
      Icons.workspace_premium_outlined,
    ];

    final progress = (currentIndex + 1) / 3.0;
    final bg = isDark ? const Color(0xFF0D1117) : Colors.white;
    final barColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF00BCD4);
    final muted = isDark ? Colors.white24 : Colors.black12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(color: bg, boxShadow: [BoxShadow(color: muted, blurRadius: 8)]),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final active = i <= currentIndex;
              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: active ? barColor : muted,
                      child: Icon(icons[i], size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: muted,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}
