import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../student/data/complaint_models.dart';
import '../../student/data/student_complaint_repository.dart';
import '../data/staff_complaint_models.dart';
import '../data/staff_complaint_repository.dart';

final staffAssignmentsProvider =
    FutureProvider.autoDispose<List<StaffAssignment>>(
      (ref) => ref.watch(staffComplaintRepositoryProvider).myAssignments(),
    );
final staffNotificationsProvider =
    FutureProvider.autoDispose<List<StudentNotification>>(
      (ref) => ref.watch(staffComplaintRepositoryProvider).notifications(),
    );
final staffComplaintDetailsProvider = FutureProvider.autoDispose
    .family<ComplaintRecord, int>(
      (ref, id) =>
          ref.watch(staffComplaintRepositoryProvider).complaintDetails(id),
    );

String _staffDate(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? value
      : DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
}

String _staffLabel(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

Color _staffStatusColor(String value) => switch (value.toUpperCase()) {
  'RESOLVED' || 'CLOSED' => AppColors.accentGreen,
  'REJECTED' => AppColors.statusRejected,
  'IN_PROGRESS' => AppColors.statusInProgress,
  _ => AppColors.statusSubmitted,
};

class StaffAssignmentsScreen extends ConsumerWidget {
  const StaffAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(staffAssignmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Complaints'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/staff/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: assignments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StaffError(
          message: '$error',
          retry: () => ref.invalidate(staffAssignmentsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(staffAssignmentsProvider.future),
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 150),
                    _StaffEmpty(
                      icon: Icons.assignment_outlined,
                      title: 'No assigned complaints',
                      subtitle: 'New assignments will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _AssignmentCard(
                    assignment: items[index],
                    onTap: () => context.push(
                      '/staff/complaints/${items[index].complaintId}',
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class StaffComplaintDetailsScreen extends ConsumerStatefulWidget {
  final int complaintId;
  const StaffComplaintDetailsScreen({super.key, required this.complaintId});

  @override
  ConsumerState<StaffComplaintDetailsScreen> createState() =>
      _StaffComplaintDetailsScreenState();
}

class _StaffComplaintDetailsScreenState
    extends ConsumerState<StaffComplaintDetailsScreen> {
  final _resolutionNotes = TextEditingController();
  bool _updating = false;

  @override
  void dispose() {
    _resolutionNotes.dispose();
    super.dispose();
  }

  Future<void> _update(int complaintId, String status) async {
    if (_updating) return;
    final validation = validateStaffStatusUpdate(status, _resolutionNotes.text);
    if (validation != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    setState(() => _updating = true);
    try {
      await ref
          .read(staffComplaintRepositoryProvider)
          .updateStatus(
            complaintId: complaintId,
            status: status,
            resolutionNotes: status == 'RESOLVED'
                ? _resolutionNotes.text
                : null,
          );
      ref.invalidate(staffAssignmentsProvider);
      ref.invalidate(staffComplaintDetailsProvider(complaintId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint marked ${_staffLabel(status)}.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintState = ref.watch(
      staffComplaintDetailsProvider(widget.complaintId),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(
              staffComplaintDetailsProvider(widget.complaintId),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: complaintState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StaffError(
          message: '$error',
          retry: () =>
              ref.invalidate(staffComplaintDetailsProvider(widget.complaintId)),
        ),
        data: (complaint) {
          final nextStatus = nextStaffComplaintStatus(complaint.status);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(
              staffComplaintDetailsProvider(widget.complaintId).future,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              complaint.complaintNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          _StaffStatus(status: complaint.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        complaint.description ?? '',
                        style: const TextStyle(height: 1.5),
                      ),
                      const Divider(height: 28),
                      _StaffInfo(label: 'Category', value: complaint.category),
                      _StaffInfo(label: 'Priority', value: complaint.priority),
                      _StaffInfo(
                        label: 'Submitted',
                        value: _staffDate(complaint.createdAt),
                      ),
                      _StaffInfo(
                        label: 'Assigned',
                        value: _staffDate(complaint.assignedAt ?? ''),
                      ),
                      if (complaint.location?.isNotEmpty == true)
                        _StaffInfo(
                          label: 'Location',
                          value: complaint.location!,
                        ),
                      if (complaint.resolutionNotes?.isNotEmpty == true)
                        _StaffInfo(
                          label: 'Resolution notes',
                          value: complaint.resolutionNotes!,
                        ),
                    ],
                  ),
                ),
                if (complaint.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Attachments',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: complaint.images
                          .map(
                            (image) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _StaffPhoto(image: image),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (complaint.history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Status history',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  AppCard(
                    child: Column(
                      children: complaint.history
                          .map(
                            (event) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.circle,
                                size: 11,
                                color: _staffStatusColor(event.to),
                              ),
                              title: Text(_staffLabel(event.to)),
                              subtitle: Text(
                                [
                                  if (event.remarks.isNotEmpty) event.remarks,
                                  if (event.changedAt.isNotEmpty)
                                    _staffDate(event.changedAt),
                                ].join('\n'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (nextStatus == 'IN_PROGRESS') ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _updating
                        ? null
                        : () => _update(complaint.id, 'IN_PROGRESS'),
                    icon: _updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start work'),
                  ),
                ],
                if (nextStatus == 'RESOLVED') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _resolutionNotes,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Resolution notes',
                      hintText: 'Describe the work completed',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _updating
                        ? null
                        : () => _update(complaint.id, 'RESOLVED'),
                    icon: _updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Mark resolved'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class StaffNotificationsScreen extends ConsumerWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(staffNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Notifications')),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StaffError(
          message: '$error',
          retry: () => ref.invalidate(staffNotificationsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(staffNotificationsProvider.future),
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 150),
                    _StaffEmpty(
                      icon: Icons.notifications_none,
                      title: 'No notifications',
                      subtitle: 'Updates about assignments will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = items[index];
                    return AppCard(
                      backgroundColor: notification.isRead
                          ? null
                          : AppColors.primaryNavyMuted,
                      onTap: () async {
                        if (!notification.isRead) {
                          try {
                            await ref
                                .read(staffComplaintRepositoryProvider)
                                .markNotificationRead(notification.id);
                            ref.invalidate(staffNotificationsProvider);
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$error')));
                            }
                          }
                        }
                        if (notification.complaintId != null &&
                            context.mounted) {
                          context.push(
                            '/staff/complaints/${notification.complaintId}',
                          );
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            notification.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active_outlined,
                            color: AppColors.primaryNavy,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(notification.message),
                                const SizedBox(height: 8),
                                Text(
                                  _staffDate(notification.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final StaffAssignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                assignment.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            _StaffStatus(status: assignment.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${assignment.complaintNumber} · ${assignment.category}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 5),
        Text(
          '${_staffLabel(assignment.priority)} priority · ${_staffDate(assignment.createdAt)}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _StaffPhoto extends ConsumerWidget {
  final ComplaintImage image;
  const _StaffPhoto({required this.image});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (image.id <= 0) {
      return const SizedBox(
        width: 170,
        child: Center(child: Text('Image unavailable')),
      );
    }
    final state = ref.watch(complaintImageBytesProvider(image.id));
    return Container(
      width: 170,
      height: 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: state.when(
        data: (bytes) => Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Icon(Icons.image_not_supported_outlined)),
      ),
    );
  }
}

class _StaffStatus extends StatelessWidget {
  final String status;
  const _StaffStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _staffStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _staffLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StaffInfo extends StatelessWidget {
  final String label;
  final String value;
  const _StaffInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _StaffEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StaffEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(icon, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _StaffError extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _StaffError({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
