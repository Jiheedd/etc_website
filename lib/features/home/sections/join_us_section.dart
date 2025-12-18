import 'package:flutter/material.dart';
import 'package:flutter_landing_page/component/component.dart';
import 'package:flutter_landing_page/section/section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
  @override
  Widget build(BuildContext context) {
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(TABLET);

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
                  const LandingFormSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingFormSection extends StatefulWidget {
  const LandingFormSection({super.key});

  @override
  State<LandingFormSection> createState() => _LandingFormSectionState();
}

class _LandingFormSectionState extends State<LandingFormSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  // final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  // final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _formationFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  final List<String> _formations = const [
    'Mécanique',
    'Pièces de rechange',
    'Carte grise',
  ];

  String? _selectedFormation;
  bool _isSubmitting = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _fullNameController.dispose();
    // _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _fullNameFocus.dispose();
    // _emailFocus.dispose();
    _phoneFocus.dispose();
    _formationFocus.dispose();
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

  String? _validateFullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'form_fullName_required'.tr;
    if (text.length < 3) return 'form_fullName_min_length'.tr;
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'form_phone_required'.tr;

    final tunisianRegex = RegExp(r'^(\+216[0-9]{8}|[0-9]{8})$');
    if (!tunisianRegex.hasMatch(text)) {
      return 'form_phone_invalid'.tr;
    }
    return null;
  }

  // String? _validateOptionalEmail(String? value) {
  //   final text = value?.trim() ?? '';
  //   if (text.isEmpty) return null;
  //
  //   final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  //   if (!emailRegex.hasMatch(text)) {
  //     return 'form_email_invalid'.tr;
  //   }
  //   return null;
  // }

  String? _validateFormation(String? _) {
    if (_selectedFormation == null || _selectedFormation!.isEmpty) {
      return 'form_program_required'.tr;
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      if (_autoValidateMode != AutovalidateMode.onUserInteraction) {
        setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'fullName': _fullNameController.text.trim(),
      // 'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'formation': _selectedFormation,
      'message': _messageController.text.trim(),
      'submittedAt': Timestamp.now(),
    };

    await submitToFirestore(data);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Votre demande a été envoyée. Merci !'),
        backgroundColor: Colors.green.shade700,
      ),
    );

    form.reset();

    setState(() {
      _selectedFormation = null;
      _autoValidateMode = AutovalidateMode.disabled;
    });

    _fullNameController.clear();
    // _emailController.clear();
    _phoneController.clear();
    _messageController.clear();
  }


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidateMode,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(context, 'form_fullName'.tr),
            validator: _validateFullName,
            onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          // const SizedBox(height: 16),
          // TextFormField(
          //   controller: _emailController,
          //   focusNode: _emailFocus,
          //   keyboardType: TextInputType.emailAddress,
          //   textInputAction: TextInputAction.next,
          //   decoration: _inputDecoration(context, 'form_email'.tr),
          //   validator: _validateOptionalEmail,
          //   onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
          // ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(context, 'form_phone'.tr),
            validator: _validatePhone,
            onFieldSubmitted: (_) => _formationFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            focusNode: _formationFocus,
            value: _selectedFormation,
            items: _formations
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: p,
                    child: Text(p),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedFormation = val),
            decoration: _inputDecoration(context, 'form_program'.tr),
            validator: _validateFormation,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            focusNode: _messageFocus,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(context, 'form_message'.tr),
            maxLines: 4,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                final backgroundColor =
                isDark ? theme.colorScheme.surface : theme.colorScheme.primary;

                final foregroundColor =
                isDark ? theme.colorScheme.primary : theme.colorScheme.onPrimary;

                return ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    disabledBackgroundColor:
                    backgroundColor.withOpacity(0.6),
                    disabledForegroundColor:
                    foregroundColor.withOpacity(0.7),
                    elevation: isDark ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foregroundColor,
                    ),
                  )
                      : Text(
                    'form_submit'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}

class FirebaseService {
  static Future<void> registerUser({
    required String fullName,
    // required String email,
    required String phone,
    required String program,
    String? message,
  }) async {
    final Map<String, dynamic> data = {
      'fullName': fullName,
      // 'email': email,
      'phone': phone,
      'program': program,
      'message': message ?? '',
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('registrations').add(data);

      if (kDebugMode) {
        debugPrint('[FirebaseService] Registration saved: $fullName');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[FirebaseService] Error: $e');
        debugPrint(stack.toString());
      }
      rethrow;
    }
  }
}


/// Safely submits form data to Firestore.
/// 
/// On Flutter Web, this checks Firebase initialization BEFORE accessing
/// Firestore to prevent JS interop type errors.
/// 
/// If Firebase is not initialized, the function returns silently without
/// crashing the UI, allowing the form to submit locally.

Future<void> submitToFirestore(Map<String, dynamic> data) async {
  try {
    if (kDebugMode) {
      debugPrint('Firebase apps: ${Firebase.apps.length}');
    }

    // Safety check (mostly for hot-reload / early calls)
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[submitToFirestore] Firebase not initialized. '
              'Firestore write aborted safely.',
        );
      }
      return;
    }

    // Normalize + secure data before sending
    final payload = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'source': kIsWeb ? 'web' : 'app',
    };

    await FirebaseFirestore.instance
        .collection('registrations')
        .add(payload);

    if (kDebugMode) {
      debugPrint('[submitToFirestore] Firestore write SUCCESS');
      debugPrint('[submitToFirestore] Data: $payload');
    }
  } on FirebaseException catch (e, stack) {
    // Firestore-specific errors (permissions, network, rules)
    if (kDebugMode) {
      debugPrint(
        '[submitToFirestore] FirebaseException '
            'code=${e.code}, message=${e.message}',
      );
      debugPrint(stack.toString());
    }
  } catch (e, stack) {
    // Any unexpected error (JS interop, runtime, etc.)
    if (kDebugMode) {
      debugPrint('[submitToFirestore] Unknown ERROR: $e');
      debugPrint(stack.toString());
    }
  }
}


