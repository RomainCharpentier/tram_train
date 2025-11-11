import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../../infrastructure/dependency_injection.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'trip_progress_page.dart';
import '../widgets/logo_widget.dart';
import '../widgets/trip_card.dart';
import '../theme/theme_x.dart';

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
    } catch (e) {
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
    } catch (e) {
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
      } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActiveTrips,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Afficher l'état vide seulement si aucun trajet existant
    if (_allTrips.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDashboard();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LogoWidget(size: 150),
          const SizedBox(height: 24),
          Text(
            'Aucun trajet actif',
            style: TextStyle(fontSize: 18, color: context.theme.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos trajets pour voir les prochains départs',
            style: TextStyle(color: context.theme.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un trajet'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    DateTime now;
    try {
      now = DependencyInjection.instance.clockService.now();
    } catch (e) {
      const useMockData = bool.fromEnvironment('USE_MOCK_DATA');
      now = useMockData ? DateTime(2025, 1, 6, 7) : DateTime.now();
    }
    final formattedNow = DateFormat("EEEE d MMMM yyyy 'à' HH:mm", 'fr_FR').format(now);

    // Trier les trajets par heure du prochain train (du plus proche au plus éloigné)
    final sortedTrips = _allTrips.where((trip) => trip.isActive).toList()
      ..sort((a, b) {
        final trainA = _tripNextTrains[a.id];
        final trainB = _tripNextTrains[b.id];

        // Si un trajet n'a pas de train, le mettre à la fin
        if (trainA == null && trainB == null) return 0;
        if (trainA == null) return 1;
        if (trainB == null) return -1;

        // Trier par heure de départ
        return trainA.departureTime.compareTo(trainB.departureTime);
      });

    return RefreshIndicator(
      onRefresh: _loadActiveTrips,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Heure actuelle (mock) : ${formattedNow[0].toUpperCase()}${formattedNow.substring(1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (sortedTrips.isEmpty) ...[
            _buildEmptyTripsMessage(),
          ] else ...[
            ...sortedTrips.map((trip) => _buildTripCard(trip)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTripsMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info, color: context.theme.warning),
            const SizedBox(height: 8),
            const Text('Aucun trajet actif', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Utilisez le bouton + pour ajouter un trajet',
                style: TextStyle(color: context.theme.muted)),
          ],
        ),
      ),
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
      MaterialPageRoute(
        builder: (context) => const AddTripPage(),
      ),
    );
    if (result == true) {
      _loadActiveTrips();
    }
  }

  Future<void> _handleTripAction(String action, domain.Trip trip) async {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTripPage(trip: trip),
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
        _loadActiveTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trajet dupliqué')),
        );
        break;
      case 'toggle':
        final updatedTrip = trip.copyWith(isActive: !trip.isActive);
        await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
        await DependencyInjection.instance.tripReminderService.refreshSchedules();
        _loadActiveTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trajet ${updatedTrip.isActive ? 'activé' : 'désactivé'}')),
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
                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await DependencyInjection.instance.tripService.deleteTripAndSimilar(trip);
          await DependencyInjection.instance.tripReminderService.refreshSchedules();
          _loadActiveTrips();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trajet supprimé (doublons inclus)')),
          );
        }
        break;
    }
  }

  void _showTripDetails(domain.Trip trip) {
    final nextTrain = _tripNextTrains[trip.id];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripProgressPage(
          trip: trip,
          currentTrain: nextTrain,
        ),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8),
              child: Text(
                'Mes trajets',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.theme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTrip(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
