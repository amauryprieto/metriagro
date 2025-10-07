import 'package:flutter/material.dart';
import 'package:metriagro/core/theme/app_theme.dart';

/// PROPUESTA 2: INTERFAZ POR TARJETAS
/// Enfoque: Organizada, visual, opciones claras por categorías
/// 
/// Características:
/// - Tarjetas visuales para diferentes tipos de consulta
/// - Historial accesible como lista
/// - Sugerencias categorizadas
/// - Respuestas organizadas por secciones expandibles
/// - Interfaz más visual y guiada

class CardBasedConsultationPage extends StatefulWidget {
  const CardBasedConsultationPage({super.key});

  @override
  State<CardBasedConsultationPage> createState() => _CardBasedConsultationPageState();
}

class _CardBasedConsultationPageState extends State<CardBasedConsultationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildConsultationCards(),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildSuggestedQueries(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.agriculture, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Metriagro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home, color: Colors.white, size: 24),
              ),
              IconButton(
                onPressed: _showHistory,
                icon: const Icon(Icons.history, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '¿En qué podemos ayudarte hoy?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildConsultationCard(
                  title: 'Audio',
                  subtitle: 'Describe tu consulta',
                  icon: Icons.mic,
                  color: Colors.blue,
                  onTap: () => _startConsultation('audio'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildConsultationCard(
                  title: 'Video',
                  subtitle: 'Graba tu cultivo',
                  icon: Icons.videocam,
                  color: Colors.red,
                  onTap: () => _startConsultation('video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConsultationCard(
                  title: 'Texto',
                  subtitle: 'Escribe tu pregunta',
                  icon: Icons.text_fields,
                  color: Colors.green,
                  onTap: () => _startConsultation('texto'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildConsultationCard(
                  title: 'Mixto',
                  subtitle: 'Combina métodos',
                  icon: Icons.apps,
                  color: Colors.orange,
                  onTap: () => _startConsultation('mixto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Diagnóstico\nrápido',
                  icon: Icons.camera_alt,
                  color: AppTheme.primaryColor,
                  onTap: () => _startQuickDiagnosis(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Consulta\nanterior',
                  icon: Icons.replay,
                  color: Colors.grey[600]!,
                  onTap: () => _repeatLastQuery(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Exportar\nreporte',
                  icon: Icons.download,
                  color: Colors.blue,
                  onTap: () => _exportReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQueries() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultas populares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSuggestionCategory(
            category: 'Enfermedades',
            icon: Icons.local_hospital,
            color: Colors.red,
            suggestions: [
              '¿Qué enfermedad tiene mi cultivo?',
              'Síntomas de hongos en plantas',
              'Prevención de enfermedades',
            ],
          ),
          const SizedBox(height: 12),
          _buildSuggestionCategory(
            category: 'Plagas',
            icon: Icons.bug_report,
            color: Colors.orange,
            suggestions: [
              'Identificar insectos dañinos',
              'Control de plagas orgánico',
              'Daños en hojas por insectos',
            ],
          ),
          const SizedBox(height: 12),
          _buildSuggestionCategory(
            category: 'Manejo',
            icon: Icons.agriculture,
            color: Colors.green,
            suggestions: [
              'Mejores prácticas de cultivo',
              'Calendario de fertilización',
              'Técnicas de riego eficiente',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCategory({
    required String category,
    required IconData icon,
    required Color color,
    required List<String> suggestions,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(
        category,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      children: suggestions
          .map((suggestion) => ListTile(
                dense: true,
                leading: Icon(Icons.lightbulb_outline, size: 16, color: color),
                title: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                onTap: () => _startConsultationWithText(suggestion),
              ))
          .toList(),
    );
  }

  void _startConsultation(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardBasedResultPage(inputType: type, query: ''),
      ),
    );
  }

  void _startConsultationWithText(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardBasedResultPage(inputType: 'texto', query: query),
      ),
    );
  }

  void _startQuickDiagnosis() {
    // TODO: Implementar diagnóstico rápido con cámara
    _startConsultation('video');
  }

  void _repeatLastQuery() {
    // TODO: Repetir última consulta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repitiendo última consulta...')),
    );
  }

  void _exportReport() {
    // TODO: Exportar reporte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando reporte...')),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryListPage()),
    );
  }
}

/// Página de resultados con diseño por tarjetas
class CardBasedResultPage extends StatefulWidget {
  final String inputType;
  final String query;

  const CardBasedResultPage({
    super.key,
    required this.inputType,
    required this.query,
  });

  @override
  State<CardBasedResultPage> createState() => _CardBasedResultPageState();
}

class _CardBasedResultPageState extends State<CardBasedResultPage> {
  bool? _wasHelpful;
  bool _showNaturalResponse = true;
  bool _showTechnicalResponse = false;
  bool _showReferences = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Resultado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildFeedbackCard(),
            const SizedBox(height: 24),
            _buildResponseCard(
              title: 'Respuesta en Lenguaje Natural',
              icon: Icons.chat_bubble_outline,
              color: Colors.blue,
              content: 'Tu cultivo presenta síntomas de roya, una enfermedad fúngica común. '
                  'Se recomienda aplicar fungicidas preventivos y mejorar la ventilación '
                  'del cultivo para evitar la propagación.',
              isExpanded: _showNaturalResponse,
              onToggle: () => setState(() => _showNaturalResponse = !_showNaturalResponse),
            ),
            const SizedBox(height: 16),
            _buildResponseCard(
              title: 'Información Técnica',
              icon: Icons.science,
              color: Colors.green,
              content: 'Diagnóstico: Puccinia spp. (Roya)\n'
                  'Tratamiento: Fungicidas sistémicos (Propiconazol 250g/L)\n'
                  'Dosis: 1.5-2.0 L/ha en aplicación foliar\n'
                  'Frecuencia: Cada 14-21 días según severidad',
              isExpanded: _showTechnicalResponse,
              onToggle: () => setState(() => _showTechnicalResponse = !_showTechnicalResponse),
            ),
            const SizedBox(height: 16),
            _buildResponseCard(
              title: 'Referencias y Documentos',
              icon: Icons.library_books,
              color: Colors.orange,
              content: '• Manual de Enfermedades Fúngicas - INTA 2023\n'
                  '• Guía de Manejo Integrado de Plagas - FAO\n'
                  '• Protocolo de Aplicación de Fungicidas - SENASA',
              isExpanded: _showReferences,
              onToggle: () => setState(() => _showReferences = !_showReferences),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¿Te fue útil esta respuesta?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeedbackOption(
                  icon: Icons.thumb_up,
                  label: 'Útil',
                  isSelected: _wasHelpful == true,
                  onTap: () => setState(() => _wasHelpful = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeedbackOption(
                  icon: Icons.thumb_down,
                  label: 'No útil',
                  isSelected: _wasHelpful == false,
                  onTap: () => setState(() => _wasHelpful = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildResponseCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _shareResults() {
    // TODO: Implementar compartir resultados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartiendo resultados...')),
    );
  }
}

/// Página de historial como lista dedicada
class HistoryListPage extends StatelessWidget {
  const HistoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Historial de Consultas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar búsqueda en historial
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildHistoryCard(
            query: 'Análisis de plagas en hojas de tomate',
            time: '${index + 1} ${index == 0 ? 'hora' : 'días'} atrás',
            type: ['audio', 'video', 'texto', 'mixto'][index % 4],
            confidence: 85.5 + (index * 2.1),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard({
    required String query,
    required String time,
    required String type,
    required double confidence,
  }) {
    Color typeColor = _getTypeColor(type);
    IconData typeIcon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'audio': return Colors.blue;
      case 'video': return Colors.red;
      case 'texto': return Colors.green;
      case 'mixto': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'audio': return Icons.mic;
      case 'video': return Icons.videocam;
      case 'texto': return Icons.text_fields;
      case 'mixto': return Icons.apps;
      default: return Icons.help;
    }
  }
}