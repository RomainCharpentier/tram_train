import 'package:flutter/material.dart';
import '../../domain/models/train.dart';
import '../../domain/models/trip.dart' as domain;
import '../../infrastructure/dependency_injection.dart';

/// Page pour afficher les horaires d'un trajet avec recherche
class TripSchedulePage extends StatefulWidget {
  final domain.Trip trip;
  
  const TripSchedulePage({super.key, required this.trip});

  @override
  State<TripSchedulePage> createState() => _TripSchedulePageState();
}

class _TripSchedulePageState extends State<TripSchedulePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Train> _allTrains = [];
  List<Train> _filteredTrains = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrains();
    _searchController.addListener(_filterTrains);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les trains depuis l'API
  Future<void> _loadTrains() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🚂 Chargement des horaires pour ${widget.trip.departureStation.name} → ${widget.trip.arrivalStation.name}');
      final trains = await DependencyInjection.instance.trainService.getNextDepartures(
        widget.trip.departureStation,
      );
      print('✅ Trouvé ${trains.length} trains');
      
      // Filtrer les trains qui vont vers la destination
      final filteredTrains = trains.where((train) => 
        train.direction.toLowerCase().contains(widget.trip.arrivalStation.name.toLowerCase()) ||
        widget.trip.arrivalStation.name.toLowerCase().contains(train.direction.toLowerCase())
      ).toList();
      
      print('🎯 ${filteredTrains.length} trains filtrés pour ${widget.trip.arrivalStation.name}');
      
      setState(() {
        _allTrains = filteredTrains;
        _filteredTrains = filteredTrains;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      setState(() {
        _error = 'Impossible de charger les horaires: $e';
        _isLoading = false;
      });
    }
  }

  /// Filtre les trains selon la recherche
  void _filterTrains() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredTrains = _allTrains;
      });
      return;
    }

    setState(() {
      _filteredTrains = _allTrains.where((train) =>
        train.direction.toLowerCase().contains(query) ||
        train.departureTimeFormatted.contains(query) ||
        train.statusText.toLowerCase().contains(query)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.trip.departureStation.name} → ${widget.trip.arrivalStation.name}'),
        backgroundColor: const Color(0xFF4A90E2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTrains,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTripInfo(),
          Expanded(child: _buildTrainsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher par destination, heure ou statut...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterTrains();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    '${widget.trip.departureStation.name} → ${widget.trip.arrivalStation.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.trip.isActive ? Icons.check_circle : Icons.cancel,
                  color: widget.trip.isActive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.trip.isActive ? 'Trajet actif' : 'Trajet inactif',
                  style: TextStyle(
                    color: widget.trip.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  widget.trip.notificationsEnabled ? Icons.notifications : Icons.notifications_off,
                  size: 16,
                  color: widget.trip.notificationsEnabled ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.trip.notificationsEnabled ? 'Notifications' : 'Pas de notifications',
                  style: TextStyle(
                    color: widget.trip.notificationsEnabled ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Jours: ${widget.trip.daysName}'),
            Text('Heure souhaitée: ${widget.trip.timeFormatted}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des horaires...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrains,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredTrains.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.train, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty 
                ? 'Aucun train trouvé pour "${_searchController.text}"'
                : 'Aucun train trouvé pour cette destination',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Vérifiez que la gare de destination est correcte',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTrains.length,
      itemBuilder: (context, index) {
        final train = _filteredTrains[index];
        return _buildTrainCard(train);
      },
    );
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
            size: 20,
          ),
        ),
        title: Text(
          train.direction,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Départ: ${train.departureTimeFormatted}'),
            if (train.isDelayed)
              Text(
                'Retard: +${train.delayMinutes} minutes',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              train.statusText,
              style: TextStyle(
                color: _getStatusColor(train.status),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (train.additionalInfo.isNotEmpty)
              Text(
                train.additionalInfo.first,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        onTap: () => _showTrainDetails(train),
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
            Text('Départ: ${train.departureTimeFormatted}'),
            Text('Statut: ${train.statusText}'),
            if (train.baseDepartureTime != null)
              Text('Heure prévue: ${train.baseDepartureTime!.hour.toString().padLeft(2, '0')}:${train.baseDepartureTime!.minute.toString().padLeft(2, '0')}'),
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
}
