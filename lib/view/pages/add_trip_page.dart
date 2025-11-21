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
  bool _directTrainsOnly = true;
  String? _connectionError;

  TimeConstraintMode _timeMode = TimeConstraintMode.departure;
  List<domain_train.Train> _candidateTrains = [];
  bool _isLoadingCandidates = false;
  bool _hasSearchedCandidates = false;
  String? _selectedCandidateId;
  List<domain.Trip> _existingTrips = [];

  @override
  void initState() {
    super.initState();
    _loadExistingTrips();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajouter un favori',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: context.theme.primary,
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
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
                  _departureStation?.name ?? 'Sélectionner la station de départ',
                  style: TextStyle(
                    color: _connectionError != null
                        ? (_connectionError!.startsWith('✅')
                            ? context.theme.success
                            : context.theme.error)
                        : context.theme.textPrimary,
                  ),
                ),
                subtitle: _departureStation != null
                    ? Text(
                        _departureStation!.description ?? '',
                        style: TextStyle(
                          color: _connectionError != null
                              ? (_connectionError!.startsWith('✅')
                                  ? context.theme.success
                                  : context.theme.error)
                              : context.theme.textSecondary,
                        ),
                      )
                    : Text(
                        'Choisissez votre station de départ',
                        style: TextStyle(
                          color: _connectionError != null
                              ? (_connectionError!.startsWith('✅')
                                  ? context.theme.success
                                  : context.theme.error)
                              : context.theme.textSecondary,
                        ),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? context.theme.success
                          : context.theme.error)
                      : context.theme.textSecondary,
                ),
                onTap: () => _selectStation(true),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: IconButton(
                onPressed: _swapStations,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.theme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.swap_vert,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    size: 24,
                  ),
                ),
                tooltip: 'Inverser les stations',
              ),
            ),

            const SizedBox(height: 8),

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
                      : (_departureStation != null ? context.theme.secondary : context.theme.muted),
                ),
                title: Text(
                  _arrivalStation?.name ?? "Sélectionner la station d'arrivée",
                  style: TextStyle(
                    color: _connectionError != null
                        ? (_connectionError!.startsWith('✅')
                            ? context.theme.success
                            : context.theme.error)
                        : (_departureStation != null
                            ? context.theme.textPrimary
                            : context.theme.muted),
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
                              : context.theme.textSecondary,
                        ),
                      )
                    : Text(
                        _departureStation != null
                            ? "Choisissez votre station d'arrivée"
                            : "Sélectionnez d'abord la station de départ",
                        style: TextStyle(
                          color: _connectionError != null
                              ? (_connectionError!.startsWith('✅')
                                  ? context.theme.success
                                  : context.theme.error)
                              : (_departureStation != null
                                  ? context.theme.textSecondary
                                  : context.theme.muted),
                        ),
                      ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: _connectionError != null
                      ? (_connectionError!.startsWith('✅')
                          ? context.theme.success
                          : context.theme.error)
                      : (_departureStation != null
                          ? context.theme.textSecondary
                          : context.theme.muted),
                ),
                onTap: _departureStation != null
                    ? () => _selectStation(false)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Veuillez d'abord sélectionner la station de départ",
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? context.theme.warning.withValues(alpha:0.75)
                                : context.theme.warning,
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
                    Icon(_connectionError!.startsWith('✅') ? Icons.check_circle : Icons.warning,
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

            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.theme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.theme.outline),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha:0.3)
                        : Colors.black.withValues(alpha:0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.access_time, color: context.theme.primary),
                title: Text(
                  _timeMode == TimeConstraintMode.departure
                      ? (_selectedTime != null
                          ? 'Départ vers ${_selectedTime!.format(context)}'
                          : "Sélectionner l'heure de départ")
                      : (_selectedTime != null
                          ? 'Arrivée vers ${_selectedTime!.format(context)}'
                          : "Sélectionner l'heure d'arrivée"),
                  style: TextStyle(color: context.theme.textPrimary),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: context.theme.textSecondary),
                onTap: _selectTime,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.theme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.theme.outline),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(alpha:0.3)
                        : Colors.black.withValues(alpha:0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Center(
                  child: ToggleButtons(
                    isSelected: [
                      _timeMode == TimeConstraintMode.departure,
                      _timeMode == TimeConstraintMode.arrival,
                    ],
                    onPressed: (i) {
                      setState(() => _timeMode =
                          i == 0 ? TimeConstraintMode.departure : TimeConstraintMode.arrival);
                      _maybeAutoSearch();
                    },
                    color: context.theme.textSecondary,
                    selectedColor: context.theme.primary,
                    fillColor: context.theme.primary.withValues(alpha:0.1),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Départ', style: TextStyle(color: context.theme.textPrimary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Arrivée', style: TextStyle(color: context.theme.textPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bouton "Filtrer par heure" retiré (recherche auto)

            // Liste des candidats
            // État de chargement / vide / liste
            if (_isLoadingCandidates) ...[
              const SizedBox(height: 8),
              const Center(child: CircularProgressIndicator()),
            ] else if (_hasSearchedCandidates && _candidateTrains.isEmpty) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.theme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.theme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha:0.3)
                          : Colors.black.withValues(alpha:0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.theme.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Aucun train trouvé autour de l'horaire choisi.",
                          style: TextStyle(color: context.theme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_candidateTrains.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.theme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.theme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha:0.3)
                          : Colors.black.withValues(alpha:0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // liste des 2 trajets candidats
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _candidateTrains.length > 2 ? 2 : _candidateTrains.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: context.theme.outline,
                          ),
                          itemBuilder: (context, index) {
                            final t = _candidateTrains[index];
                            final arr = t.arrivalTime;
                            final depStr = _formatHHmm(t.departureTime);
                            final arrStr = arr != null ? _formatHHmm(arr) : '??:??';
                            final key = _candidateKey(t);
                            final already = _isAlreadySavedTrain(t);
                            final isSelected = _selectedCandidateId == key;
                            return Column(
                              children: [
                                // ignore: deprecated_member_use
                                RadioListTile<String>(
                                  value: key,
                                  // ignore: deprecated_member_use
                                  groupValue: _selectedCandidateId,
                                  // ignore: deprecated_member_use
                                  onChanged: already
                                      ? null
                                      : (val) {
                                          setState(() {
                                            _selectedCandidateId = key;
                                            _selectedTime = flutter.TimeOfDay(
                                              hour: t.departureTime.hour,
                                              minute: t.departureTime.minute,
                                            );
                                          });
                                        },
                                  activeColor: context.theme.primary,
                                  secondary: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule, color: context.theme.textSecondary),
                                      if (already) const SizedBox(width: 8),
                                      if (already)
                                        Chip(
                                          label: Text(
                                            'Déjà enregistré',
                                            style: TextStyle(
                                              color: context.theme.textPrimary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: context.theme.muted.withValues(alpha:0.2),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    '$depStr → $arrStr',
                                    style: TextStyle(color: context.theme.textPrimary),
                                  ),
                                  subtitle: Text(
                                    '${_formatDayLabel(t.departureTime)} • ${t.direction} • ${t.statusText}',
                                    style: TextStyle(color: context.theme.textSecondary),
                                  ),
                                ),
                                // Afficher les arrêts intermédiaires si le trajet est sélectionné
                                if (isSelected && t.intermediateStops.isNotEmpty) ...[
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Arrêts intermédiaires:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: context.theme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: t.intermediateStops.map((stop) {
                                            final time = stop.departureTime ?? stop.arrivalTime;
                                            final timeStr = time != null ? _formatHHmm(time) : '';
                                            return Chip(
                                              label: Text(
                                                timeStr.isNotEmpty
                                                    ? '${stop.station.name} ($timeStr)'
                                                    : stop.station.name,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: context.theme.textPrimary,
                                                ),
                                              ),
                                              backgroundColor:
                                                  context.theme.primary.withValues(alpha:0.1),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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

            if (_departureStation != null && _arrivalStation != null && _selectedTime != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.theme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.theme.outline),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withValues(alpha:0.3)
                          : Colors.black.withValues(alpha:0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.theme.textPrimary,
                              ),
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
                            avatar: Icon(Icons.access_time,
                                size: 16, color: context.theme.textSecondary),
                            label: Text(
                              _selectedTime!.format(context),
                              style: TextStyle(color: context.theme.textPrimary),
                            ),
                            backgroundColor: context.theme.primary.withValues(alpha:0.1),
                          ),
                          if (_selectedDays.isNotEmpty)
                            Chip(
                              avatar:
                                  Icon(Icons.event, size: 16, color: context.theme.textSecondary),
                              label: Text(
                                _selectedDays.length == domain.DayOfWeek.values.length
                                    ? 'Tous les jours'
                                    : _selectedDays.map((d) => d.displayName).join(', '),
                                style: TextStyle(color: context.theme.textPrimary),
                              ),
                              backgroundColor: context.theme.primary.withValues(alpha:0.1),
                            ),
                          Chip(
                            avatar: Icon(Icons.directions_railway,
                                size: 16, color: context.theme.textSecondary),
                            label: Text(
                              _directTrainsOnly ? 'Direct uniquement' : 'Avec correspondances',
                              style: TextStyle(color: context.theme.textPrimary),
                            ),
                            backgroundColor: context.theme.primary.withValues(alpha:0.1),
                          ),
                          Chip(
                            avatar: Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: _notificationsEnabled
                                  ? context.theme.warning
                                  : context.theme.textSecondary,
                            ),
                            label: Text(
                              _notificationsEnabled ? 'Notifications ON' : 'Notifications OFF',
                              style: TextStyle(color: context.theme.textPrimary),
                            ),
                            backgroundColor: _notificationsEnabled
                                ? context.theme.warning.withValues(alpha:0.1)
                                : context.theme.primary.withValues(alpha:0.1),
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
    if (_departureStation != null &&
        _arrivalStation != null &&
        _selectedTime != null &&
        _selectedDays.isNotEmpty) {
      _loadCandidateTrains();
    }
  }

  Future<void> _selectStation(bool isDeparture) async {
    final result = await Navigator.push<Station>(
      context,
      MaterialPageRoute(
        builder: (context) => StationSearchPage(
          departureStation: isDeparture ? null : _departureStation,
          showFavoriteButton: false,
          onStationTap: (station) => Navigator.pop(context, station),
        ),
      ),
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        if (isDeparture) {
          _departureStation = result;
        } else {
          _arrivalStation = result;
        }
      });
    }
  }

  Future<void> _validateConnection() async {
    if (_departureStation == null || _arrivalStation == null) return;

    // Vérifier que les stations ne sont pas temporaires
    if (_departureStation!.id.startsWith('TEMP_') || _arrivalStation!.id.startsWith('TEMP_')) {
      setState(() {
        _connectionError = '⚠️ Station(s) invalide(s). Veuillez re-sélectionner les stations.';
      });
      return;
    }

    try {
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
    } on Object catch (e) {
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
      if (!mounted) return;
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

    int bestDelta = 8; // plus que max 7
    for (final d in _selectedDays) {
      final targetWeekday = d.index + 1; // 1=Lundi ... 7=Dimanche
      int delta = (targetWeekday - baseToday.weekday) % 7;
      if (delta == 0 && baseToday.isBefore(now)) {
        delta = 7;
      }
      if (delta < bestDelta) bestDelta = delta;
    }

    return baseToday.add(Duration(days: bestDelta % 7));
  }

  String _formatDayLabel(DateTime dt) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final name = names[(dt.weekday - 1).clamp(0, 6)];
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$name $dd/$mm';
  }

  String _formatHHmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _candidateKey(domain_train.Train t) {
    return '${t.id}_${t.departureTime.millisecondsSinceEpoch}';
  }

  Future<void> _loadExistingTrips() async {
    final trips = await DependencyInjection.instance.tripService.getAllTrips();
    if (!mounted) return;
    setState(() => _existingTrips = trips);
  }

  bool _isAlreadySavedTrain(domain_train.Train t) {
    if (_departureStation == null || _arrivalStation == null) return false;
    return _existingTrips.any((trip) {
      final sameStations = trip.departureStation.id == _departureStation!.id &&
          trip.arrivalStation.id == _arrivalStation!.id;
      if (!sameStations) return false;
      final sameTime =
          trip.time.hour == t.departureTime.hour && trip.time.minute == t.departureTime.minute;
      if (!sameTime) return false;
      if (_selectedDays.isNotEmpty) {
        final d = _selectedDays.first;
        if (trip.day != d) return false;
      }
      return true;
    });
  }

  List<domain_train.Train> _deduplicateTrains(List<domain_train.Train> trains) {
    final seen = <String>{};
    final result = <domain_train.Train>[];
    for (final t in trains) {
      final key = '${t.id}-${t.departureTime.toIso8601String()}';
      final timeKey = '${t.departureTime.hour}:${t.departureTime.minute}-${t.direction}';
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

    // Vérifier que les stations ne sont pas temporaires
    if (_departureStation!.id.startsWith('TEMP_') || _arrivalStation!.id.startsWith('TEMP_')) {
      setState(() {
        _isLoadingCandidates = false;
        _hasSearchedCandidates = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: Station(s) invalide(s). Veuillez re-sélectionner les stations.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? context.theme.error.withValues(alpha:0.75)
              : context.theme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingCandidates = true;
      _hasSearchedCandidates = true;
    });

    try {
      final service = DependencyInjection.instance.trainService;

      if (_selectedTime != null) {
        final ref = _buildReferenceDateTime();
        List<domain_train.Train> trains;
        if (_timeMode == TimeConstraintMode.departure) {
          trains = await service.findJourneysWithDepartureTime(
              _departureStation!, _arrivalStation!, ref);
        } else {
          trains =
              await service.findJourneysWithArrivalTime(_departureStation!, _arrivalStation!, ref);
        }
        if (_directTrainsOnly) {
          trains = trains.where((t) => t.isDirect).toList();
        }
        var subset = _deduplicateTrains(trains);

        final targetRef = ref;
        DateTime getRefTime(domain_train.Train t) => t.departureTime;

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

        if (before == null) {
          try {
            final byPrev = await service.findJourneyJustBefore(
                _departureStation!, _arrivalStation!, targetRef);
            if (byPrev != null) {
              before = byPrev;
              subset = _deduplicateTrains([...subset, byPrev]);
              subset.sort((a, b) => getRefTime(a).compareTo(getRefTime(b)));
            }
          } on Object catch (_) {}
        }

        if (after == null) {
          try {
            final byNext =
                await service.findJourneyJustAfter(_departureStation!, _arrivalStation!, targetRef);
            if (byNext != null) {
              after = byNext;
              subset = _deduplicateTrains([...subset, byNext]);
              subset.sort((a, b) => getRefTime(a).compareTo(getRefTime(b)));
            }
          } on Object catch (_) {}
        }

        final result = <domain_train.Train>[];

        if (before != null) {
          final ttBefore = getRefTime(before);
          final sameDay = ttBefore.year == targetRef.year &&
              ttBefore.month == targetRef.month &&
              ttBefore.day == targetRef.day;
          final within3h = targetRef.difference(ttBefore) <= const Duration(hours: 3);
          if (sameDay || within3h) {
            result.add(before);
          }
        }
        if (after != null &&
            (before == null || after.id != before.id || getRefTime(after) != getRefTime(before))) {
          result.add(after);
        }

        setState(() {
          _candidateTrains = result;
          final existingIdx = _candidateTrains.indexWhere(_isAlreadySavedTrain);
          if (existingIdx >= 0) {
            _selectedCandidateId = _candidateKey(_candidateTrains[existingIdx]);
          } else if (_selectedTime != null && _candidateTrains.isNotEmpty) {
            final match = _candidateTrains.firstWhere(
              (t) =>
                  t.departureTime.hour == _selectedTime!.hour &&
                  t.departureTime.minute == _selectedTime!.minute,
              orElse: () => _candidateTrains.first,
            );
            _selectedCandidateId = _candidateKey(match);
          }
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _candidateTrains = [];
      });
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la proposition des trains: $e',
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? context.theme.error.withValues(alpha:0.75)
                : context.theme.error,
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
    if (_departureStation == null || _arrivalStation == null || _selectedTime == null) {
      return;
    }

    try {
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
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                ),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? context.theme.warning.withValues(alpha:0.75)
                  : context.theme.warning,
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
        day: _selectedDays.first,
        time: domain.TimeOfDay(
          hour: _selectedTime!.hour,
          minute: _selectedTime!.minute,
        ),
        isActive: _isActive,
        notificationsEnabled: _notificationsEnabled,
        createdAt: DateTime.now(),
      );

      await DependencyInjection.instance.tripService.saveTrip(trip);
      await DependencyInjection.instance.tripReminderService.refreshSchedules();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Trajet enregistré avec succès !',
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? context.theme.success.withValues(alpha:0.75)
                : context.theme.success,
          ),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur lors de l'enregistrement : $e",
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? context.theme.error.withValues(alpha:0.75)
                : context.theme.error,
          ),
        );
      }
    }
  }
}
