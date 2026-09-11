import '../data/services/permission_service.dart';

class MockPermissionService implements PermissionService {
  PermissionStatus _micStatus = PermissionStatus.notRequested;
  PermissionStatus _cameraStatus = PermissionStatus.notRequested;

  @override
  Future<PermissionStatus> requestMicrophone() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _micStatus = PermissionStatus.granted;
    return _micStatus;
  }

  @override
  Future<PermissionStatus> requestCamera() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cameraStatus = PermissionStatus.granted;
    return _cameraStatus;
  }

  @override
  Future<PermissionStatus> checkMicrophone() async {
    return _micStatus;
  }

  @override
  Future<PermissionStatus> checkCamera() async {
    return _cameraStatus;
  }

  @override
  Future<void> openSettings() async {
    // Mock: no-op
  }
}
