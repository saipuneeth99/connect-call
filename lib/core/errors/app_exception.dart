class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'Network error. Please check your connection.',
      ]);
}

class CallException extends AppException {
  const CallException(super.message, {super.code, super.originalError});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

class UserNotFoundException extends AppException {
  const UserNotFoundException([super.message = 'User not found.']);
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}
