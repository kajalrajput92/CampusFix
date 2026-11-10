import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'staff_complaint_screens.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentUserProvider);
    final assignments = ref.watch(staffAssignmentsProvider);
    final notifications = ref.watch(staffNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/staff/notifications'),
            icon: Badge(
              isLabelVisible: (notifications.valueOrNull ?? const []).any(
                (item) => !item.isRead,
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait<Object?>([
              ref.refresh(staffAssignmentsProvider.future),
              ref.refresh(staffNotificationsProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavyMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: AppColors.primaryNavy,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${session?.fullName.isNotEmpty == true ? session!.fullName : 'Staff Member'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session?.email ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              assignments.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _DashboardError(
                  message: '$error',
                  retry: () => ref.invalidate(staffAssignmentsProvider),
                ),
                data: (items) {
                  final pending = items
                      .where((item) => item.status == 'ASSIGNED')
                      .length;
                  final inProgress = items
                      .where((item) => item.status == 'IN_PROGRESS')
                      .length;
                  final resolved = items
                      .where((item) => item.status == 'RESOLVED')
                      .length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _CountCard(
                              label: 'Assigned',
                              count: items.length,
                              icon: Icons.assignment_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CountCard(
                              label: 'Pending',
                              count: pending,
                              icon: Icons.pending_actions_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _CountCard(
                              label: 'In progress',
                              count: inProgress,
                              icon: Icons.autorenew_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CountCard(
                              label: 'Resolved',
                              count: resolved,
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.push('/staff/complaints'),
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('View assigned complaints'),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Recent assignments',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (items.isEmpty)
                        const AppCard(
                          child: Text(
                            'No complaints are currently assigned to you.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...items
                            .take(3)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AppCard(
                                  onTap: () => context.push(
                                    '/staff/complaints/${item.complaintId}',
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${item.complaintNumber} · ${item.category} · ${item.status.replaceAll('_', ' ')}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 8),
                      notifications.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, _) => _DashboardError(
                          message: '$error',
                          retry: () =>
                              ref.invalidate(staffNotificationsProvider),
                        ),
                        data: (items) => TextButton.icon(
                          onPressed: () => context.push('/staff/notifications'),
                          icon: const Icon(Icons.notifications_outlined),
                          label: Text('Notifications (${items.length})'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primaryNavy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _DashboardError({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
