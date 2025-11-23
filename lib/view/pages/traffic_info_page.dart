import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../infrastructure/dependency_injection.dart';
import '../theme/page_theme_provider.dart';
import '../theme/theme_x.dart';

class TrafficInfoPage extends StatefulWidget {
  const TrafficInfoPage({super.key});

  @override
  State<TrafficInfoPage> createState() => _TrafficInfoPageState();
}

class _TrafficInfoPageState extends State<TrafficInfoPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrafficReports();
  }

  Future<void> _loadTrafficReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await DependencyInjection.instance.trainService.getTrafficReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les infos trafic';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageColors = PageThemeProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              pageColors.primary.withValues(alpha: 0.15),
              context.theme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildBody(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                PageThemeProvider.of(context).primaryDark,
                PageThemeProvider.of(context).primary,
              ],
            ).createShader(bounds),
            child: Text(
              'Info Trafic',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1.0,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'État du réseau en temps réel',
            style: TextStyle(
              fontSize: 16,
              color: context.theme.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: context.theme.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: context.theme.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadTrafficReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: context.theme.success),
            const SizedBox(height: 24),
            Text(
              'Aucune perturbation signalée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le trafic semble fluide sur le réseau',
              style: TextStyle(color: context.theme.textSecondary),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).scale(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrafficReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(context, report, index);
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report, int index) {
    final severity = report['severity'] as String? ?? '';
    final isBlocking = severity == 'blocking';
    final color = isBlocking ? context.theme.error : context.theme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: context.theme.glassStrong,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report['title'] as String? ?? 'Perturbation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report['message'] as String? ?? '',
              style: TextStyle(
                color: context.theme.textPrimary.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: context.theme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Mis à jour le ${_formatDate(report['updated_at'] as String?)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM à HH:mm', 'fr_FR').format(date);
    } catch (_) {
      return '';
    }
  }
}
