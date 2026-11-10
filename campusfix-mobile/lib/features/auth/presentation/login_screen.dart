import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import 'providers/auth_provider.dart';

/// Live authentication entry screen for STUDENT and STAFF roles.
class LoginScreen extends ConsumerStatefulWidget {
  final String targetRole;
  final String? initialEmail;

  const LoginScreen({
    super.key,
    this.targetRole = AppConstants.roleStudent,
    this.initialEmail,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear any previous error before attempting
    ref.read(authNotifierProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authNotifierProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          targetRole: widget.targetRole,
        );

    if (mounted && !success) {
      final error =
          ref.read(authNotifierProvider).errorMessage ??
          'Invalid credentials or server error.';
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
    final targetRole = widget.targetRole.toUpperCase();
    final isStaff = targetRole == AppConstants.roleStaff;
    final isStudent = targetRole == AppConstants.roleStudent;
    final isAdmin = targetRole == AppConstants.roleAdmin;
    final roleLabel = isStaff
        ? 'Staff Member'
        : isAdmin
        ? 'Administrator'
        : 'Student';
    final portalLabel = isStaff
        ? 'STAFF PORTAL'
        : isAdmin
        ? 'ADMIN PORTAL'
        : 'STUDENT PORTAL';
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$roleLabel Login'),
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

                // Role badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isStaff
                          ? AppColors.primaryNavyMuted
                          : AppColors.accentGreenMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      portalLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isStaff
                            ? AppColors.primaryNavy
                            : AppColors.accentGreenDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Welcome Back',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to access your $roleLabel dashboard',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Error alert box if any
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
                  const SizedBox(height: 18),
                ],

                // Credentials Card
                AppCard(
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('loginEmailField'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'e.g. user@campus.edu',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address is required.';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('loginPasswordField'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            key: const Key('loginPasswordVisibilityToggle'),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required.';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).clearError();
                      context.push(RouteConstants.forgotPassword);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavyLight,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Submit Button
                AppButton(
                  key: const Key('loginSubmitButton'),
                  label: 'Sign In',
                  variant: AppButtonVariant.primary,
                  isLoading: authState.isLoading,
                  icon: Icons.login_rounded,
                  onPressed: authState.isLoading ? null : _handleLogin,
                ),

                const SizedBox(height: 24),

                // Student Registration Link (Only for Student Portal)
                if (isStudent) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).clearError();
                          context.push(RouteConstants.register);
                        },
                        child: const Text(
                          'Register as Student',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Role switch recommendation
                if (isStudent || isStaff)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).clearError();
                        final otherRole = isStaff
                            ? AppConstants.roleStudent
                            : AppConstants.roleStaff;
                        context.pushReplacement(
                          '${RouteConstants.login}?role=$otherRole',
                        );
                      },
                      child: Text(
                        isStaff
                            ? 'Switch to Student Portal'
                            : 'Switch to Staff Portal',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
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
