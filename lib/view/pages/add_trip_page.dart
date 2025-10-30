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
  int _toleranceMinutes = 10;
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
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      ? Colors.green.shade50
                      : Colors.red.shade50)
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.train,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? Colors.green
                          : Colors.red)
                      : const Color(0xFF4A90E2),
                ),
                title: Text(
                  _departureStation?.name ??
                      'Sélectionner la station de départ',
                  style: TextStyle(
                      color: _connectionError != null
                          ? (_connectionError!.startsWith('✅')
                              ? Colors.green
                              : Colors.red)
                          : null),
                ),
                subtitle: _departureStation != null
                    ? Text(
                        _departureStation!.description ?? '',
                        style: TextStyle(
                            color: _connectionError != null
                                ? (_connectionError!.startsWith('✅')
                                    ? Colors.green.shade700
                                    : Colors.red.shade700)
                                : null),
                      )
                    : Text(
                        'Choisissez votre station de départ',
                        style: TextStyle(
                            color: _connectionError != null
                                ? (_connectionError!.startsWith('✅')
                                    ? Colors.green.shade700
                                    : Colors.red.shade700)
                                : null),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? Colors.green
                          : Colors.red)
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
                    color: const Color(0xFF4A90E2),
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
                      ? Colors.green.shade50
                      : Colors.red.shade50)
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? Colors.green
                          : Colors.red)
                      : (_departureStation != null
                          ? const Color(0xFF2E5BBA)
                          : Colors.grey),
                ),
                title: Text(
                  _arrivalStation?.name ?? 'Sélectionner la station d\'arrivée',
                  style: TextStyle(
                    color: _connectionError != null
                        ? (_connectionError!.startsWith('✅')
                            ? Colors.green
                            : Colors.red)
                        : (_departureStation != null ? null : Colors.grey),
                  ),
                ),
                subtitle: _arrivalStation != null
                    ? Text(
                        _arrivalStation!.description ?? '',
                        style: TextStyle(
                            color: _connectionError != null
                                ? (_connectionError!.startsWith('✅')
                                    ? Colors.green.shade700
                                    : Colors.red.shade700)
                                : null),
                      )
                    : Text(
                        _departureStation != null
                            ? 'Choisissez votre station d\'arrivée'
                            : 'Sélectionnez d\'abord la station de départ',
                        style: TextStyle(
                          color: _connectionError != null
                              ? (_connectionError!.startsWith('✅')
                                  ? Colors.green.shade700
                                  : Colors.red.shade700)
                              : (_departureStation != null
                                  ? null
                                  : Colors.grey),
                        ),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? Colors.green
                          : Colors.red)
                      : (_departureStation != null ? null : Colors.grey),
                ),
                onTap: _departureStation != null
                    ? () => _selectStation(false)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Veuillez d\'abord sélectionner la station de départ'),
                            backgroundColor: Colors.orange,
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
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                      color: _connectionError!.startsWith('✅')
                          ? Colors.green.shade200
                          : Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                        _connectionError!.startsWith('✅')
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _connectionError!.startsWith('✅')
                            ? Colors.green.shade600
                            : Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionError!,
                        style: TextStyle(
                          color: _connectionError!.startsWith('✅')
                              ? Colors.green.shade700
                              : Colors.red.shade700,
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
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                    _maybeAutoSearch();
                  },
                  selectedColor: const Color(0xFF4A90E2).withOpacity(0.3),
                  checkmarkColor: const Color(0xFF4A90E2),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Heure de départ
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.access_time, color: Color(0xFF4A90E2)),
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

            // Contrainte horaire + Tolérance (compact)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    ToggleButtons(
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
                    const Spacer(),
                    const Text('Tolérance'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _toleranceMinutes,
                      items: const [5, 10, 15, 20]
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text('±$m')))
                          .toList(),
                      onChanged: (m) {
                        if (m == null) return;
                        setState(() => _toleranceMinutes = m);
                        _maybeAutoSearch();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Proposer des trains
            ElevatedButton.icon(
              onPressed: (_departureStation != null && _arrivalStation != null)
                  ? _loadCandidateTrains
                  : null,
              icon: _isLoadingCandidates
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: const Text('Filtrer par heure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
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
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange),
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
                child: ConstrainedBox(
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
                        subtitle: Text(t.statusText),
                      );
                    },
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
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFC107)),
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

  Widget _buildSaveButton() {
    final canSave = _departureStation != null &&
        _arrivalStation != null &&
        _selectedDays.isNotEmpty &&
        _selectedTime != null;

    return ElevatedButton(
      onPressed: canSave ? _saveTrip : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Enregistrer le trajet',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
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
    final base = DateTime(now.year, now.month, now.day, _selectedTime!.hour,
        _selectedTime!.minute);
    // Si des jours sont sélectionnés, prendre la prochaine occurrence du premier jour choisi
    if (_selectedDays.isEmpty) return base;
    final targetWeekday =
        _selectedDays.first.index + 1; // DateTime weekday: 1=Mon
    int addDays = (targetWeekday - base.weekday) % 7;
    if (addDays < 0) addDays += 7;
    return base.add(Duration(days: addDays));
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
      // Si on a déjà tous les trains, filtrer localement
      if (_allTrains.isNotEmpty) {
        List<domain_train.Train> subset = _deduplicateTrains(_allTrains);
        if (_directTrainsOnly) {
          subset = subset.where((t) => t.isDirect).toList();
        }
        // Filtre jours sélectionnés (si non vide)
        if (_selectedDays.isNotEmpty) {
          final allowedWeekdays = _selectedDays
              .map((d) => d.index + 1)
              .toSet(); // DateTime.weekday: 1=Mon
          final dayFiltered = subset
              .where((t) => allowedWeekdays.contains(t.departureTime.weekday))
              .toList();
          // Si la source ne couvre pas plusieurs jours et que ça vide la liste, on garde la liste d'origine
          if (dayFiltered.isNotEmpty) {
            subset = dayFiltered;
          }
        }
        // Filtre heure locale HH:mm ± tolérance
        if (_selectedTime != null) {
          // On compare sur les minutes depuis minuit, indépendamment de la date
          int minutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;
          final target = _selectedTime!.hour * 60 + _selectedTime!.minute;
          bool withinTolerance(int a, int b, int tol) => (a - b).abs() <= tol;
          List<domain_train.Train> inTol = subset
              .where((t) => withinTolerance(
                  minutesOfDay(t.departureTime), target, _toleranceMinutes))
              .toList();
          if (inTol.isEmpty) {
            // Repli: trier par proximité HH:mm et prendre une page
            subset.sort((a, b) {
              final da = (minutesOfDay(a.departureTime) - target).abs();
              final db = (minutesOfDay(b.departureTime) - target).abs();
              return da.compareTo(db);
            });
            inTol = subset;
          } else {
            // Ordonner les résultats dans la tolérance par proximité
            inTol.sort((a, b) {
              final da = (minutesOfDay(a.departureTime) - target).abs();
              final db = (minutesOfDay(b.departureTime) - target).abs();
              return da.compareTo(db);
            });
          }
          subset = inTol;
        }
        // Toujours trier par heure de départ pour stabilité
        subset.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        _applyPagination(subset);
      } else {
        // Sinon, charger via API comme avant
        final ref =
            _selectedTime != null ? _buildReferenceDateTime() : DateTime.now();
        final service = DependencyInjection.instance.trainService;
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
        // Appliquer aussi jours/heure sur résultats API
        var subset = _deduplicateTrains(trains);
        if (_selectedDays.isNotEmpty) {
          final allowedWeekdays = _selectedDays.map((d) => d.index + 1).toSet();
          final dayFiltered = subset
              .where((t) => allowedWeekdays.contains(t.departureTime.weekday))
              .toList();
          if (dayFiltered.isNotEmpty) {
            subset = dayFiltered;
          }
        }
        if (_selectedTime != null) {
          int minutesOfDay(DateTime dt) => dt.hour * 60 + dt.minute;
          final target = _selectedTime!.hour * 60 + _selectedTime!.minute;
          bool withinTolerance(int a, int b, int tol) => (a - b).abs() <= tol;
          List<domain_train.Train> inTol = subset
              .where((t) => withinTolerance(
                  minutesOfDay(t.departureTime), target, _toleranceMinutes))
              .toList();
          if (inTol.isEmpty) {
            subset.sort((a, b) {
              final da = (minutesOfDay(a.departureTime) - target).abs();
              final db = (minutesOfDay(b.departureTime) - target).abs();
              return da.compareTo(db);
            });
            inTol = subset;
          } else {
            inTol.sort((a, b) {
              final da = (minutesOfDay(a.departureTime) - target).abs();
              final db = (minutesOfDay(b.departureTime) - target).abs();
              return da.compareTo(db);
            });
          }
          subset = inTol;
        }
        subset.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        _applyPagination(subset);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la proposition des trains: $e'),
            backgroundColor: Colors.red,
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
      print(
          '🚂 Recherche trains: ${_departureStation!.name} → ${_arrivalStation!.name}');
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
      print('❌ Erreur recherche trains: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            backgroundColor: Colors.red,
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
          const SnackBar(
            content: Text('✅ Trajet enregistré avec succès !'),
            backgroundColor: Color(0xFF4A90E2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
