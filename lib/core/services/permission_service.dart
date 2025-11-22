import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class PermissionService {
  /// Solicita permisos para acceder a la cámara o galería
  Future<bool> requestImagePermission(ImageSource source) async {
    Permission permission;
    
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      permission = Permission.photos;
    }

    // Verificar si ya tiene el permiso
    PermissionStatus status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }

    // Solicitar permiso
    status = await permission.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // El usuario denegó el permiso
      return false;
    } else if (status.isPermanentlyDenied) {
      // El usuario denegó permanentemente el permiso
      // Aquí podrías mostrar un diálogo para ir a configuración
      return false;
    }
    
    return false;
  }

  /// Verifica si tiene permisos de cámara
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Verifica si tiene permisos de galería
  Future<bool> hasPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Solicita permisos de cámara
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Solicita permisos de galería
  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Abre la configuración de la app para que el usuario pueda habilitar permisos
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Verifica múltiples permisos a la vez
  Future<Map<Permission, PermissionStatus>> checkMultiplePermissions() async {
    return await [
      Permission.camera,
      Permission.photos,
    ].request();
  }
}
