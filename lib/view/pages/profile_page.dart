import 'package:flutter/material.dart';

import '../theme/theme_x.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../domain/services/favorite_station_service.dart';
import '../../infrastructure/dependency_injection.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'notification_pause_page.dart';
import 'notification_test_page.dart';
import 'station_search_page.dart';
import '../widgets/trip_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _open(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DependencyInjection.instance.themeService;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.theme.primary.withOpacity(0.12),
                    child: Icon(Icons.route, color: context.theme.primary),
                  ),
                  title: const Text('Mes trajets enregistrés'),
                  subtitle: const Text(
                      'Modifier, dupliquer ou supprimer vos trajets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const ProfileTripsPage()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.theme.primary.withOpacity(0.12),
                    child:
                        Icon(Icons.pause_circle, color: context.theme.primary),
                  ),
                  title: const Text('Pauses de notifications'),
                  subtitle: const Text('Programmer des périodes sans alertes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const NotificationPausePage()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.theme.primary.withOpacity(0.12),
                    child: Icon(Icons.star, color: context.theme.primary),
                  ),
                  title: const Text('Stations favorites'),
                  subtitle: const Text('Gérer vos gares préférées'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const FavoriteStationsPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.theme.primary.withOpacity(0.12),
                    child: Icon(Icons.notifications_active,
                        color: context.theme.primary),
                  ),
                  title: const Text('Tester les notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const NotificationTestPage()),
                ),
                AnimatedBuilder(
                  animation: themeService,
                  builder: (context, child) {
                    return SwitchListTile(
                      secondary: CircleAvatar(
                        backgroundColor:
                            context.theme.primary.withOpacity(0.12),
                        child: Icon(
                          themeService.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: context.theme.primary,
                        ),
                      ),
                      title: const Text('Mode sombre'),
                      value: themeService.isDarkMode,
                      onChanged: (_) => themeService.toggleTheme(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Raccourcis utiles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.theme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ChipButton(
                icon: Icons.add,
                label: 'Ajouter un trajet',
                onTap: () => _open(context, const AddTripPage()),
              ),
              _ChipButton(
                icon: Icons.search,
                label: 'Rechercher une station',
                onTap: () => _open(context, const StationSearchPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileTripsPage extends StatefulWidget {
  const ProfileTripsPage({super.key});

  @override
  State<ProfileTripsPage> createState() => _ProfileTripsPageState();
}

class _ProfileTripsPageState extends State<ProfileTripsPage> {
  List<domain.Trip> _trips = [];
  bool _isLoading = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trips =
          await DependencyInjection.instance.tripService.getAllTrips();
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des trajets: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: const Text('Mes trajets'),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddTrip(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_trips.isEmpty) {
      return _buildEmptyTripsState();
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return _buildDismissibleTrip(trip);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: context.theme.error),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(fontSize: 16, color: context.theme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTrips,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTripsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route, size: 64, color: context.theme.muted),
          const SizedBox(height: 16),
          Text(
            'Aucun trajet enregistré',
            style: TextStyle(fontSize: 18, color: context.theme.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos trajets pour les retrouver ici',
            style: TextStyle(color: context.theme.muted),
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

  Widget _buildDismissibleTrip(domain.Trip trip) {
    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissibleBackground(),
      confirmDismiss: (dir) => _confirmTripDeletion(trip),
      onDismissed: (_) => _deleteTrip(trip),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: TripCard(
          trip: trip,
          onAction: (action, t) => _handleTripAction(action, t),
          onTap: () => _editTrip(trip),
          showStatusIndicator: false,
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Icon(Icons.delete_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Supprimer', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Future<bool?> _confirmTripDeletion(domain.Trip trip) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer ${trip.description} ?'),
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
  }

  Future<void> _navigateToAddTrip(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTripPage(),
      ),
    );
    if (result == true) {
      await _loadTrips();
      _changed = true;
    }
  }

  void _editTrip(domain.Trip trip) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripPage(trip: trip),
      ),
    );
    if (result == true) {
      await _loadTrips();
      _changed = true;
    }
  }

  void _handleTripAction(String action, domain.Trip trip) async {
    switch (action) {
      case 'edit':
        _editTrip(trip);
        break;
      case 'duplicate':
        final duplicatedTrip = trip.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
        );
        await DependencyInjection.instance.tripService.saveTrip(duplicatedTrip);
        await DependencyInjection.instance.tripReminderService
            .refreshSchedules();
        await _loadTrips();
        _showSnackBar('Trajet dupliqué', context.theme.success);
        _changed = true;
        break;
      case 'toggle':
        final updatedTrip = trip.copyWith(isActive: !trip.isActive);
        await DependencyInjection.instance.tripService.saveTrip(updatedTrip);
        await DependencyInjection.instance.tripReminderService
            .refreshSchedules();
        await _loadTrips();
        _showSnackBar(
          'Trajet ${updatedTrip.isActive ? 'activé' : 'désactivé'}',
          context.theme.success,
        );
        _changed = true;
        break;
      case 'delete':
        final confirmed = await _confirmTripDeletion(trip);
        if (confirmed == true) {
          await _deleteTrip(trip);
        }
        break;
    }
  }

  Future<void> _deleteTrip(domain.Trip trip) async {
    await DependencyInjection.instance.tripService.deleteTripAndSimilar(trip);
    await DependencyInjection.instance.tripReminderService.refreshSchedules();
    await _loadTrips();
    _showSnackBar('Trajet supprimé (doublons inclus)', context.theme.success);
    _changed = true;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

class FavoriteStationsPage extends StatefulWidget {
  const FavoriteStationsPage({super.key});

  @override
  State<FavoriteStationsPage> createState() => _FavoriteStationsPageState();
}

class _FavoriteStationsPageState extends State<FavoriteStationsPage> {
  final FavoriteStationService _favoriteStationService =
      DependencyInjection.instance.favoriteStationService;
  List<Station> _favoriteStations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStations();
  }

  Future<void> _loadFavoriteStations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _favoriteStationService.getAllFavoriteStations();
      setState(() {
        _favoriteStations = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations favorites'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSearch,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter une station favorite',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteStations.isEmpty) {
      return _buildEmptyFavoritesState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteStations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteStations.length,
        itemBuilder: (context, index) {
          final station = _favoriteStations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: context.theme.surface,
                child: Icon(Icons.train, color: context.theme.primary),
              ),
              title: Text(
                station.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: station.description != null
                  ? Text(station.description!)
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeFavorite(station),
                tooltip: 'Retirer des favoris',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyFavoritesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: context.theme.muted),
          const SizedBox(height: 16),
          Text(
            'Aucune station favorite',
            style: TextStyle(fontSize: 18, color: context.theme.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des stations depuis la recherche',
            style: TextStyle(color: context.theme.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToSearch,
            icon: const Icon(Icons.search),
            label: const Text('Rechercher une station'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSearch() async {
    final result = await Navigator.push<Station>(
      context,
      MaterialPageRoute(
        builder: (context) => const StationSearchPage(),
      ),
    );

    if (result != null) {
      _loadFavoriteStations();
    }
  }

  Future<void> _removeFavorite(Station station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer la station'),
        content: Text(
            'Êtes-vous sûr de vouloir retirer ${station.name} de vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _favoriteStationService.removeFavoriteStation(station.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${station.name} retirée des favoris'),
              backgroundColor: context.theme.success,
            ),
          );
          _loadFavoriteStations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: context.theme.error,
            ),
          );
        }
      }
    }
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: context.theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: context.theme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
