import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart';
import '../../dependency_injection.dart';
import 'profile_page.dart';
import 'add_trip_page.dart';
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
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
    if (_nextTrains.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(height: 8),
                const Text(
                  'Aucun train trouvé',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vérifiez les horaires ou réessayez plus tard',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadNextTrains,
                  child: const Text('Actualiser'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _nextTrains.map((train) => _buildTrainCard(train)).toList();
  }

  Widget _buildTrainCard(Train train) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(train.status),
          child: Icon(
            _getStatusIcon(train.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          train.direction,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${train.station.name} → ${train.direction}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  train.departureTimeFormatted,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (train.isDelayed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Retard ${train.delayMinutes}min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showTrainDetails(train),
        ),
      ),
    );
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

  void _showTrainDetails(Train train) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(train.direction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gare: ${train.station.name}'),
            Text('Départ: ${train.departureTimeFormatted}'),
            if (train.isDelayed)
              Text('Retard: ${train.delayMinutes} minutes'),
            if (train.additionalInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Informations:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...train.additionalInfo.map((info) => Text('• $info')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
        builder: (context) => AddTripPage(),
      ),
    );
  }
}
