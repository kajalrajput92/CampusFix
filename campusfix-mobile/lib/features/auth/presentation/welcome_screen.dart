import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

/// Branded initial welcome screen for CampusFix.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),

                      // CampusFix Brand Header
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNavy.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.apartment_rounded,
                              size: 48,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title & Tagline
                      const Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        AppConstants.appDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),

                      const Spacer(),

                      // Feature Highlights Card
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            _buildHighlightRow(
                              icon: Icons.qr_code_scanner_rounded,
                              title: 'QR-Enabled Reporting',
                              subtitle: 'Instant campus room & facility location detection',
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            _buildHighlightRow(
                              icon: Icons.track_changes_rounded,
                              title: 'Real-Time Tracking',
                              subtitle: 'Live complaint status progression from submission to fix',
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            _buildHighlightRow(
                              icon: Icons.verified_rounded,
                              title: 'Verified Resolution',
                              subtitle: 'Staff resolution proof notes with student ratings',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Entry Options
                      AppButton(
                        label: 'Student Portal',
                        variant: AppButtonVariant.primary,
                        icon: Icons.school_rounded,
                        onPressed: () {
                          context.push(
                            '/auth/login?role=${AppConstants.roleStudent}',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Staff Portal',
                        variant: AppButtonVariant.outlined,
                        icon: Icons.engineering_rounded,
                        onPressed: () {
                          context.push(
                            '/auth/login?role=${AppConstants.roleStaff}',
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Footer
                      const Text(
                        'CampusFix © College Infrastructure System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHighlightRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentGreenMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.accentGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
