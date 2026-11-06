import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'providers/auth_provider.dart';

/// Screen allowing the user to reset their password using a 64-char one-time token.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    ref.read(authNotifierProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final message = await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(
          token: _tokenController.text.trim(),
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Successfully reset -> route to student login
      context.go('${RouteConstants.login}?role=${AppConstants.roleStudent}');
    } else {
      final error =
          ref.read(authNotifierProvider).errorMessage ??
          'Password reset failed. The token may be expired or invalid.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authNotifierProvider.notifier).clearError();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteConstants.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Set New Password',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter the 64-character verification token received via email and choose a secure new password.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Error alert box
                if (authState.hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                AppCard(
                  child: Column(
                    children: [
                      // Token Input
                      TextFormField(
                        key: const Key('resetPasswordTokenField'),
                        controller: _tokenController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Reset Token *',
                          hintText: 'Paste 64-character token',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password reset token is required.';
                          }
                          final tokenRegex = RegExp(r'^[a-fA-F0-9]{64}$');
                          if (!tokenRegex.hasMatch(value.trim())) {
                            return 'Token must be a valid 64-character hexadecimal code.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // New Password Input
                      TextFormField(
                        key: const Key('resetPasswordNewField'),
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'New Password *',
                          helperText: 'Minimum 8 characters',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            key: const Key('resetPasswordNewToggle'),
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'New password is required.';
                          }
                          if (value.length < 8) {
                            return 'Password must contain at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Input
                      TextFormField(
                        key: const Key('resetPasswordConfirmField'),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleResetPassword(),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            key: const Key('resetPasswordConfirmToggle'),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password.';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  key: const Key('resetPasswordSubmitButton'),
                  label: 'Reset Password',
                  variant: AppButtonVariant.primary,
                  isLoading: _isSubmitting,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _isSubmitting ? null : _handleResetPassword,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).clearError();
                      context.go(RouteConstants.welcome);
                    },
                    child: const Text(
                      'Cancel and Return to Welcome',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
