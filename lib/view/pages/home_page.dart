import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../../domain/models/station.dart';
import '../../infrastructure/dependency_injection.dart';
import 'profile_page.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'trip_schedule_page.dart';
import '../widgets/logo_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<domain.Trip> _activeTrips = [];
  List<Train> _nextTrains = [];
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

  /// Charge les trajets actifs pour aujourd'hui
  Future<void> _loadActiveTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trips = await DependencyInjection.instance.tripService.getAllTrips();
      final activeTrips = trips.where((trip) => trip.isActiveToday).toList();
      
      // Si aucun trajet, créer un trajet de test
      if (activeTrips.isEmpty) {
        // Supprimer l'ancien trajet de test s'il existe
        try {
          await DependencyInjection.instance.tripService.deleteTrip('test-trip');
        } catch (e) {
          // Ignorer si le trajet n'existe pas
        }
        
        final testTrip = domain.Trip(
          id: 'test-trip',
          departureStation: const Station(
            id: 'SNCF:87590349',
            name: 'Babinière',
            description: 'Gare de Babinière',
          ),
          arrivalStation: const Station(
            id: 'SNCF:87481002',
            name: 'Nantes',
            description: 'Gare de Nantes',
          ),
          days: [domain.DayOfWeek.monday, domain.DayOfWeek.tuesday, domain.DayOfWeek.wednesday, domain.DayOfWeek.thursday, domain.DayOfWeek.friday, domain.DayOfWeek.saturday, domain.DayOfWeek.sunday],
          time: const domain.TimeOfDay(hour: 8, minute: 30),
          isActive: true,
          notificationsEnabled: true,
          createdAt: DateTime.now(),
        );
        
        await DependencyInjection.instance.tripService.saveTrip(testTrip);
        activeTrips.add(testTrip);
      }
      
      setState(() {
        _activeTrips = activeTrips;
        _isLoading = false;
      });

      // Charger les horaires pour chaque trajet actif
      await _loadNextTrains();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des trajets: $e';
        _isLoading = false;
      });
    }
  }


  /// Charge les prochains trains pour les trajets actifs
  Future<void> _loadNextTrains() async {
    final nextTrains = <Train>[];
    
    for (final trip in _activeTrips) {
      try {
        final trains = await DependencyInjection.instance.trainService.getNextDepartures(
          trip.departureStation,
        );
        nextTrains.addAll(trains);
      } catch (e) {
        // Ignorer les erreurs pour un trajet spécifique
      }
    }
    
    setState(() {
      _nextTrains = nextTrains;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            LogoWidget(size: 40, showText: false),
            SizedBox(width: 12),
            Text('Train\'Qil'),
          ],
        ),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          // Toggle de thème
          AnimatedBuilder(
            animation: DependencyInjection.instance.themeService,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  DependencyInjection.instance.themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => DependencyInjection.instance.themeService.toggleTheme(),
                tooltip: DependencyInjection.instance.themeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
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

    if (_activeTrips.isEmpty) {
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
              const Text(
                'Aucun trajet actif',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajoutez vos trajets pour voir les prochains départs',
                style: TextStyle(color: Colors.grey),
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
    return RefreshIndicator(
      onRefresh: _loadActiveTrips,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo en en-tête
          const Center(
            child: LogoWidget(size: 120, showText: false),
          ),
          const SizedBox(height: 24),
          _buildHeader(),
          const SizedBox(height: 16),
          ..._buildTripCards(),
          
          // Section des prochains trains
          if (_nextTrains.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Prochains Départs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            ..._buildTrainCards(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.train, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Prochains Trains',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_activeTrips.length} trajet${_activeTrips.length > 1 ? 's' : ''} actif${_activeTrips.length > 1 ? 's' : ''} aujourd\'hui',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTripCards() {
    if (_activeTrips.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(height: 8),
                const Text(
                  'Aucun trajet configuré',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ajoutez vos trajets quotidiens pour voir les horaires',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _navigateToAddTrip(context),
                  child: const Text('Ajouter un trajet'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _activeTrips.map((trip) => _buildTripCard(trip)).toList();
  }

  Widget _buildTripCard(domain.Trip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.train, color: Color(0xFF4A90E2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${trip.departureStation.name} → ${trip.arrivalStation.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTripAction(value, trip),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy),
                          SizedBox(width: 8),
                          Text('Dupliquer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.power_settings_new),
                          SizedBox(width: 8),
                          Text('Activer/Désactiver'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  trip.isActive ? Icons.check_circle : Icons.cancel,
                  color: trip.isActive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  trip.isActive ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: trip.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  trip.notificationsEnabled ? Icons.notifications : Icons.notifications_off,
                  size: 16,
                  color: trip.notificationsEnabled ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  trip.notificationsEnabled ? 'Notifications' : 'Pas de notifications',
                  style: TextStyle(
                    color: trip.notificationsEnabled ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Jours: ${trip.daysName}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Heure: ${trip.timeFormatted}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showTripDetails(trip),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Voir les horaires'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit les cartes des trains
  List<Widget> _buildTrainCards() {
    return _nextTrains.map((train) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(train.status),
          child: Icon(
            _getStatusIcon(train.status),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          '${train.departureTimeFormatted} - ${train.direction}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(train.statusText),
        trailing: train.isDelayed
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${train.delayMinutes}min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    )).toList();
  }

  Color _getStatusColor(TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return Colors.green;
      case TrainStatus.delayed:
        return Colors.orange;
      case TrainStatus.early:
        return Colors.blue;
      case TrainStatus.cancelled:
        return Colors.red;
      case TrainStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TrainStatus status) {
    switch (status) {
      case TrainStatus.onTime:
        return Icons.check_circle;
      case TrainStatus.delayed:
        return Icons.schedule;
      case TrainStatus.early:
        return Icons.schedule;
      case TrainStatus.cancelled:
        return Icons.cancel;
      case TrainStatus.unknown:
        return Icons.help;
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  void _navigateToAddTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTripPage(),
      ),
    );
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
          await DependencyInjection.instance.tripService.deleteTrip(trip.id);
          _loadActiveTrips();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trajet supprimé')),
          );
        }
        break;
    }
  }

  void _showTripDetails(domain.Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripSchedulePage(trip: trip),
      ),
    );
  }
}
