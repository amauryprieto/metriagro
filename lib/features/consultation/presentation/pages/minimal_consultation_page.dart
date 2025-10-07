import 'package:flutter/material.dart';
import 'package:metriagro/core/theme/app_theme.dart';

/// PROPUESTA 1: INTERFAZ MINIMALISTA
/// Enfoque: Simple, directo, centrado en la acción principal
/// 
/// Características:
/// - Un botón central grande para hacer consultas
/// - Opciones de entrada multimodal (audio, video, texto, mixto)
/// - Acceso rápido al historial
/// - Sugerencias contextuales
/// - Respuesta estructurada con validación de utilidad

class MinimalConsultationPage extends StatefulWidget {
  const MinimalConsultationPage({super.key});

  @override
  State<MinimalConsultationPage> createState() => _MinimalConsultationPageState();
}

class _MinimalConsultationPageState extends State<MinimalConsultationPage> {
  String _selectedInputType = 'mixto'; // audio, video, texto, mixto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    _buildMainConsultationButton(),
                    const SizedBox(height: 32),
                    _buildInputTypeSelector(),
                    const Spacer(),
                    _buildSuggestions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo y título
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Metriagro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          // Botones de acción
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.home,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showHistory,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainConsultationButton() {
    return GestureDetector(
      onTap: _startConsultation,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getInputIcon(),
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'NUEVA\nCONSULTA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInputTypeOption('audio', Icons.mic, 'Audio'),
          _buildInputTypeOption('video', Icons.videocam, 'Video'),
          _buildInputTypeOption('texto', Icons.text_fields, 'Texto'),
          _buildInputTypeOption('mixto', Icons.apps, 'Mixto'),
        ],
      ),
    );
  }

  Widget _buildInputTypeOption(String type, IconData icon, String label) {
    final isSelected = _selectedInputType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedInputType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      '¿Qué enfermedad tiene mi cultivo?',
      'Análisis de plagas en hojas',
      'Recomendaciones de manejo',
    ];

    return Column(
      children: [
        const Text(
          'Consultas sugeridas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...suggestions.map((suggestion) => _buildSuggestionItem(suggestion)).toList(),
      ],
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _startConsultationWithText(suggestion),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInputIcon() {
    switch (_selectedInputType) {
      case 'audio':
        return Icons.mic;
      case 'video':
        return Icons.videocam;
      case 'texto':
        return Icons.text_fields;
      case 'mixto':
      default:
        return Icons.smart_button;
    }
  }

  void _startConsultation() {
    // Navegación a página de consulta según el tipo seleccionado
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationResultPage(
          inputType: _selectedInputType,
          query: '',
        ),
      ),
    );
  }

  void _startConsultationWithText(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationResultPage(
          inputType: 'texto',
          query: query,
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const HistoryBottomSheet(),
    );
  }
}

/// Página de resultados de consulta
class ConsultationResultPage extends StatefulWidget {
  final String inputType;
  final String query;

  const ConsultationResultPage({
    super.key,
    required this.inputType,
    required this.query,
  });

  @override
  State<ConsultationResultPage> createState() => _ConsultationResultPageState();
}

class _ConsultationResultPageState extends State<ConsultationResultPage> {
  bool? _wasHelpful;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Resultado de Consulta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedbackSection(),
            const SizedBox(height: 24),
            _buildNaturalLanguageResponse(),
            const SizedBox(height: 24),
            _buildTechnicalResponse(),
            const SizedBox(height: 24),
            _buildReferences(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text(
            '¿Te fue útil esta respuesta?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeedbackButton(
                icon: Icons.thumb_up,
                label: 'Útil',
                isSelected: _wasHelpful == true,
                onTap: () => setState(() => _wasHelpful = true),
              ),
              const SizedBox(width: 16),
              _buildFeedbackButton(
                icon: Icons.thumb_down,
                label: 'No útil',
                isSelected: _wasHelpful == false,
                onTap: () => setState(() => _wasHelpful = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNaturalLanguageResponse() {
    return _buildResponseSection(
      title: 'Respuesta en Lenguaje Natural',
      icon: Icons.chat_bubble_outline,
      content: 'Tu cultivo presenta síntomas de roya, una enfermedad fúngica común. '
          'Se recomienda aplicar fungicidas preventivos y mejorar la ventilación '
          'del cultivo para evitar la propagación.',
    );
  }

  Widget _buildTechnicalResponse() {
    return _buildResponseSection(
      title: 'Respuesta Técnica',
      icon: Icons.science,
      content: 'Diagnóstico: Puccinia spp. (Roya)\n'
          'Tratamiento: Fungicidas sistémicos (Propiconazol 250g/L)\n'
          'Dosis: 1.5-2.0 L/ha en aplicación foliar\n'
          'Frecuencia: Cada 14-21 días según severidad',
    );
  }

  Widget _buildReferences() {
    return _buildResponseSection(
      title: 'Referencias y Documentos',
      icon: Icons.library_books,
      content: '• Manual de Enfermedades Fúngicas - INTA 2023\n'
          '• Guía de Manejo Integrado de Plagas - FAO\n'
          '• Protocolo de Aplicación de Fungicidas - SENASA',
    );
  }

  Widget _buildResponseSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal de historial
class HistoryBottomSheet extends StatelessWidget {
  const HistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Consultas Anteriores',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildHistoryItem('Análisis de plagas en hojas de tomate', '2 horas atrás'),
          _buildHistoryItem('Diagnóstico de enfermedad en maíz', '1 día atrás'),
          _buildHistoryItem('Recomendación de fertilizantes', '3 días atrás'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String query, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.history, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    query,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}