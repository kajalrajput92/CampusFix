import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: CampusFixApp()));
}

/// Root widget of the CampusFix mobile application.
class CampusFixApp extends ConsumerStatefulWidget {
  const CampusFixApp({super.key});

  @override
  ConsumerState<CampusFixApp> createState() => _CampusFixAppState();
}

class _CampusFixAppState extends ConsumerState<CampusFixApp> {
  @override
  void initState() {
    super.initState();
    // Silently restore session from secure storage on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
