import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/train.dart' as domain_train;
import '../../domain/models/station.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../infrastructure/dependency_injection.dart';
import '../../infrastructure/utils/error_message_mapper.dart';
import 'station_search_page.dart';
import '../widgets/switch_card.dart';
import '../widgets/save_button.dart';
import '../widgets/page_header.dart';
import '../theme/theme_x.dart';
import '../theme/page_theme_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_snackbar.dart';
import '../utils/page_transitions.dart';

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
    final pageColors = PageThemeProvider.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              pageColors.primary.withValues(alpha: 0.15),
              context.theme.surface,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              PageHeader(
                title: 'Ajouter un trajet',
                subtitle: 'Créez un nouveau trajet pour suivre vos déplacements',
                showBackButton: true,
              ),
              const SizedBox(height: 24),
              _buildStationSelectionCard(),
              const SizedBox(height: 24),
              _buildDaysSection(),
              const SizedBox(height: 24),
              _buildTimeSection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              const SizedBox(height: 8),
              if (_departureStation != null && _arrivalStation != null && _selectedTime != null)
                _buildSummaryCard(),
              const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildStationSelectionCard() {
    return Container(
      decoration: context.theme.glassStrong,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStationTile(
            isDeparture: true,
            station: _departureStation,
            placeholder: 'Station de départ',
            icon: Icons.train,
            iconColor: context.theme.primary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _swapStations,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.theme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.theme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.swap_vert_rounded,
                        color: context.theme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
          _buildStationTile(
            isDeparture: false,
            station: _arrivalStation,
            placeholder: "Station d'arrivée",
            icon: Icons.location_on,
            iconColor: context.theme.secondary,
          ),
          if (_connectionError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _connectionError!.startsWith('✅')
                    ? context.theme.success.withValues(alpha: 0.1)
                    : context.theme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _connectionError!.startsWith('✅')
                      ? context.theme.success.withValues(alpha: 0.3)
                      : context.theme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _connectionError!.startsWith('✅') ? Icons.check_circle : Icons.warning,
                    color: _connectionError!.startsWith('✅')
                        ? context.theme.success
                        : context.theme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectionError!,
                      style: TextStyle(
                        color: _connectionError!.startsWith('✅')
                            ? context.theme.success
                            : context.theme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStationTile({
    required bool isDeparture,
    required Station? station,
    required String placeholder,
    required IconData icon,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isDeparture && _departureStation == null) {
            AppSnackBar.showWarning(
              context,
              message: "Veuillez d'abord sélectionner la station de départ",
            );
            return;
          }
          _selectStation(isDeparture);
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: iconColor.withValues(alpha: 0.1),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station?.name ?? placeholder,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: station != null ? FontWeight.w600 : FontWeight.w500,
                        color: station != null
                            ? context.theme.textPrimary
                            : context.theme.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (station?.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        station!.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.theme.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Jours de circulation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.theme.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: domain.DayOfWeek.values.map((day) {
            final isSelected = _selectedDays.contains(day);
            return FilterChip(
              label: Text(
                day.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
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
              selectedColor: context.theme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : context.theme.textPrimary,
              ),
              backgroundColor: context.theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : context.theme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Container(
      decoration: context.theme.glassStrong,
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _buildTimeModeButton(
                    'Départ',
                    TimeConstraintMode.departure,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTimeModeButton(
                    'Arrivée',
                    TimeConstraintMode.arrival,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: context.theme.outline.withValues(alpha: 0.2),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        color: context.theme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTime != null
                                ? '${_timeMode == TimeConstraintMode.departure ? "Départ" : "Arrivée"} vers ${_selectedTime!.format(context)}'
                                : "Choisir l'heure",
                            style: TextStyle(
                              fontSize: 16,
                              color: context.theme.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (_selectedTime != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Appuyez pour modifier',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.theme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.theme.textSecondary.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeModeButton(String label, TimeConstraintMode mode) {
    final isSelected = _timeMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _timeMode = mode);
          _maybeAutoSearch();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? context.theme.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: context.theme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? context.theme.primary : context.theme.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        SwitchCard(
          title: 'Trajet actif',
          subtitle: 'Afficher sur le tableau de bord',
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
        ),
        const SizedBox(height: 8),
        SwitchCard(
          title: 'Notifications',
          subtitle: 'Recevoir des alertes trafic',
          value: _notificationsEnabled,
          onChanged: (v) => setState(() => _notificationsEnabled = v),
        ),
        const SizedBox(height: 8),
        SwitchCard(
          title: 'Direct uniquement',
          subtitle: 'Exclure les correspondances',
          value: _directTrainsOnly,
          onChanged: (v) {
            setState(() => _directTrainsOnly = v);
            if (_departureStation != null && _arrivalStation != null) {
              _validateConnection();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final pageColors = PageThemeProvider.of(context);

    final card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pageColors.primary,
            pageColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        boxShadow: DesignTokens.shadowMD,
      ),
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.summarize_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Résumé du trajet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.train_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_departureStation!.name} → ${_arrivalStation!.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedDays.length == 7 ? "Tous les jours" : _selectedDays.map((d) => d.displayName).join(", ")} à ${_selectedTime!.format(context)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return card.animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
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
      PageTransitions.slideRoute(
        StationSearchPage(
          departureStation: isDeparture ? null : _departureStation,
          showFavoriteButton: false,
          onStationTap: (station) => Navigator.pop(context, station),
        ),
        begin: const Offset(0.0, 0.1),
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
        _connectionError = '⚠️ ${ErrorMessageMapper.toUserFriendlyMessage(e)}';
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
      AppSnackBar.showError(
        context,
        message: 'Erreur: Station(s) invalide(s). Veuillez re-sélectionner les stations.',
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
        AppSnackBar.showError(
          context,
          message: 'Erreur lors de la proposition des trains: $e',
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
          AppSnackBar.showWarning(
            context,
            message: '⚠️ ${result.message}',
            duration: const Duration(seconds: 5),
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
        AppSnackBar.showSuccess(
          context,
          message: '✅ Trajet enregistré avec succès !',
        );
      }
    } on Object catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          message: "Erreur lors de l'enregistrement : $e",
        );
      }
    }
  }
}
