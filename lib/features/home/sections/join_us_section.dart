import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Developer notes:
/// - Add `cloud_firestore` to `pubspec.yaml` under dependencies.
/// - Initialize Firebase in `main.dart` before running the app:
///   - `WidgetsFlutterBinding.ensureInitialized();`
///   - `await Firebase.initializeApp();`
/// - Then generate and run as usual.
class JoinUsSection extends ConsumerStatefulWidget {
  const JoinUsSection({super.key});

  @override
  ConsumerState<JoinUsSection> createState() => _JoinUsSectionState();
}

class _JoinUsSectionState extends ConsumerState<JoinUsSection> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _programFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  final List<String> _programs = const [
    'Mécanique',
    'Pièces de rechange',
    'Carte grise',
  ];

  String? _selectedProgram;
  bool _isSubmitting = false;

  bool get _isFormValid =>
      (_formKey.currentState?.validate() ?? false) &&
      _selectedProgram != null &&
      _selectedProgram!.isNotEmpty;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _programFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _validateEmail(
      String? value, String requiredMessage, String invalidMessage) {
    if (value == null || value.trim().isEmpty) return requiredMessage;
    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return invalidMessage;
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final currentState = _formKey.currentState;
    if (currentState == null) return;
    if (!currentState.validate()) return;
    if (_selectedProgram == null || _selectedProgram!.isEmpty) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('form_program_required'.tr),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseService.registerUser(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        program: _selectedProgram!,
        message: _messageController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          content: Text('form_success'.tr),
        ),
      );

      _formKey.currentState?.reset();
      setState(() {
        _selectedProgram = null;
      });
      _fullNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _messageController.clear();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final snackBar = SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content:
            Text('form_error'.tr + (e.message != null ? ' ${e.message!}' : '')),
        action: SnackBarAction(
          label: 'join_us_submit'.tr,
          textColor: Colors.white,
          onPressed: _submit,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (_) {
      if (!mounted) return;
      final snackBar = SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text('form_error'.tr),
        action: SnackBarAction(
          label: 'join_us_submit'.tr,
          textColor: Colors.white,
          onPressed: _submit,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final offset = box.localToGlobal(Offset.zero).dy;
            ref.read(scrollNotifierProvider.notifier).updateSectionPosition(
                  section: Section.joinUs,
                  dy: offset,
                );
          }
        });

        final maxWidth = isLargeScreen ? 720.0 : 560.0;
        final horizontalPadding = isLargeScreen ? 24.0 : 16.0;

        return Container(
          key: const ValueKey(Section.joinUs),
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: horizontalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'form_title'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        onChanged: () => setState(() {}),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  _inputDecoration(context, 'form_fullName'.tr),
                              validator: (v) => _validateRequired(
                                  v, 'form_fullName_required'.tr),
                              onFieldSubmitted: (_) =>
                                  _emailFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  _inputDecoration(context, 'form_email'.tr),
                              validator: (v) => _validateEmail(
                                v,
                                'form_email_required'.tr,
                                'form_email_invalid'.tr,
                              ),
                              onFieldSubmitted: (_) =>
                                  _phoneFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  _inputDecoration(context, 'form_phone'.tr),
                              validator: (v) => _validateRequired(
                                  v, 'form_phone_required'.tr),
                              onFieldSubmitted: (_) =>
                                  _programFocus.requestFocus(),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              focusNode: _programFocus,
                              value: _selectedProgram,
                              items: _programs
                                  .map((p) => DropdownMenuItem<String>(
                                        value: p,
                                        child: Text(p),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedProgram = val),
                              decoration:
                                  _inputDecoration(context, 'form_program'.tr),
                              validator: (_) => (_selectedProgram == null ||
                                      _selectedProgram!.isEmpty)
                                  ? 'form_program_required'.tr
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              focusNode: _messageFocus,
                              textInputAction: TextInputAction.done,
                              decoration:
                                  _inputDecoration(context, 'form_message'.tr),
                              maxLines: 4,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSubmitting || !_isFormValid
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5),
                                      )
                                    : Text('form_submit'.tr),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FirebaseService {
  static Future<void> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String program,
    String? message,
  }) async {
    final Map<String, dynamic> data = {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'program': program,
      'message': message ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('registrations').add(data);
      if (kDebugMode) {
        debugPrint(
            '[FirebaseService.registerUser] Success adding registration for "$fullName"');
      }
    } on FirebaseException catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
            '[FirebaseService.registerUser] FirebaseException code=${e.code} message=${e.message}');
        debugPrint(stack.toString());
      }
      rethrow;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[FirebaseService.registerUser] Unknown error: $e');
        debugPrint(stack.toString());
      }
      rethrow;
    }
  }
}
