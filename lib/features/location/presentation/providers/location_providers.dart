import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/features/location/data/location_repository.dart';
import 'package:welinked/features/location/domain/user_location.dart';

/// Stream of partner's location updates.
final partnerLocationProvider = StreamProvider<UserLocation?>((ref) {
  final partnerUid = ref.watch(
    currentUserStreamProvider.select((userAsync) => userAsync.value?.partnerUid),
  );
  if (partnerUid == null || partnerUid.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(locationRepositoryProvider).watchPartnerLocation(partnerUid);
});
