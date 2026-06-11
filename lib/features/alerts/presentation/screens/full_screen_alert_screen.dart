import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/alerts/domain/alert_model.dart';
import 'package:welinked/features/alerts/presentation/providers/alert_providers.dart';
import 'package:welinked/services/audio_service.dart';
import 'package:welinked/services/wakelock_service.dart';
import 'package:vibration/vibration.dart';

class FullScreenAlertScreen extends ConsumerStatefulWidget {
  final AlertModel alert;
  final String senderName;

  const FullScreenAlertScreen({
    super.key,
    required this.alert,
    required this.senderName,
  });

  @override
  ConsumerState<FullScreenAlertScreen> createState() => _FullScreenAlertScreenState();
}

class _FullScreenAlertScreenState extends ConsumerState<FullScreenAlertScreen> {
  int _secondsRemaining = 10;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initAlertBehavior();
  }

  void _initAlertBehavior() async {
    // Acquire wake lock to keep screen on
    await WakeLockService.acquire();

    // Start vibrating
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
    }

    // Play Alert Audio
    final audioService = ref.read(audioServiceProvider);
    await audioService.playAlertAudio(widget.alert.alertType);

    // Mark alert as delivered when full screen overlay opens
    ref.read(alertControllerProvider).markDelivered(widget.alert.alertId);

    // Start 10-second dismiss timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 1) {
        _dismissAlert();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _acknowledge() {
    HapticFeedback.heavyImpact();
    ref.read(alertControllerProvider).acknowledge(widget.alert.alertId);
    _dismissAlert();
  }

  void _dismissAlert() {
    _cleanup();
    Navigator.of(context).pop();
  }

  void _cleanup() {
    _countdownTimer?.cancel();
    Vibration.cancel();
    ref.read(audioServiceProvider).stopAudio();
    WakeLockService.release();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.alert.alertType;

    return PopScope(
      canPop: false, // Prevent back-button dismissing
      child: Scaffold(
        backgroundColor: type.color,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Auto-dismissing in ${_secondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 100,
                      color: type.textColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      type.title,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: type.textColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'From: ${widget.senderName}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: type.textColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    onPressed: _acknowledge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: type.color,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
