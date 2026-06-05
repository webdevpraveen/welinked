import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/core/utils/permission_utils.dart';
import 'package:welinked/features/settings/presentation/providers/settings_providers.dart';
import 'package:welinked/features/status/presentation/providers/status_providers.dart';
import 'package:welinked/shared/widgets/loading_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, bool> _permissionStatus = {
    'Notifications': false,
    'Location': false,
    'Background Location': false,
    'Battery Optimization': false,
  };
  bool _loadingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loadingPermissions = true);
    final summary = await PermissionUtils.getPermissionSummary();
    if (mounted) {
      setState(() {
        _permissionStatus = summary;
        _loadingPermissions = false;
      });
    }
  }

  void _requestPermission(String type) async {
    bool granted = false;
    if (type == 'Notifications') {
      granted = await PermissionUtils.requestNotificationPermission();
    } else if (type == 'Location') {
      granted = await PermissionUtils.requestLocationPermission();
    } else if (type == 'Background Location') {
      granted = await PermissionUtils.requestBackgroundLocationPermission();
    } else if (type == 'Battery Optimization') {
      granted = await PermissionUtils.requestIgnoreBatteryOptimizations();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? '$type permission granted!' : '$type permission request failed.'),
          duration: const Duration(seconds: 1),
        ),
      );
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partner = ref.watch(partnerStatusProvider).value;
    final settingsAsync = ref.watch(alertSettingsProvider);
    final settingsController = ref.read(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Partner Profile Banner
            if (partner != null) ...[
              Card(
                color: theme.colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
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
                              'Paired Partner',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            Text(
                              partner.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              partner.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Sound Toggle Settings
            Text(
              'Alert Tone Settings',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            settingsAsync.when(
              data: (settings) => Card(
                child: Column(
                  children: [
                    _buildSoundTile(
                      type: AlertType.red,
                      value: settings.redSoundEnabled,
                      onChanged: (val) => settingsController.updateSoundSetting('red', val),
                    ),
                    const Divider(height: 1),
                    _buildSoundTile(
                      type: AlertType.green,
                      value: settings.greenSoundEnabled,
                      onChanged: (val) => settingsController.updateSoundSetting('green', val),
                    ),
                    const Divider(height: 1),
                    _buildSoundTile(
                      type: AlertType.blue,
                      value: settings.blueSoundEnabled,
                      onChanged: (val) => settingsController.updateSoundSetting('blue', val),
                    ),
                    const Divider(height: 1),
                    _buildSoundTile(
                      type: AlertType.yellow,
                      value: settings.yellowSoundEnabled,
                      onChanged: (val) => settingsController.updateSoundSetting('yellow', val),
                    ),
                  ],
                ),
              ),
              loading: () => const Card(child: Padding(padding: EdgeInsets.all(24), child: AppLoadingWidget())),
              error: (err, stack) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $err'))),
            ),
            const SizedBox(height: 24),

            // Permissions Status Wizard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Permissions Wizard',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _checkPermissions,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: _loadingPermissions
                  ? const Padding(padding: EdgeInsets.all(24), child: AppLoadingWidget())
                  : Column(
                      children: _permissionStatus.entries.map((entry) {
                        final permissionName = entry.key;
                        final isGranted = entry.value;

                        return ListTile(
                          title: Text(permissionName),
                          leading: Icon(
                            isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: isGranted ? const Color(0xFF43A047) : theme.colorScheme.error,
                          ),
                          trailing: isGranted
                              ? const Icon(Icons.done, color: Colors.green)
                              : TextButton(
                                  onPressed: () => _requestPermission(permissionName),
                                  child: const Text('Fix'),
                                ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // Xiaomi Device Optimization Instructions
            Text(
              'Xiaomi / Redmi Reliability Guide',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Ensure Alerts Deliver on MIUI / HyperOS',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuideStep(
                      step: '1',
                      title: 'Enable Auto Start',
                      description: 'Long press WeLinked app icon → App Info → Enable "Auto Start". This allows the background service to launch on system boot.',
                    ),
                    const SizedBox(height: 12),
                    _buildGuideStep(
                      step: '2',
                      title: 'Set Battery Saver to No Restrictions',
                      description: 'App Info → Battery Saver → Select "No Restrictions". Ensures MIUI won\'t kill the background tracking service.',
                    ),
                    const SizedBox(height: 12),
                    _buildGuideStep(
                      step: '3',
                      title: 'Allow Display Over Other Apps',
                      description: 'App Info → Other Permissions → Enable "Show on Lock screen" and "Display pop-up windows while running in the background" to show instant full-screen alert screens.',
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.settings_phone),
                        label: const Text('Open System App Settings'),
                        onPressed: () => PermissionUtils.openSettings(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTile({
    required AlertType type,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(type.icon, color: type.color),
      title: Text(type.title),
      subtitle: const Text('Play sound on incoming alert'),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGuideStep({
    required String step,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            step,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
