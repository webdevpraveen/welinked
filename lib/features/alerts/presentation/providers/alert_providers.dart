import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/core/constants/alert_constants.dart';
import 'package:welinked/features/alerts/data/alert_repository.dart';
import 'package:welinked/features/alerts/domain/alert_model.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';

/// Stream of all active (non-archived) alerts involving the logged-in user.
final activeAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final uid = ref.watch(
    currentUserStreamProvider.select((userAsync) => userAsync.value?.uid),
  );
  if (uid == null) return Stream.value([]);
  return ref.watch(alertRepositoryProvider).watchAllAlerts(uid);
});

/// Tracking button cooldowns per alert type. Map of AlertType to end timestamp.
class AlertCooldownNotifier extends Notifier<Map<AlertType, DateTime>> {
  @override
  Map<AlertType, DateTime> build() => {};

  void startCooldown(AlertType type, Duration duration) {
    state = {
      ...state,
      type: DateTime.now().add(duration),
    };

    // Auto update state when timer completes — create new Map to avoid in-place mutation
    Timer(duration, () {
      final updated = Map<AlertType, DateTime>.from(state);
      updated.remove(type);
      state = updated;
    });
  }

  bool isCoolingDown(AlertType type) {
    final expiry = state[type];
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }
}

final alertCooldownProvider = NotifierProvider<AlertCooldownNotifier, Map<AlertType, DateTime>>(
  AlertCooldownNotifier.new,
);

class AlertController {
  final AlertRepository _repository;
  final Ref _ref;

  AlertController(this._repository, this._ref);

  Future<void> sendAlert(AlertType type, {
    required Function(String id) onSuccess,
    required Function(String error) onError,
  }) async {
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null || user.partnerUid == null) {
      onError('Unable to send alert. Make sure you are authenticated and paired.');
      return;
    }

    // Check cooldown
    final isCoolingDown = _ref.read(alertCooldownProvider.notifier).isCoolingDown(type);
    if (isCoolingDown) {
      onError('Please wait before sending this alert type again.');
      return;
    }

    try {
      final alertId = await _repository.createAlert(
        senderUid: user.uid,
        receiverUid: user.partnerUid!,
        alertType: type,
      );
      // Start 5-second cooldown
      _ref.read(alertCooldownProvider.notifier).startCooldown(type, const Duration(seconds: 5));
      onSuccess(alertId);
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> acknowledge(String alertId) async {
    try {
      await _repository.markAcknowledged(alertId);
    } catch (e) {
      // Background operation failure logging
    }
  }

  Future<void> markDelivered(String alertId) async {
    try {
      await _repository.markDelivered(alertId);
    } catch (e) {
      // Silent error logging
    }
  }

  Future<void> markSeen(String alertId) async {
    try {
      await _repository.markSeen(alertId);
    } catch (e) {
      // Silent error logging
    }
  }

  Future<void> archive(String alertId) async {
    try {
      await _repository.archiveAlert(alertId);
    } catch (e) {
      // Silent error logging
    }
  }
}

final alertControllerProvider = Provider<AlertController>((ref) {
  return AlertController(ref.read(alertRepositoryProvider), ref);
});
