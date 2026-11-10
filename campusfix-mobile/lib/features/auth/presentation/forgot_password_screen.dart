import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'providers/auth_provider.dart';

/// Password recovery request screen connecting to POST /api/auth/forgot-password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitted = false;
  String? _serverMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    ref.read(authNotifierProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final message = await ref
        .read(authNotifierProvider.notifier)
        .forgotPassword(email: _emailController.text.trim());

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (message != null) {
      setState(() {
        _isSubmitted = true;
        _serverMessage = message;
      });
    } else {
      final error =
          ref.read(authNotifierProvider).errorMessage ??
          'Unable to process password reset request. Please try again.';
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
        title: const Text('Forgot Password'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: _isSubmitted
              ? _buildSuccessView(context)
              : _buildRequestForm(context, authState),
        ),
      ),
    );
  }

  Widget _buildRequestForm(BuildContext context, dynamic authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryNavyMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Reset Your Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address registered with your CampusFix account. If an account is found, reset instructions will be sent.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          AppCard(
            child: TextFormField(
              key: const Key('forgotPasswordEmailField'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleForgotPassword(),
              decoration: const InputDecoration(
                labelText: 'Account Email Address',
                hintText: 'e.g. user@campus.edu',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email address is required.';
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            key: const Key('forgotPasswordSubmitButton'),
            label: 'Send Reset Instructions',
            variant: AppButtonVariant.primary,
            isLoading: _isSubmitting,
            icon: Icons.send_rounded,
            onPressed: _isSubmitting ? null : _handleForgotPassword,
          ),
          const SizedBox(height: 16),

          // Direct token entry option
          AppButton(
            label: 'I Have a Reset Token',
            variant: AppButtonVariant.outlined,
            onPressed: () {
              ref.read(authNotifierProvider.notifier).clearError();
              context.push(RouteConstants.resetPassword);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentGreenMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 42,
              color: AppColors.accentGreenDark,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Check Your Inbox',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _serverMessage ?? 'If an account exists with this email, password reset instructions will be sent.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: 'Enter Received Token',
            variant: AppButtonVariant.primary,
            icon: Icons.vpn_key_rounded,
            onPressed: () {
              context.pushReplacement(RouteConstants.resetPassword);
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Return to Login',
            variant: AppButtonVariant.outlined,
            onPressed: () {
              context.go(RouteConstants.welcome);
            },
          ),
        ],
      ),
    );
  }
}
