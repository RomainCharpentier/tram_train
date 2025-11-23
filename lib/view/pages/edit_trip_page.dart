import 'package:flutter/material.dart' hide TimeOfDay;
import '../theme/theme_x.dart';
import '../theme/page_theme_provider.dart';
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../infrastructure/dependency_injection.dart';
import 'station_search_page.dart';
import '../widgets/page_header.dart';
import '../widgets/glass_container.dart';
import '../widgets/save_button.dart';
import '../utils/app_snackbar.dart';

class EditTripPage extends StatefulWidget {
  final domain.Trip trip;

  const EditTripPage({
    super.key,
    required this.trip,
  });

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  late Station _departureStation;
  late Station _arrivalStation;
  late List<domain.DayOfWeek> _selectedDays;
  late flutter.TimeOfDay _selectedTime;
  late bool _isActive;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _departureStation = widget.trip.departureStation;
    _arrivalStation = widget.trip.arrivalStation;
    _selectedDays = [widget.trip.day];
    _selectedTime = flutter.TimeOfDay(
      hour: widget.trip.time.hour,
      minute: widget.trip.time.minute,
    );
    _isActive = widget.trip.isActive;
    _notificationsEnabled = widget.trip.notificationsEnabled;
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
      setState(() {
        if (isDeparture) {
          _departureStation = result;
        } else {
          _arrivalStation = result;
        }
      });

      if (!isDeparture) {
        _validateConnection();
      }
    }
  }

  Future<void> _validateConnection() async {
    try {
      await ConnectedStationsService.checkConnection(
        _departureStation,
        _arrivalStation,
        directOnly: false,
      );
    } catch (e) {
      // Ignorer les erreurs silencieusement lors du chargement initial
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
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _saveTrip() async {
    try {
      final result = await ConnectedStationsService.checkConnection(
        _departureStation,
        _arrivalStation,
        directOnly: false,
      );

      if (!result.isConnected) {
        if (mounted) {
          AppSnackBar.showWarning(
            context,
            message: '⚠️ ${result.message}',
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      final updatedTrip = widget.trip.copyWith(
        departureStation: _departureStation,
        arrivalStation: _arrivalStation,
        day: _selectedDays.first,
        time: domain.TimeOfDay(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        ),
        isActive: _isActive,
        notificationsEnabled: _notificationsEnabled,
      );

      await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
      await DependencyInjection.instance.tripReminderService.refreshSchedules();

      if (mounted) {
        Navigator.pop(context, true);
        AppSnackBar.showSuccess(
          context,
          message: '✅ Trajet modifié avec succès !',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          message: 'Erreur lors de la modification : $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageColors = PageThemeProvider.of(context);
    final canSave = _selectedDays.isNotEmpty;

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
                title: 'Modifier le trajet',
                subtitle: 'Modifiez les informations de votre trajet',
              ),
              const SizedBox(height: 24),
              _buildDepartureStationCard(),
              const SizedBox(height: 8),
              _buildSwapButton(),
              const SizedBox(height: 8),
              _buildArrivalStationCard(),
              const SizedBox(height: 24),
              _buildDaysSection(),
              const SizedBox(height: 24),
              _buildTimeCard(),
              const SizedBox(height: 24),
              _buildActiveSwitch(),
              _buildNotificationsSwitch(),
              const SizedBox(height: 24),
              SaveButton(
                label: 'Enregistrer les modifications',
                enabled: canSave,
                onPressed: _saveTrip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartureStationCard() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: 0.98,
      child: ListTile(
        leading: Icon(Icons.train, color: context.theme.primary),
        title: Text(
          _departureStation.name,
          style: TextStyle(color: context.theme.textPrimary),
        ),
        subtitle: Text(
          _departureStation.description ?? '',
          style: TextStyle(color: context.theme.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: context.theme.textSecondary),
        onTap: () => _selectStation(true),
      ),
    );
  }

  Widget _buildArrivalStationCard() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: 0.98,
      child: ListTile(
        leading: Icon(Icons.location_on, color: context.theme.secondary),
        title: Text(
          _arrivalStation.name,
          style: TextStyle(color: context.theme.textPrimary),
        ),
        subtitle: Text(
          _arrivalStation.description ?? '',
          style: TextStyle(color: context.theme.textSecondary),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: context.theme.textSecondary),
        onTap: () => _selectStation(false),
      ),
    );
  }

  Widget _buildSwapButton() {
    return Center(
      child: IconButton(
        onPressed: _swapStations,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.swap_vert,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
        tooltip: 'Inverser les stations',
      ),
    );
  }

  Widget _buildDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeCard() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: 0.98,
      child: ListTile(
        leading: Icon(Icons.access_time, color: context.theme.primary),
        title: Text(
          'Départ à ${_selectedTime.format(context)}',
          style: TextStyle(color: context.theme.textPrimary),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: context.theme.textSecondary),
        onTap: _selectTime,
      ),
    );
  }

  Widget _buildActiveSwitch() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: 0.98,
      child: SwitchListTile(
        title: Text(
          'Trajet actif',
          style: TextStyle(color: context.theme.textPrimary),
        ),
        subtitle: Text(
          'Ce trajet sera affiché sur le tableau de bord',
          style: TextStyle(color: context.theme.textSecondary),
        ),
        value: _isActive,
        onChanged: (value) => setState(() => _isActive = value),
        activeThumbColor: context.theme.primary,
      ),
    );
  }

  Widget _buildNotificationsSwitch() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: 0.98,
      child: SwitchListTile(
        title: Text(
          'Notifications activées',
          style: TextStyle(color: context.theme.textPrimary),
        ),
        subtitle: Text(
          'Recevoir des notifications pour ce trajet',
          style: TextStyle(color: context.theme.textSecondary),
        ),
        value: _notificationsEnabled,
        onChanged: (value) => setState(() => _notificationsEnabled = value),
        activeThumbColor: context.theme.primary,
      ),
    );
  }
}
