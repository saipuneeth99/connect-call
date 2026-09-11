enum PermissionStatus {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
}

abstract class PermissionService {
  Future<PermissionStatus> requestMicrophone();
  Future<PermissionStatus> requestCamera();
  Future<PermissionStatus> checkMicrophone();
  Future<PermissionStatus> checkCamera();
  Future<void> openSettings();
}
