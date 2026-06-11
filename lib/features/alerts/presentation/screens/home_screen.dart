import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/features/alerts/presentation/providers/alert_providers.dart';
import 'package:welinked/features/alerts/presentation/widgets/alert_button.dart';
import 'package:welinked/features/status/presentation/providers/status_providers.dart';
import 'package:welinked/features/status/presentation/widgets/partner_status_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final partnerStatus = ref.watch(partnerStatusProvider);
    final alertController = ref.read(alertControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeLinked'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartnerStatusCard(
                partner: partnerStatus.hasValue ? partnerStatus.value : null,
                isRefreshing: partnerStatus.isLoading,
              ),
              const SizedBox(height: 24),
              Text(
                'Send Attention Alert',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                    AlertButton(
                      type: AlertType.red,
                      onTap: () => alertController.sendAlert(
                        AlertType.red,
                        onSuccess: (id) => _showSuccessSnack(context, 'RED ALERT sent!'),
                        onError: (err) => _showErrorSnack(context, err),
                      ),
                    ),
                    AlertButton(
                      type: AlertType.green,
                      onTap: () => alertController.sendAlert(
                        AlertType.green,
                        onSuccess: (id) => _showSuccessSnack(context, 'GREEN ALERT sent!'),
                        onError: (err) => _showErrorSnack(context, err),
                      ),
                    ),
                    AlertButton(
                      type: AlertType.blue,
                      onTap: () => alertController.sendAlert(
                        AlertType.blue,
                        onSuccess: (id) => _showSuccessSnack(context, 'BLUE ALERT sent!'),
                        onError: (err) => _showErrorSnack(context, err),
                      ),
                    ),
                    AlertButton(
                      type: AlertType.yellow,
                      onTap: () => alertController.sendAlert(
                        AlertType.yellow,
                        onSuccess: (id) => _showSuccessSnack(context, 'YELLOW ALERT sent!'),
                        onError: (err) => _showErrorSnack(context, err),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
