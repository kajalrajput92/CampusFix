import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../data/complaint_models.dart';
import '../data/student_complaint_repository.dart';

final myComplaintsProvider = FutureProvider.autoDispose<List<ComplaintRecord>>(
  (ref) => ref.watch(studentComplaintRepositoryProvider).myComplaints(),
);
final complaintDetailsProvider = FutureProvider.autoDispose
    .family<ComplaintRecord, int>(
      (ref, id) =>
          ref.watch(studentComplaintRepositoryProvider).complaintDetails(id),
    );
final departmentsProvider = FutureProvider.autoDispose<List<CatalogOption>>(
  (ref) => ref.watch(studentComplaintRepositoryProvider).departments(),
);
final locationsProvider = FutureProvider.autoDispose<List<CatalogOption>>(
  (ref) => ref.watch(studentComplaintRepositoryProvider).locations(),
);
final myFeedbackProvider = FutureProvider.autoDispose<List<StudentFeedback>>(
  (ref) => ref.watch(studentComplaintRepositoryProvider).myFeedback(),
);
final notificationsProvider =
    FutureProvider.autoDispose<List<StudentNotification>>(
      (ref) => ref.watch(studentComplaintRepositoryProvider).notifications(),
    );

String _date(String value) {
  final date = DateTime.tryParse(value);
  return date == null
      ? value
      : DateFormat('d MMM yyyy, h:mm a').format(date.toLocal());
}

String _friendly(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
    .join(' ');
Color _statusColor(String status) => switch (status.toUpperCase()) {
  'RESOLVED' || 'CLOSED' => AppColors.accentGreen,
  'REJECTED' => AppColors.statusRejected,
  'IN_PROGRESS' || 'ASSIGNED' => AppColors.statusInProgress,
  _ => AppColors.statusSubmitted,
};

class MyComplaintsScreen extends ConsumerWidget {
  const MyComplaintsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myComplaintsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            onPressed: () => context.push('/student/notifications'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/student/complaints/new'),
        icon: const Icon(Icons.add),
        label: const Text('New complaint'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Problem(
          message: '$e',
          retry: () => ref.invalidate(myComplaintsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(myComplaintsProvider.future),
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 150),
                    _Empty(
                      icon: Icons.inbox_outlined,
                      title: 'No complaints yet',
                      subtitle: 'Report a campus issue to start tracking it.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return AppCard(
                      onTap: () => context.push('/student/complaints/${c.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _Status(status: c.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${c.number}  ·  ${c.category}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _date(c.createdAt),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
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

class SubmitComplaintScreen extends ConsumerStatefulWidget {
  final int? initialLocationId;
  const SubmitComplaintScreen({super.key, this.initialLocationId});
  @override
  ConsumerState<SubmitComplaintScreen> createState() =>
      _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends ConsumerState<SubmitComplaintScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  int? _department, _location;
  List<XFile> _images = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocationId;
  }
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final List<XFile> picks;
      if (source == ImageSource.gallery) {
        picks = await picker.pickMultiImage();
      } else {
        final image = await picker.pickImage(source: source);
        picks = image == null ? <XFile>[] : <XFile>[image];
      }
      if (!mounted) return;
      final allowed = <XFile>[];
      for (final image in picks) {
        final extension = image.name.toLowerCase().split('.').last;
        if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
          _message('${image.name}: use JPG, PNG, or WebP images.');
          continue;
        }
        if (await image.length() > 5 * 1024 * 1024) {
          _message('${image.name}: images must be 5 MB or smaller.');
          continue;
        }
        allowed.add(image);
      }
      if (!mounted) return;
      final available = 5 - _images.length;
      setState(() => _images = [..._images, ...allowed.take(available)]);
      if (allowed.length > available)
        _message('You can attach up to 5 images.');
    } catch (e) {
      _message('Could not select image: $e');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _openQrDialog(List<CatalogOption> options) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryNavy),
            SizedBox(width: 8),
            Text('Scan / Enter Room QR', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the code from the classroom QR card (e.g. CAMPUSFIX_LOC:2 or CF-002), or tap a campus room below:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. CAMPUSFIX_LOC:1 or 1',
                  prefixIcon: const Icon(Icons.qr_code, size: 20),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      final input = controller.text.trim();
                      if (input.isEmpty) return;
                      _applyQrCode(input, options, ctx);
                    },
                  ),
                ),
                onSubmitted: (val) => _applyQrCode(val, options, ctx),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verified Campus QR Locations:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = options[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CF-${item.id.toString().padLeft(3, '0')}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      title: Text(
                        item.label,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.primaryNavy,
                      ),
                      onTap: () {
                        setState(() => _location = item.id);
                        Navigator.pop(ctx);
                        _message('✓ Room location auto-detected: ${item.label}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyQrCode(String code, List<CatalogOption> options, BuildContext ctx) {
    final raw = code.toUpperCase().trim();
    int? matchedId;
    if (raw.contains('CAMPUSFIX_LOC:')) {
      matchedId = int.tryParse(raw.replaceAll('CAMPUSFIX_LOC:', '').trim());
    } else if (raw.contains('CF-')) {
      final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
      if (digits != null) matchedId = int.tryParse(digits);
    } else {
      matchedId = int.tryParse(raw);
    }

    CatalogOption? matched;
    if (matchedId != null) {
      matched = options.cast<CatalogOption?>().firstWhere(
        (opt) => opt?.id == matchedId,
        orElse: () => null,
      );
    }
    matched ??= options.cast<CatalogOption?>().firstWhere(
      (opt) => (opt?.label.toLowerCase() ?? '').contains(code.toLowerCase()),
      orElse: () => null,
    );

    if (matched != null) {
      setState(() => _location = matched!.id);
      Navigator.pop(ctx);
      _message('✓ Location identified via QR: ${matched.label}');
    } else {
      _message('Invalid or unrecognized QR location code: "$code"');
    }
  }
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_location == null) {
      _message('Select a campus location.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(studentComplaintRepositoryProvider)
          .submit(
            title: _title.text,
            description: _description.text,
            category: _category.text,
            locationId: _location!,
            departmentId: _department,
            images: _images,
          );
      ref.invalidate(myComplaintsProvider);
      if (mounted) {
        _message('Complaint submitted successfully.');
        context.pop();
      }
    } catch (e) {
      if (mounted) _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsProvider);
    final locations = ref.watch(locationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('New Complaint')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Describe the issue' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _category,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'For example: Electrical, Cleaning',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a category' : null,
            ),
            const SizedBox(height: 14),
            departments.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _CatalogRetry(
                message: 'Departments unavailable: $e',
                retry: () => ref.invalidate(departmentsProvider),
              ),
              data: (items) => DropdownButtonFormField<int>(
                initialValue: _department,
                decoration: const InputDecoration(
                  labelText: 'Department (optional)',
                  border: OutlineInputBorder(),
                ),
                items: items
                    .map(
                      (x) =>
                          DropdownMenuItem(value: x.id, child: Text(x.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _department = v),
              ),
            ),
            const SizedBox(height: 14),
            locations.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _CatalogRetry(
                message: 'Locations unavailable: $e',
                retry: () => ref.invalidate(locationsProvider),
              ),
              data: (items) {
                final selectedLocation = items
                    .cast<CatalogOption?>()
                    .firstWhere((x) => x?.id == _location, orElse: () => null);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _location != null
                            ? AppColors.accentGreen.withValues(alpha: 0.08)
                            : AppColors.primaryNavy.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _location != null
                              ? AppColors.accentGreen.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _location != null
                                ? Icons.verified_rounded
                                : Icons.qr_code_scanner_rounded,
                            color: _location != null
                                ? AppColors.accentGreen
                                : AppColors.primaryNavy,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _location != null
                                      ? 'Room Identified via QR'
                                      : 'QR-Enabled Location Detection',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _location != null
                                        ? AppColors.accentGreen
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  selectedLocation != null
                                      ? selectedLocation.label
                                      : 'Scan classroom QR code to auto-select room',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _location != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _openQrDialog(items),
                            icon: const Icon(Icons.qr_code_scanner, size: 16),
                            label: Text(
                              _location != null ? 'Rescan' : 'Scan QR',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: ValueKey(_location),
                      initialValue: _location,
                      decoration: const InputDecoration(
                        labelText: 'Or select campus location manually *',
                        border: OutlineInputBorder(),
                      ),
                      items: items
                          .map(
                            (x) => DropdownMenuItem(
                              value: x.id,
                              child: Text(
                                x.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _location = v),
                      validator: (v) => v == null ? 'Select a location' : null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Photos (up to 5, 5 MB each)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Choose from gallery',
                  onPressed: _images.length >= 5
                      ? null
                      : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                IconButton(
                  tooltip: 'Take photo',
                  onPressed: _images.length >= 5
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
              ],
            ),
            if (_images.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images
                    .asMap()
                    .entries
                    .map(
                      (entry) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(entry.value.path),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              onPressed: () =>
                                  setState(() => _images.removeAt(entry.key)),
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Submitting…' : 'Submit complaint'),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintDetailsScreen extends ConsumerWidget {
  final int complaintId;
  const ComplaintDetailsScreen({super.key, required this.complaintId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(complaintDetailsProvider(complaintId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(complaintDetailsProvider(complaintId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Problem(
          message: '$e',
          retry: () => ref.invalidate(complaintDetailsProvider(complaintId)),
        ),
        data: (c) {
          final feedbacks = ref.watch(myFeedbackProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(complaintDetailsProvider(complaintId));
              ref.invalidate(myFeedbackProvider);
              await ref.read(complaintDetailsProvider(complaintId).future);
            },
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
                              c.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          _Status(status: c.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        c.description ?? '',
                        style: const TextStyle(height: 1.5),
                      ),
                      const Divider(height: 28),
                      _Info(label: 'Category', value: c.category),
                      if (c.location?.isNotEmpty == true)
                        _Info(label: 'Location', value: c.location!),
                      _Info(label: 'Priority', value: _friendly(c.priority)),
                      _Info(label: 'Submitted', value: _date(c.createdAt)),
                      if (c.resolutionNotes?.isNotEmpty == true)
                        _Info(
                          label: 'Resolution notes',
                          value: c.resolutionNotes!,
                        ),
                    ],
                  ),
                ),
                if (c.images.isNotEmpty) ...[
                  const _SectionTitle('Photos'),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: c.images
                          .map(
                            (image) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _ComplaintPhoto(image: image),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (c.history.isNotEmpty) ...[
                  const _SectionTitle('Status history'),
                  AppCard(
                    child: Column(
                      children: c.history
                          .map(
                            (event) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.circle,
                                size: 12,
                                color: _statusColor(event.to),
                              ),
                              title: Text(
                                _friendly(event.to),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (event.remarks.isNotEmpty) event.remarks,
                                  if (event.changedAt.isNotEmpty)
                                    _date(event.changedAt),
                                ].join('\n'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (c.status.toUpperCase() == 'RESOLVED') ...[
                  const _SectionTitle('Your feedback'),
                  feedbacks.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => _Problem(
                      message: '$e',
                      retry: () => ref.invalidate(myFeedbackProvider),
                    ),
                    data: (list) {
                      final submitted = list
                          .where((f) => f.complaintId == c.id)
                          .firstOrNull;
                      return submitted != null
                          ? AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Your rating: ${submitted.rating}/5'),
                                  if (submitted.comments?.isNotEmpty == true)
                                    Text(submitted.comments!),
                                ],
                              ),
                            )
                          : _FeedbackForm(complaintId: c.id);
                    },
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

class _FeedbackForm extends ConsumerStatefulWidget {
  final int complaintId;
  const _FeedbackForm({required this.complaintId});
  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How was the resolution?'),
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: () => setState(() => _rating = i + 1),
              icon: Icon(
                i < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
            ),
          ),
        ),
        TextField(
          controller: _comment,
          maxLength: 2000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Comments (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await ref
                        .read(studentComplaintRepositoryProvider)
                        .submitFeedback(
                          widget.complaintId,
                          _rating,
                          _comment.text,
                        );
                    ref.invalidate(myFeedbackProvider);
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feedback submitted.')),
                      );
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('$e')));
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: Text(_busy ? 'Submitting…' : 'Send feedback'),
        ),
      ],
    ),
  );
}

class StudentNotificationsScreen extends ConsumerWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Problem(
          message: '$e',
          retry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider.future),
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 150),
                    _Empty(
                      icon: Icons.notifications_none,
                      title: 'All caught up',
                      subtitle:
                          'Updates about your complaints will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return AppCard(
                      onTap: () async {
                        if (!n.isRead) {
                          try {
                            await ref
                                .read(studentComplaintRepositoryProvider)
                                .markNotificationRead(n.id);
                            ref.invalidate(notificationsProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        }
                        if (n.complaintId != null && context.mounted) {
                          context.push('/student/complaints/${n.complaintId}');
                        }
                      },
                      backgroundColor: n.isRead
                          ? null
                          : AppColors.accentGreenMuted,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            n.isRead
                                ? Icons.notifications_none
                                : Icons.notifications_active_outlined,
                            color: AppColors.accentGreenDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(n.message),
                                const SizedBox(height: 8),
                                Text(
                                  _date(n.createdAt),
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

class _ComplaintPhoto extends ConsumerWidget {
  final ComplaintImage image;
  const _ComplaintPhoto({required this.image});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (image.id <= 0)
      return const SizedBox(
        width: 170,
        height: 120,
        child: Center(child: Text('Image unavailable')),
      );
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
        error: (_, _) => const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final String status;
  const _Status({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _friendly(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label, value;
  const _Info({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 98,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Empty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 48, color: AppColors.textMuted),
      const SizedBox(height: 12),
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _Problem extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _Problem({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.textMuted,
          ),
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

class _CatalogRetry extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _CatalogRetry({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.statusRejected),
        ),
      ),
      IconButton(onPressed: retry, icon: const Icon(Icons.refresh)),
    ],
  );
}
