import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:welinked/features/location/presentation/providers/location_providers.dart';
import 'package:welinked/features/status/presentation/providers/status_providers.dart';
import 'package:welinked/core/utils/date_utils.dart';
import 'package:welinked/shared/widgets/loading_widget.dart';
import 'package:welinked/shared/widgets/error_widget.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // BUG 12 fix: Use partnerLocationProvider for coordinates and timestamp.
    // Use partnerStatusProvider only for the partner's name to avoid rebuilding
    // the location screen on every status update (battery, online status etc.).
    final locationAsync = ref.watch(partnerLocationProvider);
    final partnerName = ref.watch(
      partnerStatusProvider.select((s) => s.value?.name ?? 'Duo'),
    );

    Widget body;
    final location = locationAsync.value;

    if (location == null) {
      if (locationAsync.isLoading) {
        body = const AppLoadingWidget(message: 'Locating Duo...');
      } else if (locationAsync.hasError) {
        body = const AppErrorWidget(message: 'Could not fetch Duo location.');
      } else {
        // No location data yet (null value, not loading, no error)
        body = Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Location Shared Yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$partnerName's location has not been updated yet. Updates sync automatically in the background.",
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
    } else {
      final lastUpdatedStr = AppDateUtils.relativeTime(location.timestamp);

      body = Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // Location Header card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      partnerName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: $lastUpdatedStr',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Coordinates display card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telemetry Coordinates',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Divider(height: 24),
                    _buildCoordinateRow(
                      label: 'Latitude',
                      value: location.latitude.toStringAsFixed(6),
                      icon: Icons.explore_outlined,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildCoordinateRow(
                      label: 'Longitude',
                      value: location.longitude.toStringAsFixed(6),
                      icon: Icons.explore_rounded,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Maps redirection action
            ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(location.latitude, location.longitude),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duo Location'),
      ),
      body: Stack(
        children: [
          body,
          if (location != null && locationAsync.isLoading)
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

  Widget _buildCoordinateRow({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
