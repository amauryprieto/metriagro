import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import 'package:metriagro/core/theme/app_theme.dart';
import 'package:metriagro/core/services/image_picker_service.dart';
import 'package:metriagro/core/services/permission_service.dart';
import 'package:metriagro/core/network/network_info.dart';
import 'package:metriagro/core/services/ml_inference_service.dart';
import 'package:metriagro/core/services/gcp_disease_api_service.dart';
import 'package:metriagro/shared/models/disease_detection_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final PermissionService _permissionService = PermissionService();
  final NetworkInfo _networkInfo = NetworkInfoImpl();
  final MlInferenceService _mlService = LocalTfliteInferenceService();
  final GcpDiseaseApiService _gcpService = GcpDiseaseApiServiceImpl(Dio());

  int _remainingQueries = 5; // Número de consultas gratis
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildUpgradeCard(),
            const SizedBox(height: 48),
            _buildCameraButton(),
            const SizedBox(height: 24),
            _buildInvitationText(),
            const SizedBox(height: 32),
            _buildPhotoInstructions(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          // TODO: Implementar logout o navegación
        },
      ),
      title: const Text(
        'Metriagro',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // TODO: Implementar menú de opciones
          },
        ),
      ],
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tienes $_remainingQueries consultas gratis',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navegar a página de planes/upgrade
                        _navigateToUpgradePage();
                      },
                      child: Text(
                        '¿Necesitas más análisis?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _showImagePickerOptions,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: _isLoading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 3)
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 60, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'TOMAR FOTO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInvitationText() {
    return const Text(
      'Toma una foto para que nuestro\nasistente pueda examinarla',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
    );
  }

  Widget _buildPhotoInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Para obtener mejores resultados:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionItem('Asegúrate de que la imagen esté bien iluminada'),
          _buildInstructionItem('Mantén la cámara estable'),
          _buildInstructionItem('Enfoca el objeto principal'),
          _buildInstructionItem('Evita sombras o reflejos'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleccionar imagen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.camera_alt,
                    title: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    icon: Icons.photo_library,
                    title: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar permisos
      bool hasPermission = await _permissionService.requestImagePermission(source);

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos necesarios para acceder a la cámara/galería'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Seleccionar imagen
      XFile? image = await _imagePickerService.pickImage(source);

      if (image != null) {
        final isConnected = await _networkInfo.isConnected;
        final file = File(image.path);
        DiseaseDetectionResult result;
        try {
          if (isConnected) {
            result = await _gcpService.uploadAndAnalyze(file);
          } else {
            result = await _mlService.analyzeImage(file);
          }
        } catch (_) {
          // Fallback to local if cloud fails
          result = await _mlService.analyzeImage(file);
        }

        await showDialog<void>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Análisis completado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resultado: ${result.diseaseName ?? (result.hasDisease ? 'Enfermedad detectada' : 'Sin enfermedad')}',
                  ),
                  const SizedBox(height: 8),
                  Text('Confianza: ${(result.confidence * 100).toStringAsFixed(1)}%'),
                ],
              ),
              actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Aceptar'))],
            );
          },
        );

        setState(() {
          _remainingQueries--;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToUpgradePage() {
    // TODO: Implementar navegación a página de planes/upgrade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Página de planes y upgrade'), backgroundColor: AppTheme.primaryColor),
    );
  }
}
