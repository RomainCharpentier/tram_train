import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
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
  DateTime? _lastRequestedRef;

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
      final service = DependencyInjection.instance.trainService;
      final ref = _computeReferenceDateTime(widget.trip);
      _lastRequestedRef = ref;

      // 1) Trajets à/près de l'heure (donne l'après)
      final base = await service.findJourneysWithDepartureTime(
        widget.trip.departureStation,
        widget.trip.arrivalStation,
        ref,
      );
      base.sort((a, b) => a.departureTime.compareTo(b.departureTime));

      // 2) Trajet juste après (premier >= ref)
      Train? after;
      for (final t in base) {
        if (!t.departureTime.isBefore(ref)) {
          after = t;
          break;
        }
      }

      // 3) Trajet juste avant via pagination prev
      final before = await service.findJourneyJustBefore(
        widget.trip.departureStation,
        widget.trip.arrivalStation,
        ref,
      );

      // 4) Contrainte: garder "avant" si même jour ou <= 3h d'écart
      final result = <Train>[];
      if (before != null) {
        final tt = before.departureTime;
        final sameDay =
            tt.year == ref.year && tt.month == ref.month && tt.day == ref.day;
        final within3h = ref.difference(tt) <= const Duration(hours: 3);
        if (sameDay || within3h) {
          result.add(before);
        }
      }
      if (after != null &&
          (result.isEmpty ||
              result.first.departureTime != after.departureTime)) {
        result.add(after);
      }

      setState(() {
        _allTrains = result;
        _filteredTrains = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les horaires: $e';
        _isLoading = false;
      });
    }
  }

  DateTime _computeReferenceDateTime(domain.Trip trip) {
    final now = DateTime.now();
    final baseToday = DateTime(
      now.year,
      now.month,
      now.day,
      trip.time.hour,
      trip.time.minute,
    );

    final targetWeekday = trip.day.index + 1; // 1 = Lundi ... 7 = Dimanche
    int delta = (targetWeekday - baseToday.weekday) % 7;
    if (delta == 0 && baseToday.isBefore(now)) {
      delta = 7; // même jour mais heure passée -> semaine suivante
    }
    final bestDelta = delta;

    return baseToday.add(Duration(days: bestDelta % 7));
  }

  String _formatRefLabel(DateTime dt) {
    const names = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    final dayName = names[(dt.weekday - 1).clamp(0, 6)];
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$dayName $dd/$mm • $hh:$mn';
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
                Icon(Icons.train, color: context.theme.primary),
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
                  color: widget.trip.isActive
                      ? context.theme.success
                      : context.theme.error,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.trip.isActive ? 'Trajet actif' : 'Trajet inactif',
                  style: TextStyle(
                    color: widget.trip.isActive
                        ? context.theme.success
                        : context.theme.error,
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
                      ? context.theme.warning
                      : context.theme.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.trip.notificationsEnabled
                      ? 'Notifications'
                      : 'Pas de notifications',
                  style: TextStyle(
                    color: widget.trip.notificationsEnabled
                        ? context.theme.warning
                        : context.theme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Jours: ${widget.trip.daysName}',
              style: TextStyle(color: context.theme.textSecondary),
            ),
            Text(
              'Heure souhaitée: ${widget.trip.timeFormatted}',
              style: TextStyle(color: context.theme.textSecondary),
            ),
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
            ? "Essayez avec d'autres mots-clés"
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
        backgroundColor: context.theme.primary,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                // Toujours afficher la cible choisie (jour + heure sélectionnés)
                'Affichage pour: ${_formatRefLabel(_lastRequestedRef ?? _computeReferenceDateTime(widget.trip))}',
                style: TextStyle(color: context.theme.textSecondary),
              ),
            ),
          ),
          if (_lastRequestedRef != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Demandée: ${_formatRefLabel(_lastRequestedRef!)}',
                  style: TextStyle(color: context.theme.textSecondary),
                ),
              ),
            ),
          if (_filteredTrains.isNotEmpty)
            Builder(builder: (context) {
              final ref =
                  _lastRequestedRef ?? _computeReferenceDateTime(widget.trip);
              DateTime? before;
              DateTime? after;
              for (final t in _filteredTrains) {
                final dt = t.departureTime;
                if (dt.isBefore(ref)) {
                  if (before == null || dt.isAfter(before)) before = dt;
                } else {
                  if (after == null || dt.isBefore(after)) after = dt;
                }
              }
              // plus de badge avant/après
              return const SizedBox.shrink();
            }),
          if (_filteredTrains.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Builder(builder: (context) {
                  final first = _filteredTrains.first.departureTime;
                  return Text(
                    'Premier départ trouvé: ${_formatRefLabel(first)}',
                    style: TextStyle(color: context.theme.textSecondary),
                  );
                }),
              ),
            ),
          Expanded(child: _buildTrainsList()),
        ],
      ),
    );
  }
}
