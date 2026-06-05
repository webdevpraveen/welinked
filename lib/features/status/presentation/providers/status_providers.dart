import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/auth/domain/app_user.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/features/status/data/status_repository.dart';

/// Stream of partner's entire profile document (for status dashboard).
final partnerStatusProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null || user.partnerUid == null) {
    return Stream.value(null);
  }
  return ref.watch(statusRepositoryProvider).watchPartner(user.partnerUid!);
});
