/// Typed failure classes for consistent error handling across the app.
class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message (code: $code)';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.fromFirebase(String code) {
    switch (code) {
      case 'user-not-found':
        return const AuthFailure('No account found with this email.', code: 'user-not-found');
      case 'wrong-password':
        return const AuthFailure('Incorrect password.', code: 'wrong-password');
      case 'invalid-credential':
        return const AuthFailure('Invalid email or password.', code: 'invalid-credential');
      case 'email-already-in-use':
        return const AuthFailure('An account already exists with this email.', code: 'email-already-in-use');
      case 'weak-password':
        return const AuthFailure('Password is too weak. Use at least 6 characters.', code: 'weak-password');
      case 'invalid-email':
        return const AuthFailure('Invalid email address.', code: 'invalid-email');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Please try again later.', code: 'too-many-requests');
      case 'network-request-failed':
        return const AuthFailure('Network error. Check your internet connection.', code: 'network-request-failed');
      default:
        return AuthFailure('Authentication error: $code', code: code);
    }
  }
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class LocationFailure extends Failure {
  const LocationFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}
