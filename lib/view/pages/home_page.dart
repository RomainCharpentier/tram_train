import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../../infrastructure/dependency_injection.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'trip_progress_page.dart';
import '../widgets/logo_widget.dart';
import '../widgets/trip_card.dart';
import '../widgets/glass_container.dart';
import '../theme/theme_x.dart';
import '../theme/page_theme_provider.dart';
import '../utils/page_transitions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<domain.Trip> _allTrips = [];
  Map<String, Train?> _tripNextTrains = {}; // Map tripId -> nextTrain
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveTrips();
  }

  Future<void> _loadActiveTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trips = await DependencyInjection.instance.tripService.getAllTrips();

      setState(() {
        _allTrips = trips;
        _tripNextTrains = {};
      });

      await _loadNextTrainsForTrips();
    } on Object catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des trajets: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextTrainsForTrips() async {
    final tripNextTrains = <String, Train?>{};
    DateTime now;
    try {
      now = DependencyInjection.instance.clockService.now();
    } on Object catch (_) {
      const useMockData = bool.fromEnvironment('USE_MOCK_DATA');
      now = useMockData ? DateTime(2025, 1, 6, 7) : DateTime.now();
    }

    for (final trip in _allTrips.where((t) => t.isActive)) {
      try {
        final Train? currentTrain = await _findCurrentTrain(trip, now);

        if (currentTrain != null) {
          tripNextTrains[trip.id] = currentTrain;
        } else {
          final nextTrain = await _findNextScheduledTrain(trip, now);
          tripNextTrains[trip.id] = nextTrain;
        }
      } on Object catch (_) {
        tripNextTrains[trip.id] = null;
      }
    }

    setState(() {
      _tripNextTrains = tripNextTrains;
      _isLoading = false;
    });
  }

  Future<Train?> _findCurrentTrain(domain.Trip trip, DateTime now) async {
    if (!trip.isForToday(now)) return null;

    final todayDeparture = DateTime(
      now.year,
      now.month,
      now.day,
      trip.time.hour,
      trip.time.minute,
    );

    final searchTime = todayDeparture.isBefore(now)
        ? now.subtract(const Duration(hours: 2))
        : todayDeparture.subtract(const Duration(minutes: 30));

    final trains = await DependencyInjection.instance.trainService.findJourneysWithDepartureTime(
      trip.departureStation,
      trip.arrivalStation,
      searchTime,
    );

    Train? inProgressTrain;
    for (final train in trains) {
      if (!train.direction.contains(trip.arrivalStation.name)) continue;

      final isInProgress = train.departureTime.isBefore(now) &&
          train.arrivalTime != null &&
          train.arrivalTime!.isAfter(now);

      if (isInProgress) {
        final timeDiff = (train.baseDepartureTime ?? train.departureTime)
            .difference(todayDeparture)
            .abs()
            .inHours;

        if (timeDiff <= 2) {
          inProgressTrain = train;
          break;
        }
      }
    }

    if (inProgressTrain != null) {
      return inProgressTrain;
    }

    for (final train in trains) {
      if (!train.direction.contains(trip.arrivalStation.name)) continue;

      final isInProgress = train.departureTime.isBefore(now) &&
          train.arrivalTime != null &&
          train.arrivalTime!.isAfter(now);

      if (isInProgress) {
        if (inProgressTrain == null || train.departureTime.isAfter(inProgressTrain.departureTime)) {
          inProgressTrain = train;
        }
      }
    }

    return inProgressTrain;
  }

  Future<Train?> _findNextScheduledTrain(domain.Trip trip, DateTime now) async {
    final nextActiveDate = _findNextActiveDate(trip, now);
    if (nextActiveDate == null) return null;

    final departureDateTime = DateTime(
      nextActiveDate.year,
      nextActiveDate.month,
      nextActiveDate.day,
      trip.time.hour,
      trip.time.minute,
    );

    final searchTime = departureDateTime.isBefore(now)
        ? now.subtract(const Duration(hours: 1))
        : departureDateTime.subtract(const Duration(minutes: 30));

    final trains = await DependencyInjection.instance.trainService.findJourneysWithDepartureTime(
      trip.departureStation,
      trip.arrivalStation,
      searchTime,
    );

    for (final train in trains) {
      if (!train.direction.contains(trip.arrivalStation.name)) continue;

      final timeDiff = (train.baseDepartureTime ?? train.departureTime)
          .difference(departureDateTime)
          .abs()
          .inMinutes;

      if (timeDiff > 30) continue;

      if (train.departureTime.isAfter(now.subtract(const Duration(minutes: 5)))) {
        return train;
      }
    }

    return null;
  }

  DateTime? _findNextActiveDate(domain.Trip trip, DateTime now) {
    for (int i = 0; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      final weekday = date.weekday;
      final dayOfWeek = domain.DayOfWeek.values.firstWhere(
        (d) => d.index + 1 == weekday,
        orElse: () => domain.DayOfWeek.monday,
      );

      if (trip.day == dayOfWeek) {
        if (i == 0) {
          final todayDeparture = DateTime(
            now.year,
            now.month,
            now.day,
            trip.time.hour,
            trip.time.minute,
          );
          if (todayDeparture.isAfter(now)) {
            return date;
          }
        } else {
          return date;
        }
      }
    }

    return null;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                PageThemeProvider.of(context).primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement de vos trajets...',
              style: TextStyle(
                fontSize: 14,
                color: context.theme.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.theme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.theme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oups !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.theme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 15,
                  color: context.theme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _loadActiveTrips,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allTrips.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDashboard(context);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LogoWidget(size: 120),
          const SizedBox(height: 32),
          Text(
            'Aucun trajet actif',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ajoutez vos trajets pour voir les\nprochains départs en temps réel',
            style: TextStyle(
              fontSize: 16,
              color: context.theme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _navigateToAddTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un trajet'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    DateTime now;
    try {
      now = DependencyInjection.instance.clockService.now();
    } on Object catch (_) {
      const useMockData = bool.fromEnvironment('USE_MOCK_DATA');
      now = useMockData ? DateTime(2025, 1, 6, 7) : DateTime.now();
    }
    final formattedNow = DateFormat("EEEE d MMMM", 'fr_FR').format(now);

    final sortedTrips = _allTrips.where((trip) => trip.isActive).toList()
      ..sort((a, b) {
        final trainA = _tripNextTrains[a.id];
        final trainB = _tripNextTrains[b.id];

        if (trainA == null && trainB == null) return 0;
        if (trainA == null) return 1;
        if (trainB == null) return -1;

        return trainA.departureTime.compareTo(trainB.departureTime);
      });

    const useMockData = bool.fromEnvironment('USE_MOCK_DATA');

    return RefreshIndicator(
      onRefresh: _loadActiveTrips,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          Text(
            formattedNow.replaceFirst(formattedNow[0], formattedNow[0].toUpperCase()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.theme.primary,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                PageThemeProvider.of(context).primaryDark,
                PageThemeProvider.of(context).primary,
              ],
            ).createShader(bounds),
            child: Text(
              'Vos Trajets',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1.2,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 28),
          if (useMockData) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, // Bleu clair au lieu d'orange pour contraste
                border: Border.all(color: Colors.blue.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined,
                      color: Colors.blue.shade700), // Bleu au lieu d'orange
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Démo Actif',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800, // Bleu foncé au lieu d'orange
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Les données affichées sont simulées',
                          style: TextStyle(
                            color: Colors.blue.shade700, // Bleu au lieu d'orange
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
          if (sortedTrips.isEmpty) ...[
            _buildEmptyTripsMessage(),
          ] else ...[
            ...sortedTrips.asMap().entries.map((entry) {
              final index = entry.key;
              final trip = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTripCard(trip)
                    .animate()
                    .fadeIn(delay: (200 + (index * 80)).ms, duration: 400.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      delay: (200 + (index * 80)).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1, 1),
                      delay: (200 + (index * 80)).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTripsMessage() {
    final pageColors = PageThemeProvider.of(context);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pageColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.train_outlined,
              size: 40,
              color: pageColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun trajet actif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.theme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez le bouton + pour ajouter un trajet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildTripCard(domain.Trip trip) {
    final nextTrain = _tripNextTrains[trip.id];

    return TripCard(
      trip: trip,
      nextTrain: nextTrain,
      onAction: (action, t) => _handleTripAction(action, t),
      onTap: () => _showTripDetails(trip),
      showActions: false,
    );
  }

  Future<void> _navigateToAddTrip(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      PageTransitions.slideRoute(
        const AddTripPage(),
        begin: const Offset(0.0, 0.05),
      ),
    );
    if (result == true) {
      if (!mounted) return;
      _loadActiveTrips();
    }
  }

  Future<void> _handleTripAction(String action, domain.Trip trip) async {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          PageTransitions.slideRoute(
            EditTripPage(trip: trip),
            begin: const Offset(0.0, 0.05),
          ),
        );
        break;
      case 'duplicate':
        final duplicatedTrip = trip.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
        );
        await DependencyInjection.instance.tripService.saveTrip(duplicatedTrip);
        await DependencyInjection.instance.tripReminderService.refreshSchedules();
        if (!mounted) return;
        _loadActiveTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trajet dupliqué'),
            backgroundColor: context.theme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'toggle':
        final updatedTrip = trip.copyWith(isActive: !trip.isActive);
        await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
        await DependencyInjection.instance.tripReminderService.refreshSchedules();
        if (!mounted) return;
        _loadActiveTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trajet ${updatedTrip.isActive ? 'activé' : 'désactivé'}'),
            backgroundColor: context.theme.info,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer le trajet'),
            content: const Text('Êtes-vous sûr de vouloir supprimer ce trajet ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Supprimer', style: TextStyle(color: context.theme.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await DependencyInjection.instance.tripService.deleteTripAndSimilar(trip);
          await DependencyInjection.instance.tripReminderService.refreshSchedules();
          if (!mounted) return;
          _loadActiveTrips();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Trajet supprimé'),
              backgroundColor: context.theme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
    }
  }

  void _showTripDetails(domain.Trip trip) {
    final nextTrain = _tripNextTrains[trip.id];
    Navigator.push(
      context,
      PageTransitions.scaleRoute(
        TripProgressPage(
          trip: trip,
          currentTrain: nextTrain,
        ),
      ),
    );
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
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTrip(context),
        backgroundColor: pageColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Nouveau',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        elevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      )
          .animate()
          .scale(
            delay: 400.ms,
            duration: 500.ms,
            curve: Curves.easeOutBack,
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
          )
          .fadeIn(delay: 400.ms, duration: 300.ms),
    );
  }
}
