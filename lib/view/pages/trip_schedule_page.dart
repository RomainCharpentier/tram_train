import 'package:flutter/material.dart';
import '../../domain/models/train.dart';
import '../../domain/models/trip.dart' as domain;
import '../../infrastructure/dependency_injection.dart';
import '../widgets/train_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

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

  Future<void> _loadTrains() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trains =
          await DependencyInjection.instance.trainService.getNextDepartures(
        widget.trip.departureStation,
      );

      // Filtrer les trains qui vont vers la destination
      final filteredTrains = trains
          .where((train) =>
              train.direction
                  .toLowerCase()
                  .contains(widget.trip.arrivalStation.name.toLowerCase()) ||
              widget.trip.arrivalStation.name
                  .toLowerCase()
                  .contains(train.direction.toLowerCase()))
          .toList();

      setState(() {
        _allTrains = filteredTrains;
        _filteredTrains = filteredTrains;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les horaires: $e';
        _isLoading = false;
      });
    }
  }

  void _filterTrains() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredTrains = _allTrains;
      });
      return;
    }

    setState(() {
      _filteredTrains = _allTrains
          .where((train) =>
              train.direction.toLowerCase().contains(query) ||
              train.departureTimeFormatted.contains(query) ||
              train.statusText.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AppSearchBar(
        controller: _searchController,
        hintText: 'Rechercher par destination, heure ou statut...',
        onChanged: (_) => _filterTrains(),
        onSubmitted: (_) => _filterTrains(),
        onSearchPressed: _filterTrains,
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
                  widget.trip.notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_off,
                  size: 16,
                  color: widget.trip.notificationsEnabled
                      ? Colors.orange
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.trip.notificationsEnabled
                      ? 'Notifications'
                      : 'Pas de notifications',
                  style: TextStyle(
                    color: widget.trip.notificationsEnabled
                        ? Colors.orange
                        : Colors.grey,
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
      return ErrorState(message: _error!, onRetry: _loadTrains);
    }

    if (_filteredTrains.isEmpty) {
      return EmptyState(
        icon: Icons.train,
        title: _searchController.text.isNotEmpty
            ? 'Aucun train trouvé pour "${_searchController.text}"'
            : 'Aucun train trouvé pour cette destination',
        subtitle: _searchController.text.isNotEmpty
            ? 'Essayez avec d\'autres mots-clés'
            : 'Vérifiez que la gare de destination est correcte',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTrains.length,
      itemBuilder: (context, index) {
        final train = _filteredTrains[index];
        return TrainCard(
          train: train,
          showAdditionalInfo: true,
          onTap: () => _showTrainDetails(train),
        );
      },
    );
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
              Text(
                  'Heure prévue: ${train.baseDepartureTime!.hour.toString().padLeft(2, '0')}:${train.baseDepartureTime!.minute.toString().padLeft(2, '0')}'),
            if (train.additionalInfo.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Informations:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.trip.departureStation.name} → ${widget.trip.arrivalStation.name}'),
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
}
