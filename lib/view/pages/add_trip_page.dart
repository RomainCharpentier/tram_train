import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart' as domain_train;
import '../../domain/models/station.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../infrastructure/dependency_injection.dart';
import 'station_search_page.dart';
import '../widgets/switch_card.dart';
import '../widgets/save_button.dart';
import '../theme/theme_x.dart';

enum TimeConstraintMode { departure, arrival }

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  Station? _departureStation;
  Station? _arrivalStation;
  final List<domain.DayOfWeek> _selectedDays = [];
  flutter.TimeOfDay? _selectedTime;
  bool _isActive = true;
  bool _notificationsEnabled = true;
  bool _directTrainsOnly =
      true; // Nouvelle option pour trajets directs uniquement
  String? _connectionError;

  // Sélection d'un train précis autour d'une heure
  TimeConstraintMode _timeMode = TimeConstraintMode.departure;
  List<domain_train.Train> _candidateTrains = [];
  List<domain_train.Train> _allTrains = [];
  String? _selectedTrainId;
  bool _isLoadingCandidates = false;
  bool _hasSearchedCandidates = false;
  int _pageIndex = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un favori'),
        backgroundColor: context.theme.primary,
        foregroundColor: context.theme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Station de départ
            Card(
              color: _connectionError != null
                  ? (_connectionError!.startsWith('✅')
                      ? context.theme.successBg
                      : context.theme.errorBg)
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.train,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? context.theme.success
                          : context.theme.error)
                      : context.theme.primary,
                ),
                title: Text(
                  _departureStation?.name ??
                      'Sélectionner la station de départ',
                  style: TextStyle(
                      color: _connectionError != null
                          ? (_connectionError!.startsWith('✅')
                              ? context.theme.success
                              : context.theme.error)
                          : null),
                ),
                subtitle: _departureStation != null
                    ? Text(
                        _departureStation!.description ?? '',
                        style: TextStyle(
                            color: _connectionError != null
                                ? (_connectionError!.startsWith('✅')
                                    ? context.theme.success
                                    : context.theme.error)
                                : null),
                      )
                    : Text(
                        'Choisissez votre station de départ',
                        style: TextStyle(
                            color: _connectionError != null
                                ? (_connectionError!.startsWith('✅')
                                    ? context.theme.success
                                    : context.theme.error)
                                : null),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? context.theme.success
                          : context.theme.error)
                      : null,
                ),
                onTap: () => _selectStation(true),
              ),
            ),

            const SizedBox(height: 8),

            // Bouton d'inversion des stations
            Center(
              child: IconButton(
                onPressed: _swapStations,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                tooltip: 'Inverser les stations',
              ),
            ),

            const SizedBox(height: 8),

            // Station d'arrivée
            Card(
              color: _connectionError != null
                  ? (_connectionError!.startsWith('✅')
                      ? context.theme.successBg
                      : context.theme.errorBg)
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? context.theme.success
                          : context.theme.error)
                      : (_departureStation != null
                          ? context.theme.secondary
                          : context.theme.muted),
                ),
                title: Text(
                  _arrivalStation?.name ?? 'Sélectionner la station d\'arrivée',
                  style: TextStyle(
                    color: _connectionError != null
                        ? (_connectionError!.startsWith('✅')
                            ? context.theme.success
                            : context.theme.error)
                        : (_departureStation != null ? null : context.theme.muted),
                  ),
                ),
                subtitle: _arrivalStation != null
                    ? Text(
                        _arrivalStation!.description ?? '',
                        style: TextStyle(
                            color: _connectionError != null
                                ? (_connectionError!.startsWith('✅')
                                    ? context.theme.success
                                    : context.theme.error)
                                : null),
                      )
                    : Text(
                        _departureStation != null
                            ? 'Choisissez votre station d\'arrivée'
                            : 'Sélectionnez d\'abord la station de départ',
                        style: TextStyle(
                          color: _connectionError != null
                              ? (_connectionError!.startsWith('✅')
                                  ? context.theme.success
                                  : context.theme.error)
                              : (_departureStation != null
                                  ? null
                                  : context.theme.muted),
                        ),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? context.theme.success
                          : context.theme.error)
                      : (_departureStation != null ? null : context.theme.muted),
                ),
                onTap: _departureStation != null
                    ? () => _selectStation(false)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Veuillez d\'abord sélectionner la station de départ'),
                            backgroundColor: context.theme.warning,
                          ),
                        );
                      },
              ),
            ),

            // Message d'erreur/succès de connexion
            if (_connectionError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionError!.startsWith('✅')
                      ? context.theme.successBg
                      : context.theme.errorBg,
                  border: Border.all(
                      color: _connectionError!.startsWith('✅')
                          ? context.theme.successBorder
                          : context.theme.errorBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                        _connectionError!.startsWith('✅')
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _connectionError!.startsWith('✅')
                            ? context.theme.success
                            : context.theme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionError!,
                        style: TextStyle(
                          color: _connectionError!.startsWith('✅')
                              ? context.theme.success
                              : context.theme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Jours de la semaine
            const Text(
              'Jours de la semaine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: domain.DayOfWeek.values.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays
                          ..clear()
                          ..add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                    _maybeAutoSearch();
                  },
                  selectedColor: context.theme.primary.withValues(alpha: 0.3),
                  checkmarkColor: context.theme.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Heure de départ
            Card(
              child: ListTile(
                leading:
                    Icon(Icons.access_time, color: context.theme.primary),
                title: Text(
                  _timeMode == TimeConstraintMode.departure
                      ? (_selectedTime != null
                          ? 'Départ vers ${_selectedTime!.format(context)}'
                          : 'Sélectionner l\'heure de départ')
                      : (_selectedTime != null
                          ? 'Arrivée vers ${_selectedTime!.format(context)}'
                          : 'Sélectionner l\'heure d\'arrivée'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectTime,
              ),
            ),

            const SizedBox(height: 24),

            // Contrainte horaire (départ/arrivée) – sans tolérance
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Center(
                  child: ToggleButtons(
                    isSelected: [
                      _timeMode == TimeConstraintMode.departure,
                      _timeMode == TimeConstraintMode.arrival,
                    ],
                    onPressed: (i) {
                      setState(() => _timeMode = i == 0
                          ? TimeConstraintMode.departure
                          : TimeConstraintMode.arrival);
                      _maybeAutoSearch();
                    },
                    children: const [
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Départ')),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Arrivée')),
                    ],
                  ),
                ),
              ),
            ),

            // Proposer des trains
            ElevatedButton.icon(
              onPressed: (_departureStation != null && _arrivalStation != null)
                  ? _loadCandidateTrains
                  : null,
              icon: _isLoadingCandidates
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.theme.onPrimary))
                  : const Icon(Icons.search),
              label: const Text('Filtrer par heure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primary,
                foregroundColor: context.theme.onPrimary,
              ),
            ),

            // Liste des candidats
            // État de chargement / vide / liste
            if (_isLoadingCandidates) ...[
              const SizedBox(height: 8),
              const Center(child: CircularProgressIndicator()),
            ] else if (_hasSearchedCandidates && _candidateTrains.isEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.theme.warning),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              'Aucun train trouvé dans la plage sélectionnée. Ajustez l\'heure ou la tolérance.')),
                    ],
                  ),
                ),
              ),
            ] else if (_candidateTrains.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bandeau Avant/Après
                      if (_selectedTime != null) Builder(builder: (context) {
                        final ref = _buildReferenceDateTime();
                        final before = _candidateTrains
                            .where((t) => t.departureTime.isBefore(ref))
                            .fold<DateTime?>(null, (prev, e) =>
                                prev == null || e.departureTime.isAfter(prev)
                                    ? e.departureTime
                                    : prev);
                        final after = _candidateTrains
                            .where((t) => !t.departureTime.isBefore(ref))
                            .fold<DateTime?>(null, (prev, e) =>
                                prev == null || e.departureTime.isBefore(prev)
                                    ? e.departureTime
                                    : prev);
                        String fmt(DateTime? dt) => dt == null
                            ? 'aucun'
                            : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Chip(
                                avatar: const Icon(Icons.keyboard_double_arrow_left, size: 16),
                                label: Text('Avant: ${fmt(before)}'),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                avatar: const Icon(Icons.keyboard_double_arrow_right, size: 16),
                                label: Text('Après: ${fmt(after)}'),
                              ),
                            ],
                          ),
                        );
                      }),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _candidateTrains.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final t = _candidateTrains[index];
                            return RadioListTile<String>(
                              value: t.id,
                              groupValue: _selectedTrainId,
                              onChanged: (val) {
                                setState(() {
                                  _selectedTrainId = val;
                                  _selectedTime = flutter.TimeOfDay(
                                    hour: t.departureTime.hour,
                                    minute: t.departureTime.minute,
                                  );
                                });
                              },
                              title: Text(
                                  '${t.departureTime.hour.toString().padLeft(2, '0')}:${t.departureTime.minute.toString().padLeft(2, '0')} → ${t.direction}'),
                              subtitle: Text(
                                '${_formatDayLabel(t.departureTime)} • ${t.statusText}',
                                style: TextStyle(color: context.theme.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pagination controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Précédent',
                      onPressed: _pageIndex > 0
                          ? () => _setPage(_pageIndex - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Page ${_pageIndex + 1}'),
                    IconButton(
                      tooltip: 'Suivant',
                      onPressed:
                          _hasNextPage ? () => _setPage(_pageIndex + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],

            // Statut actif
            SwitchCard(
              title: 'Trajet actif',
              subtitle: 'Ce trajet sera affiché sur le tableau de bord',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),

            SwitchCard(
              title: 'Notifications activées',
              subtitle: 'Recevoir des notifications pour ce trajet',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),

            const SizedBox(height: 16),

            // Option pour trajets directs uniquement
            SwitchCard(
              title: 'Trajets directs uniquement',
              subtitle: 'Exclure les trajets avec correspondances',
              value: _directTrainsOnly,
              onChanged: (v) {
                setState(() => _directTrainsOnly = v);
                if (_departureStation != null && _arrivalStation != null) {
                  _validateConnection();
                }
              },
            ),

            const SizedBox(height: 8),

            // Résumé du favori
            if (_departureStation != null &&
                _arrivalStation != null &&
                _selectedTime != null) ...[
              Card(
                elevation: 0,
                color: context.theme.bgCard,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: context.theme.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_departureStation!.name} → ${_arrivalStation!.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.access_time, size: 16),
                            label: Text(_selectedTime!.format(context)),
                          ),
                          if (_selectedDays.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.event, size: 16),
                              label: Text(
                                _selectedDays.length ==
                                        domain.DayOfWeek.values.length
                                    ? 'Tous les jours'
                                    : _selectedDays
                                        .map((d) => d.displayName)
                                        .join(', '),
                              ),
                            ),
                          Chip(
                            avatar:
                                const Icon(Icons.directions_railway, size: 16),
                            label: Text(_directTrainsOnly
                                ? 'Direct uniquement'
                                : 'Avec correspondances'),
                          ),
                          Chip(
                            avatar: const Icon(
                                Icons.notifications_active_outlined,
                                size: 16),
                            label: Text(_notificationsEnabled
                                ? 'Notifications ON'
                                : 'Notifications OFF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Bouton de sauvegarde
            SaveButton(
              label: 'Enregistrer le trajet',
              enabled: _departureStation != null &&
                  _arrivalStation != null &&
                  _selectedDays.isNotEmpty &&
                  _selectedTime != null,
              onPressed: _saveTrip,
            ),
          ],
        ),
      ),
    );
  }

  void _maybeAutoSearch() {
    if (_departureStation != null && _arrivalStation != null) {
      _loadCandidateTrains();
    }
  }

  

  Future<void> _selectStation(bool isDeparture) async {
    final result = await Navigator.push<Station>(
      context,
      MaterialPageRoute(
        builder: (context) => StationSearchPage(
          departureStation: isDeparture ? null : _departureStation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isDeparture) {
          _departureStation = result;
        } else {
          _arrivalStation = result;
        }
      });

      // Charger les trains dès que les deux gares sont sélectionnées
      if (_departureStation != null && _arrivalStation != null) {
        _loadAllTrains();
      }
    }
  }

  /// Valide la connexion entre les gares sélectionnées
  Future<void> _validateConnection() async {
    if (_departureStation == null || _arrivalStation == null) return;

    try {
      // Utiliser la nouvelle méthode avec plus d'informations
      final result = await ConnectedStationsService.checkConnection(
        _departureStation!,
        _arrivalStation!,
        directOnly: _directTrainsOnly,
      );

      setState(() {
        if (!result.isConnected) {
          _connectionError = '⚠️ ${result.message}';
        } else {
          _connectionError = '✅ ${result.message}';
        }
      });
    } catch (e) {
      setState(() {
        _connectionError = 'Erreur lors de la validation: $e';
      });
    }
  }

  void _swapStations() {
    setState(() {
      final temp = _departureStation;
      _departureStation = _arrivalStation;
      _arrivalStation = temp;
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const flutter.TimeOfDay(hour: 8, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
      _maybeAutoSearch();
    }
  }

  DateTime _buildReferenceDateTime() {
    final now = DateTime.now();
    final hour = _selectedTime?.hour ?? now.hour;
    final minute = _selectedTime?.minute ?? now.minute;
    final baseToday = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (_selectedDays.isEmpty) {
      return baseToday;
    }

    // Chercher la prochaine occurrence parmi tous les jours sélectionnés
    int bestDelta = 8; // plus que max 7
    for (final d in _selectedDays) {
      final targetWeekday = d.index + 1; // 1=Lundi ... 7=Dimanche
      int delta = (targetWeekday - baseToday.weekday) % 7;
      if (delta == 0 && baseToday.isBefore(now)) {
        // même jour mais heure déjà passée → semaine suivante
        delta = 7;
      }
      if (delta < bestDelta) bestDelta = delta;
    }

    return baseToday.add(Duration(days: bestDelta % 7));
  }

  void _applyPagination(List<domain_train.Train> list) {
    list.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    final totalPages = (list.length / _pageSize).ceil();
    if (_pageIndex >= totalPages) {
      _pageIndex = (totalPages - 1).clamp(0, totalPages);
    }
    final start = _pageIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, list.length);
    setState(() {
      _candidateTrains = list.sublist(start, end);
    });
  }

  void _setPage(int index) {
    setState(() {
      _pageIndex = index;
    });
    // Re-appliquer pagination sur la source actuelle (_allTrains ou derniers filtrés)
    final source = _allTrains.isNotEmpty ? _allTrains : _candidateTrains;
    _applyPagination(List<domain_train.Train>.from(source));
  }

  bool get _hasNextPage {
    final source = _allTrains.isNotEmpty ? _allTrains : _candidateTrains;
    final totalPages = (source.length / _pageSize).ceil();
    return _pageIndex + 1 < totalPages;
  }

  String _formatDayLabel(DateTime dt) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final name = names[(dt.weekday - 1).clamp(0, 6)];
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$name $dd/$mm';
  }

  List<domain_train.Train> _deduplicateTrains(List<domain_train.Train> trains) {
    final seen = <String>{};
    final result = <domain_train.Train>[];
    for (final t in trains) {
      final key = '${t.id}-${t.departureTime.toIso8601String()}';
      final timeKey =
          '${t.departureTime.hour}:${t.departureTime.minute}-${t.direction}';
      // Utiliser clé stricte puis clé horaire si id instable
      if (!seen.contains(key) && !seen.contains(timeKey)) {
        seen.add(key);
        seen.add(timeKey);
        result.add(t);
      }
    }
    return result;
  }

  Future<void> _loadCandidateTrains() async {
    if (_departureStation == null || _arrivalStation == null) return;
    setState(() {
      _isLoadingCandidates = true;
      _selectedTrainId = null;
      _hasSearchedCandidates = true;
    });

    try {
      final service = DependencyInjection.instance.trainService;

      // Si une heure est choisie, toujours recharger depuis l'API autour de cette heure
      if (_selectedTime != null) {
        final ref = _buildReferenceDateTime();
        List<domain_train.Train> trains;
        if (_timeMode == TimeConstraintMode.departure) {
          trains = await service.findJourneysWithDepartureTime(
              _departureStation!, _arrivalStation!, ref);
        } else {
          trains = await service.findJourneysWithArrivalTime(
              _departureStation!, _arrivalStation!, ref);
        }
        if (_directTrainsOnly) {
          trains = trains.where((t) => t.isDirect).toList();
        }
        var subset = _deduplicateTrains(trains);

        // Ne garder que 2 trajets: le plus proche APRÈS et le plus proche AVANT l'heure cible
        // Référence exacte (même date/heure que la requête envoyée)
        final targetRef = ref;
        DateTime getRefTime(domain_train.Train t) => t.departureTime;

        // Trier par horaire croissant sur le champ de référence
        subset.sort((a, b) => getRefTime(a).compareTo(getRefTime(b)));

        domain_train.Train? after;
        for (final t in subset) {
          final tt = getRefTime(t);
          if (!tt.isBefore(targetRef)) {
            after = t;
            break;
          }
        }

        domain_train.Train? before;
        for (var i = subset.length - 1; i >= 0; i--) {
          final t = subset[i];
          final tt = getRefTime(t);
          if (tt.isBefore(targetRef)) {
            before = t;
            break;
          }
        }

        // Si on n'a pas de "before", utiliser uniquement la pagination journeys: lien 'prev'
        if (before == null) {
          try {
            final byPrev = await service.findJourneyJustBefore(
                _departureStation!, _arrivalStation!, targetRef);
            if (byPrev != null) {
              before = byPrev;
              subset = _deduplicateTrains([...subset, byPrev]);
              subset.sort((a, b) => getRefTime(a).compareTo(getRefTime(b)));
            }
          } catch (_) {}
        }

        // Si on n'a pas d'"after", utiliser uniquement la pagination journeys: lien 'next'
        if (after == null) {
          try {
            final byNext = await service.findJourneyJustAfter(
                _departureStation!, _arrivalStation!, targetRef);
            if (byNext != null) {
              after = byNext;
              subset = _deduplicateTrains([...subset, byNext]);
              subset.sort((a, b) => getRefTime(a).compareTo(getRefTime(b)));
            }
          } catch (_) {}
        }

        // Construire la liste finale (au plus 2 éléments)
        final result = <domain_train.Train>[];

        // Conserver le "before" uniquement s'il est le même jour que la cible
        // ou à défaut dans une fenêtre maximale de 3h avant la cible
        if (before != null) {
          final ttBefore = getRefTime(before);
          final sameDay = ttBefore.year == targetRef.year &&
              ttBefore.month == targetRef.month &&
              ttBefore.day == targetRef.day;
          final within3h = targetRef.difference(ttBefore) <=
              const Duration(hours: 3);
          if (sameDay || within3h) {
            result.add(before);
          }
        }
        if (after != null && (before == null || after.id != before.id ||
            getRefTime(after) != getRefTime(before))) {
          result.add(after);
        }

        setState(() {
          _pageIndex = 0;
          _candidateTrains = result;
        });
        return;
      }

      // Sinon, on filtre localement la liste déjà chargée autour de maintenant
      if (_allTrains.isEmpty) {
        await _loadAllTrains();
      }
      List<domain_train.Train> subset = _deduplicateTrains(_allTrains);
      if (_directTrainsOnly) {
        subset = subset.where((t) => t.isDirect).toList();
      }
      subset.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      _applyPagination(subset);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la proposition des trains: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCandidates = false;
        });
      }
    }
  }

  /// Charge tous les trains disponibles entre les deux gares
  Future<void> _loadAllTrains() async {
    if (_departureStation == null || _arrivalStation == null) return;

    setState(() {
      _isLoadingCandidates = true;
      _candidateTrains = [];
      _selectedTrainId = null;
      _hasSearchedCandidates = true;
    });

    try {
      final service = DependencyInjection.instance.trainService;
      // Récupère les départs à la gare de départ puis filtre la direction qui contient la gare d'arrivée
      var departures = await service.getDepartures(_departureStation!);
      // Étendre la fenêtre en récupérant aussi un créneau +1h
      final plusOneHour = DateTime.now().add(const Duration(hours: 1));
      final more =
          await service.getDeparturesAt(_departureStation!, plusOneHour);
      departures = [...departures, ...more];
      var filteredTrains =
          service.filterByDirection(departures, _arrivalStation!.name);
      if (_directTrainsOnly) {
        filteredTrains = filteredTrains.where((t) => t.isDirect).toList();
      }
      filteredTrains.sort((a, b) => a.departureTime.compareTo(b.departureTime));
      final deduped = _deduplicateTrains(filteredTrains);
      setState(() {
        _allTrains = deduped;
      });
      _applyPagination(deduped);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCandidates = false;
        });
      }
    }
  }

  Future<void> _saveTrip() async {
    if (_departureStation == null ||
        _arrivalStation == null ||
        _selectedTime == null) {
      return;
    }

    try {
      // Vérifier que les gares sont connectées
      final result = await ConnectedStationsService.checkConnection(
        _departureStation!,
        _arrivalStation!,
        directOnly: _directTrainsOnly,
      );

      if (!result.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ ${result.message}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return; // Bloquer la sauvegarde
      }

      final trip = domain.Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        departureStation: _departureStation!,
        arrivalStation: _arrivalStation!,
        days: _selectedDays,
        time: domain.TimeOfDay(
          hour: _selectedTime!.hour,
          minute: _selectedTime!.minute,
        ),
        isActive: _isActive,
        notificationsEnabled: _notificationsEnabled,
        createdAt: DateTime.now(),
      );

      await DependencyInjection.instance.tripService.saveTrip(trip);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Trajet enregistré avec succès !'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
