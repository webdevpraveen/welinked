import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/features/pairing/data/pairing_repository.dart';
import 'package:welinked/features/pairing/domain/pair_request.dart';

/// Stream incoming partner requests
final incomingRequestsProvider = StreamProvider<List<PairRequest>>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(pairingRepositoryProvider).watchIncomingRequests(user.uid);
});

/// Stream outgoing partner requests
final outgoingRequestsProvider = StreamProvider<List<PairRequest>>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(pairingRepositoryProvider).watchOutgoingRequests(user.uid);
});

class PairingLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool val) {
    state = val;
  }
}

final pairingLoadingProvider = NotifierProvider<PairingLoadingNotifier, bool>(
  PairingLoadingNotifier.new,
);

class PairingController {
  final PairingRepository _repository;
  final Ref _ref;

  PairingController(this._repository, this._ref);

  Future<void> sendRequest(String targetEmail, {
    required VoidCallback onSuccess,
    required Function(String error) onError,
  }) async {
    final user = _ref.read(currentUserStreamProvider).value;
    if (user == null) {
      onError('User not authenticated');
      return;
    }

    _ref.read(pairingLoadingProvider.notifier).set(true);
    try {
      await _repository.sendPartnerRequest(
        fromUid: user.uid,
        fromName: user.name,
        fromEmail: user.email,
        toEmail: targetEmail,
      );
      onSuccess();
    } catch (e) {
      onError(e.toString());
    } finally {
      _ref.read(pairingLoadingProvider.notifier).set(false);
    }
  }

  Future<void> acceptRequest(PairRequest request, {
    required VoidCallback onSuccess,
    required Function(String error) onError,
  }) async {
    _ref.read(pairingLoadingProvider.notifier).set(true);
    try {
      await _repository.acceptPartnerRequest(request);
      onSuccess();
    } catch (e) {
      onError(e.toString());
    } finally {
      _ref.read(pairingLoadingProvider.notifier).set(false);
    }
  }
}

final pairingControllerProvider = Provider<PairingController>((ref) {
  return PairingController(ref.read(pairingRepositoryProvider), ref);
});
