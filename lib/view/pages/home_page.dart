import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../../infrastructure/dependency_injection.dart';
import 'profile_page.dart';
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
    // Recharger les données quand on revient sur la page
    _loadActiveTrips();
  }

  /// Charge tous les trajets et récupère le prochain train pour chacun
  Future<void> _loadActiveTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer tous les trajets
      final trips = await DependencyInjection.instance.tripService.getAllTrips();

      setState(() {
        _allTrips = trips;
        _tripNextTrains = {};
      });

      // Charger le prochain train pour chaque trajet actif
      await _loadNextTrainsForTrips();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des trajets: $e';
        _isLoading = false;
      });
    }
  }

  /// Charge le prochain train pour chaque trajet actif
  Future<void> _loadNextTrainsForTrips() async {
    final tripNextTrains = <String, Train?>{};
    final now = DateTime.now();

    for (final trip in _allTrips.where((t) => t.isActive)) {
      try {
        // Calculer la date/heure de référence pour ce trajet
        final refDateTime = _computeReferenceDateTime(trip, now);

        // Chercher le prochain train pour ce trajet
        final trains =
            await DependencyInjection.instance.trainService.findJourneysWithDepartureTime(
          trip.departureStation,
          trip.arrivalStation,
          refDateTime,
        );

        // Filtrer les trains qui vont vers la destination et prendre le premier futur ou en cours
        Train? nextTrain;
        for (final train in trains) {
          if (train.direction.contains(trip.arrivalStation.name)) {
            // Prendre le train s'il :
            // - est en cours (départ dans le passé mais arrivée dans le futur)
            // - ou est futur (départ après maintenant)
            final isInProgress = train.departureTime.isBefore(now) &&
                train.arrivalTime != null &&
                train.arrivalTime!.isAfter(now);
            final isFuture = train.departureTime.isAfter(now.subtract(const Duration(minutes: 5)));

            if (isInProgress || isFuture) {
              nextTrain = train;
              break;
            }
          }
        }

        tripNextTrains[trip.id] = nextTrain;
      } catch (e) {
        // Si erreur, pas de train disponible
        tripNextTrains[trip.id] = null;
      }
    }

    setState(() {
      _tripNextTrains = tripNextTrains;
      _isLoading = false;
    });
  }

  /// Calcule la date/heure de référence pour un trajet
  DateTime _computeReferenceDateTime(domain.Trip trip, DateTime now) {
    // Calculer la date de base avec l'heure du trajet
    final today = DateTime(now.year, now.month, now.day, trip.time.hour, trip.time.minute);

    // Si l'heure est passée aujourd'hui, prendre demain (ou le prochain jour du trajet)
    if (today.isBefore(now)) {
      // Trouver le prochain jour où ce trajet est actif
      for (int i = 1; i <= 7; i++) {
        final nextDay = today.add(Duration(days: i));
        final weekday = nextDay.weekday;
        final dayOfWeek = domain.DayOfWeek.values.firstWhere(
          (d) => d.index + 1 == weekday,
          orElse: () => domain.DayOfWeek.monday,
        );
        if (trip.days.contains(dayOfWeek)) {
          return nextDay;
        }
      }
    }

    return today;
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
    );
  }

  void _navigateToProfile(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
    if (result == true) {
      _loadActiveTrips();
    }
  }

  void _navigateToAddTrip(BuildContext context) async {
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

  void _handleTripAction(String action, domain.Trip trip) async {
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
        _loadActiveTrips();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trajet dupliqué')),
        );
        break;
      case 'toggle':
        final updatedTrip = trip.copyWith(isActive: !trip.isActive);
        await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
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
      appBar: AppBar(
        title: const Row(
          children: [
            LogoWidget(size: 40, showText: false),
            SizedBox(width: 12),
            Text('Train\'Qil'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          AnimatedBuilder(
            animation: DependencyInjection.instance.themeService,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  DependencyInjection.instance.themeService.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => DependencyInjection.instance.themeService.toggleTheme(),
                tooltip: DependencyInjection.instance.themeService.isDarkMode
                    ? 'Mode clair'
                    : 'Mode sombre',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => _navigateToProfile(context),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTrip(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
