import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partnerStatus = ref.watch(partnerStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Location'),
      ),
      body: partnerStatus.when(
        data: (partner) {
          if (partner == null) {
            return const AppErrorWidget(message: 'Could not fetch partner information.');
          }

          if (!partner.hasLocation) {
            return Center(
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
                      "${partner.name}'s location has not been updated yet. Updates sync automatically in the background.",
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

          final position = LatLng(partner.latitude!, partner.longitude!);
          final lastUpdatedStr = partner.locationUpdatedAt != null
              ? AppDateUtils.relativeTime(partner.locationUpdatedAt!)
              : 'Unknown';

          final markers = {
            Marker(
              markerId: MarkerId(partner.uid),
              position: position,
              infoWindow: InfoWindow(
                title: partner.name,
                snippet: 'Battery: ${partner.batteryPercentage}% | Last updated: $lastUpdatedStr',
              ),
            ),
          };

          // Auto center map on partner location update
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(position));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position,
                  zoom: 15.0,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 6,
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${partner.name}'s Location",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Last updated: $lastUpdatedStr',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            if (_mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(position, 15.5),
                              );
                            }
                          },
                          icon: const Icon(Icons.center_focus_strong_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingWidget(message: 'Locating partner...'),
        error: (err, stack) => AppErrorWidget(
          message: 'Failed to access location details: $err',
        ),
      ),
    );
  }
}
