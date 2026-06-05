import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/router/app_router.dart';
import 'package:welinked/core/theme/app_theme.dart';
import 'package:welinked/core/constants/app_constants.dart';

class WeLinkedApp extends ConsumerWidget {
  const WeLinkedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
