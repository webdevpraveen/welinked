import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/features/alerts/presentation/providers/alert_providers.dart';
import 'package:welinked/features/alerts/presentation/widgets/alert_card.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/shared/widgets/loading_widget.dart';
import 'package:welinked/shared/widgets/error_widget.dart';

class AlertHistoryScreen extends ConsumerWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentUserStreamProvider.select((u) => u.value?.uid));
    final activeAlerts = ref.watch(activeAlertsProvider);
    final controller = ref.read(alertControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
      ),
      body: SafeArea(
        child: uid == null
            ? const AppLoadingWidget(message: 'Loading user details...')
            : activeAlerts.when(
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Alerts Yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sent alerts and attention notifications will appear here.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      
                      // Auto-mark received alerts as seen when history is opened
                      if (alert.receiverUid == uid && alert.status == AlertStatus.delivered) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controller.markSeen(alert.alertId);
                        });
                      }

                      return AlertCard(
                        alert: alert,
                        currentUid: uid,
                        onSwipe: () {
                          controller.archive(alert.alertId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alert archived.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const AppLoadingWidget(message: 'Retrieving history...'),
                error: (err, stack) => AppErrorWidget(
                  message: 'Could not load alert history: $err',
                ),
              ),
      ),
    );
  }
}
