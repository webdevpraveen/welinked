import 'package:flutter/material.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/core/utils/date_utils.dart';
import 'package:welinked/features/alerts/domain/alert_model.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final String currentUid;
  final VoidCallback onSwipe;

  const AlertCard({
    super.key,
    required this.alert,
    required this.currentUid,
    required this.onSwipe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSentByMe = alert.senderUid == currentUid;
    
    // Status text & colors
    final isDelivered = alert.deliveredAt != null;
    final isSeen = alert.seenAt != null;
    final isAcknowledged = alert.acknowledgedAt != null;

    String statusText = 'Sent';
    Color statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    if (isAcknowledged) {
      statusText = 'Acknowledged';
      statusColor = const Color(0xFF43A047);
    } else if (isSeen) {
      statusText = 'Seen';
      statusColor = const Color(0xFFFFA726);
    } else if (isDelivered) {
      statusText = 'Delivered';
      statusColor = const Color(0xFF1E88E5);
    }

    final relativeTime = AppDateUtils.formatAlertTime(alert.createdAt);

    return Dismissible(
      key: Key(alert.alertId),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.error.withValues(alpha: 0.2),
        child: Icon(Icons.archive_outlined, color: theme.colorScheme.error),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.error.withValues(alpha: 0.2),
        child: Icon(Icons.archive_outlined, color: theme.colorScheme.error),
      ),
      onDismissed: (_) => onSwipe(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 8,
                  color: alert.alertType.color,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              alert.alertType.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: alert.alertType.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              relativeTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSentByMe 
                              ? 'You sent this alert' 
                              : 'Your partner sent this alert',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              _getStatusIcon(alert.status),
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAcknowledged && alert.acknowledgedAt != null) ...[
                              Text(
                                ' at ${AppDateUtils.formatTime(alert.acknowledgedAt!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ] else if (isSeen && alert.seenAt != null) ...[
                              Text(
                                ' at ${AppDateUtils.formatTime(alert.seenAt!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ] else if (isDelivered && alert.deliveredAt != null) ...[
                              Text(
                                ' at ${AppDateUtils.formatTime(alert.deliveredAt!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(AlertStatus status) {
    switch (status) {
      case AlertStatus.created:
        return Icons.arrow_outward;
      case AlertStatus.delivered:
        return Icons.done;
      case AlertStatus.seen:
        return Icons.visibility;
      case AlertStatus.acknowledged:
        return Icons.done_all;
    }
  }
}
