import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen desde la cámara o galería
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
      return image;
    } catch (e) {
      throw Exception('Error al seleccionar imagen: $e');
    }
  }

  /// Selecciona múltiples imágenes desde la galería
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
      return images;
    } catch (e) {
      throw Exception('Error al seleccionar imágenes: $e');
    }
  }

  /// Toma una foto con la cámara
  Future<XFile?> takePicture() async {
    return await pickImage(ImageSource.camera);
  }

  /// Selecciona una imagen de la galería
  Future<XFile?> selectFromGallery() async {
    return await pickImage(ImageSource.gallery);
  }
}
