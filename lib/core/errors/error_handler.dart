import 'app_exception.dart';

class ErrorHandler {
  ErrorHandler._();

  static String getUserMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    if (error is CallException) {
      return error.message;
    }
    if (error is PermissionException) {
      return error.message;
    }
    if (error is StorageException) {
      return error.message;
    }
    if (error is UserNotFoundException) {
      return error.message;
    }
    if (error is AppException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
