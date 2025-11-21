import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/theme_x.dart';
import '../theme/page_theme_provider.dart';
import '../../domain/models/notification_pause.dart';
import '../../domain/models/station.dart';
import '../../domain/models/trip.dart' as domain;
import '../../infrastructure/dependency_injection.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  bool _isPauseUpdating = false;
  bool _isTestingNotification = false;
  String? _error;
  String? _testMessage;
  List<domain.Trip> _trips = [];
  NotificationPause? _currentPause;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tripService = DependencyInjection.instance.tripService;
      final pauseService = DependencyInjection.instance.notificationPauseService;

      final trips = await tripService.getAllTrips();
      final pauses = List<NotificationPause>.from(
        await pauseService.getAllPauses(),
      )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      NotificationPause? selectedPause;
      for (final pause in pauses) {
        if (!pause.isPast) {
          selectedPause = pause;
          break;
        }
      }

      setState(() {
        _trips = trips;
        _currentPause = selectedPause;
        _isLoading = false;
      });
    } on Object catch (e) {
      setState(() {
        _error = 'Impossible de récupérer les données: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(domain.Trip trip, bool enabled) async {
    try {
      final updatedTrip = trip.copyWith(notificationsEnabled: enabled);
      await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
      await DependencyInjection.instance.tripReminderService.refreshSchedules();
      if (!mounted) return;
      setState(() {
        _trips = _trips.map((t) => t.id == trip.id ? updatedTrip : t).toList();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'Notifications activées pour ${trip.description}'
              : 'Notifications désactivées pour ${trip.description}'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: context.theme.error,
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    if (_isTestingNotification) return;

    setState(() {
      _isTestingNotification = true;
      _testMessage = 'Notification programmée dans 5 secondes...';
    });

    try {
      final notificationService = DependencyInjection.instance.notificationService;
      await notificationService.initialize();
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      await notificationService.notifyReminder(_createTestTrip(), 5);
      if (!mounted) return;
      setState(() {
        _testMessage = '✅ Notification envoyée !';
      });
      if (mounted) {
        setState(() {
          _isTestingNotification = false;
        });
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _testMessage = '❌ Erreur: $e';
        _isTestingNotification = false;
      });
    }
  }

  domain.Trip _createTestTrip() {
    return domain.Trip(
      id: 'test_trip_${DateTime.now().millisecondsSinceEpoch}',
      departureStation: const Station(
        id: 'test_dep',
        name: 'Gare de Test Départ',
        description: 'Station de test',
      ),
      arrivalStation: const Station(
        id: 'test_arr',
        name: 'Gare de Test Arrivée',
        description: 'Station de test',
      ),
      day: domain.DayOfWeek.monday,
      time: const domain.TimeOfDay(hour: 10, minute: 30),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _showPauseOptions() async {
    if (_isPauseUpdating) return;

    final now = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: (_currentPause != null && _currentPause!.endDate.isAfter(now))
          ? _currentPause!.endDate
          : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    final endDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
    );

    if (endDate.isBefore(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une date de fin dans le futur'),
          backgroundColor: context.theme.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    await _schedulePauseUntil(endDate);
  }

  Future<void> _schedulePauseUntil(DateTime endDate) async {
    if (_isPauseUpdating) return;

    setState(() {
      _isPauseUpdating = true;
    });

    try {
      final pauseService = DependencyInjection.instance.notificationPauseService;
      final existing = await pauseService.getAllPauses();
      for (final pause in existing) {
        await pauseService.deletePause(pause.id);
      }

      final pause = NotificationPause(
        id: NotificationPause.generateId(),
        name: "Pause jusqu'au ${_formatDateTime(endDate)}",
        startDate: DateTime.now(),
        endDate: endDate,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await pauseService.createPause(pause);
      if (!mounted) return;
      setState(() {
        _currentPause = pause;
        _isPauseUpdating = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Notifications en pause jusqu'au ${_formatDateTime(pause.endDate)}",
          ),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _isPauseUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création de la pause: $e'),
          backgroundColor: context.theme.error,
        ),
      );
    }
  }

  Future<void> _cancelPause() async {
    if (_currentPause == null || _isPauseUpdating) return;

    setState(() {
      _isPauseUpdating = true;
    });

    try {
      await DependencyInjection.instance.notificationPauseService.deletePause(_currentPause!.id);
      if (!mounted) return;
      setState(() {
        _currentPause = null;
        _isPauseUpdating = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pause désactivée')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _isPauseUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: context.theme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTrips = _trips.where((t) => t.isActive).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildNotificationsSection(context, activeTrips),
            const SizedBox(height: 16),
            _buildPauseSection(context),
            if (const bool.fromEnvironment('USE_MOCK_DATA')) ...[
              const SizedBox(height: 16),
              _buildTestCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final pageColors = PageThemeProvider.of(context);
              return Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          pageColors.primaryDark,
                          pageColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        pageColors.primaryDark,
                        pageColors.primary,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Gérez les alertes pour chaque trajet et mettez-les en pause si besoin.',
            style: TextStyle(
              fontSize: 13,
              color: context.theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, List<domain.Trip> activeTrips) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorCard(context);
    }

    if (activeTrips.isEmpty) {
      return _buildEmptyNotificationsCard(context);
    }

    return Column(
      children: activeTrips.map((trip) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.theme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.theme.outline),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha:0.3)
                    : Colors.black.withValues(alpha:0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: context.theme.card,
            child: InkWell(
              onTap: () => _toggleNotifications(trip, !trip.notificationsEnabled),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            trip.notificationsEnabled ? context.theme.success : context.theme.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        trip.notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.description.isNotEmpty
                                ? trip.description
                                : 'Trajet sans description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${trip.day.displayName} · ${trip.timeFormatted}',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: trip.notificationsEnabled,
                      onChanged: (value) => _toggleNotifications(trip, value),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.theme.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.errorBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Erreur',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.theme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: context.theme.error),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Icons.refresh, color: context.theme.onPrimary),
              label: Text('Réessayer', style: TextStyle(color: context.theme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotificationsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Icon(Icons.notifications_off, color: context.theme.muted),
            const SizedBox(height: 12),
            Text(
              'Aucune notification active',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activez les alertes depuis vos trajets pour les voir ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.theme.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pause_circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pause des notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.theme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_isPauseUpdating)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentPause == null)
              Text(
                'Aucune pause active. Les notifications seront envoyées normalement.',
                style: TextStyle(color: context.theme.textSecondary),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentPause!.isCurrentlyActive
                          ? context.theme.error
                          : context.theme.warning,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _currentPause!.isCurrentlyActive ? 'PAUSE ACTIVE' : 'PAUSE À VENIR',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Du ${_formatDateTime(_currentPause!.startDate)}',
                    style: TextStyle(color: context.theme.textSecondary),
                  ),
                  Text(
                    'Au ${_formatDateTime(_currentPause!.endDate)}',
                    style: TextStyle(color: context.theme.textSecondary),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPauseUpdating ? null : _showPauseOptions,
                    icon: const Icon(Icons.add),
                    label: Text(_currentPause == null ? 'Programmer' : 'Modifier la pause'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentPause == null || _isPauseUpdating ? null : _cancelPause,
                    icon: const Icon(Icons.close),
                    label: const Text('Désactiver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.theme.info,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tester une notification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.theme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Un rappel sera envoyé après un délai de 5 secondes pour vérifier que tout fonctionne.',
              style: TextStyle(color: context.theme.textSecondary),
            ),
            if (_testMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _testMessage!,
                style: TextStyle(
                  color: _testMessage!.startsWith('✅')
                      ? context.theme.success
                      : _testMessage!.startsWith('❌')
                          ? context.theme.error
                          : context.theme.warning,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isTestingNotification ? null : _sendTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primary,
                foregroundColor:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
              icon: Icon(
                _isTestingNotification ? Icons.hourglass_top : Icons.play_arrow,
              ),
              label: Text(_isTestingNotification
                  ? 'Notification dans 5 secondes...'
                  : 'Envoyer une notification test'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('EEEE d MMMM à HH:mm', 'fr_FR');
    final formatted = formatter.format(dateTime);
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }
}
