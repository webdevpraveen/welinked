import 'package:flutter/material.dart';
import 'package:welinked/features/auth/domain/app_user.dart';
import 'package:welinked/core/utils/date_utils.dart';

class PartnerStatusCard extends StatelessWidget {
  final AppUser? partner;
  final bool isRefreshing;

  const PartnerStatusCard({super.key, this.partner, this.isRefreshing = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (partner == null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(
                'Connecting with duo...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isOnline = partner!.isOnline;
    final lastSeenStr = partner!.lastSeen != null
        ? AppDateUtils.relativeTime(partner!.lastSeen!)
        : 'Never';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        partner!.name.isNotEmpty
                            ? partner!.name[0].toUpperCase()
                            : 'P',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? const Color(0xFF43A047)
                                      : const Color(0xFF9E9E9E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline
                                    ? 'Online'
                                    : 'Offline (Last seen: $lastSeenStr)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatusItem(
                      icon: partner!.batteryPercentage > 20
                          ? Icons.battery_full_rounded
                          : Icons.battery_alert_rounded,
                      iconColor: partner!.batteryPercentage > 20
                          ? const Color(0xFF43A047)
                          : theme.colorScheme.error,
                      value: '${partner!.batteryPercentage}%',
                      label: 'Battery',
                    ),
                    _StatusItem(
                      icon: partner!.gpsEnabled
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_off_rounded,
                      iconColor: partner!.gpsEnabled
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFFE53935),
                      value: partner!.gpsEnabled ? 'ON' : 'OFF',
                      label: 'GPS',
                    ),
                    _StatusItem(
                      icon: partner!.internetConnected
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      iconColor: partner!.internetConnected
                          ? const Color(0xFF43A047)
                          : const Color(0xFFE53935),
                      value: partner!.internetConnected
                          ? 'Connected'
                          : 'Offline',
                      label: 'Internet',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isRefreshing)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatusItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
