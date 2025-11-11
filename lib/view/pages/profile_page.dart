import 'package:flutter/material.dart';

import '../theme/theme_x.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../infrastructure/dependency_injection.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'station_search_page.dart';
import '../widgets/trip_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _tripService = DependencyInjection.instance.tripService;
  final _reminderService = DependencyInjection.instance.tripReminderService;
  final _favoriteService = DependencyInjection.instance.favoriteStationService;
  final _themeService = DependencyInjection.instance.themeService;

  List<domain.Trip> _trips = [];
  List<Station> _favoriteStations = [];
  bool _isLoadingTrips = false;
  bool _isLoadingFavorites = false;
  String? _tripError;
  String? _favoritesError;

  bool _tripsExpanded = true;
  bool _favoritesExpanded = false;
  bool _settingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadTrips(),
      _loadFavorites(),
    ]);
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoadingTrips = true;
      _tripError = null;
    });

    try {
      final trips = await _tripService.getAllTrips();
      setState(() {
        _trips = trips;
      });
    } catch (e) {
      setState(() {
        _tripError = 'Erreur lors du chargement des trajets: $e';
      });
    } finally {
      setState(() {
        _isLoadingTrips = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoadingFavorites = true;
      _favoritesError = null;
    });

    try {
      final favorites = await _favoriteService.getAllFavoriteStations();
      setState(() {
        _favoriteStations = favorites;
      });
    } catch (e) {
      setState(() {
        _favoritesError = 'Erreur lors du chargement des favoris: $e';
      });
    } finally {
      setState(() {
        _isLoadingFavorites = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Profil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.theme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildTripsSection(context),
            const SizedBox(height: 16),
            _buildFavoritesSection(context),
            const SizedBox(height: 16),
            _buildSettingsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    required bool expanded,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          initiallyExpanded: expanded,
          onExpansionChanged: onChanged,
          leading: CircleAvatar(
            backgroundColor: context.theme.primary.withOpacity(0.12),
            child: Icon(icon, color: context.theme.primary),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.theme.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: context.theme.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildTripsSection(BuildContext context) {
    return _buildExpandableSection(
      context: context,
      expanded: _tripsExpanded,
      onChanged: (value) => setState(() => _tripsExpanded = value),
      icon: Icons.route,
      title: 'Mes trajets enregistrés',
      subtitle: 'Activez, modifiez ou supprimez vos trajets favoris ici.',
      child: _buildTripsContent(context),
    );
  }

  Widget _buildTripsContent(BuildContext context) {
    if (_isLoadingTrips) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tripError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tripError!,
            style: TextStyle(color: context.theme.error),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadTrips,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (_trips.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucun trajet enregistré',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos trajets pour les retrouver rapidement.',
            style: TextStyle(color: context.theme.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _navigateToAddTrip(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un trajet'),
          ),
        ],
      );
    }

    return Column(
      children: [
        ..._trips.map(
          (trip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(trip.id),
              direction: DismissDirection.endToStart,
              background: _buildDismissibleBackground(),
              confirmDismiss: (direction) => _confirmTripDeletion(context, trip),
              onDismissed: (_) => _deleteTrip(context, trip),
              child: TripCard(
                trip: trip,
                onAction: (action, t) => _handleTripAction(context, action, t),
                onTap: () => _editTrip(context, trip),
                showStatusIndicator: false,
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _navigateToAddTrip(context),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un trajet'),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    return _buildExpandableSection(
      context: context,
      expanded: _favoritesExpanded,
      onChanged: (value) => setState(() => _favoritesExpanded = value),
      icon: Icons.star,
      title: 'Stations favorites',
      subtitle: 'Enregistrez des gares pour les retrouver facilement.',
      child: _buildFavoritesContent(context),
    );
  }

  Widget _buildFavoritesContent(BuildContext context) {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoritesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _favoritesError!,
            style: TextStyle(color: context.theme.error),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadFavorites,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (_favoriteStations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucune station favorite',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.theme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez la recherche pour ajouter vos gares préférées.',
            style: TextStyle(color: context.theme.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _navigateToSearch(context),
            icon: const Icon(Icons.search),
            label: const Text('Rechercher une station'),
          ),
        ],
      );
    }

    return Column(
      children: [
        ..._favoriteStations.map(
          (station) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: context.theme.primary.withOpacity(0.12),
              child: Icon(Icons.train, color: context.theme.primary),
            ),
            title: Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: station.description != null
                ? Text(
                    station.description!,
                    style: TextStyle(color: context.theme.textSecondary),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeFavorite(context, station),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _navigateToSearch(context),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une station'),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return _buildExpandableSection(
      context: context,
      expanded: _settingsExpanded,
      onChanged: (value) => setState(() => _settingsExpanded = value),
      icon: Icons.palette,
      title: 'Personnalisation',
      child: AnimatedBuilder(
        animation: _themeService,
        builder: (context, child) {
          return SwitchListTile(
            secondary: CircleAvatar(
              backgroundColor: context.theme.primary.withOpacity(0.12),
              child: Icon(
                _themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: context.theme.primary,
              ),
            ),
            title: const Text('Mode sombre'),
            subtitle: Text(
              _themeService.isDarkMode
                  ? 'Désactivez pour passer en mode clair.'
                  : 'Activez pour un thème sombre.',
            ),
            value: _themeService.isDarkMode,
            onChanged: (_) => _themeService.toggleTheme(),
          );
        },
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Supprimer', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Future<void> _navigateToAddTrip(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTripPage(),
      ),
    );
    if (result == true) {
      await _loadTrips();
      await _reminderService.refreshSchedules();
    }
  }

  Future<void> _editTrip(BuildContext context, domain.Trip trip) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTripPage(trip: trip),
      ),
    );
    if (result == true) {
      await _loadTrips();
      await _reminderService.refreshSchedules();
    }
  }

  Future<void> _handleTripAction(
    BuildContext context,
    String action,
    domain.Trip trip,
  ) async {
    switch (action) {
      case 'edit':
        await _editTrip(context, trip);
        break;
      case 'duplicate':
        final duplicatedTrip = trip.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
        );
        await _tripService.saveTrip(duplicatedTrip);
        await _reminderService.refreshSchedules();
        await _loadTrips();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trajet dupliqué')),
          );
        }
        break;
      case 'toggle':
        final updatedTrip = trip.copyWith(isActive: !trip.isActive);
        await _tripService.saveTrip(updatedTrip);
        await _reminderService.refreshSchedules();
        await _loadTrips();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Trajet ${updatedTrip.isActive ? 'activé' : 'désactivé'}',
              ),
            ),
          );
        }
        break;
      case 'delete':
        final confirmed = await _confirmTripDeletion(context, trip);
        if (confirmed == true) {
          await _deleteTrip(context, trip);
        }
        break;
    }
  }

  Future<bool?> _confirmTripDeletion(BuildContext context, domain.Trip trip) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${trip.description} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrip(BuildContext context, domain.Trip trip) async {
    await _tripService.deleteTripAndSimilar(trip);
    await _reminderService.refreshSchedules();
    await _loadTrips();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trajet supprimé')),
      );
    }
  }

  Future<void> _navigateToSearch(BuildContext context) async {
    final result = await Navigator.push<Station>(
      context,
      MaterialPageRoute(
        builder: (_) => const StationSearchPage(),
      ),
    );

    if (result != null) {
      await _loadFavorites();
    }
  }

  Future<void> _removeFavorite(BuildContext context, Station station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer la station'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer ${station.name} de vos favoris ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _favoriteService.removeFavoriteStation(station.id);
        await _loadFavorites();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${station.name} retirée des favoris'),
            ),
          );
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
