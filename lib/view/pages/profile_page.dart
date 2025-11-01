import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/trip.dart' as domain;
import '../../domain/models/station.dart';
import '../../domain/services/favorite_station_service.dart';
import '../../infrastructure/dependency_injection.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'notification_pause_page.dart';
import 'station_search_page.dart';
import '../widgets/trip_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<domain.Trip> _trips = [];
  bool _isLoading = false;
  String? _error;
  bool _changed = false;
  List<Station> _favoriteStations = [];
  bool _isLoadingFavorites = false;
  final FavoriteStationService _favoriteStationService =
      DependencyInjection.instance.favoriteStationService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTrips();
    _loadFavoriteStations();
  }

  void _onTabChanged() {
    if (_tabController.index == 2 && !_tabController.indexIsChanging) {
      // Recharger les favoris quand on passe sur l'onglet Favoris
      _loadFavoriteStations();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Charge toutes les stations favorites
  Future<void> _loadFavoriteStations() async {
    setState(() {
      _isLoadingFavorites = true;
    });

    try {
      final favorites = await _favoriteStationService.getAllFavoriteStations();
      setState(() {
        _favoriteStations = favorites;
        _isLoadingFavorites = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFavorites = false;
      });
    }
  }

  /// Charge tous les trajets
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
    return _buildScaffold();
  }

  Widget _buildTripsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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

    if (_trips.isEmpty) {
      return _buildEmptyTripsState();
    }

    return _buildTripsList();
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

  Widget _buildTripsList() {
    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return Dismissible(
            key: ValueKey(trip.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: context.theme.error,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (dir) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer le trajet'),
                      content: Text('Supprimer "${trip.description}" ?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Supprimer',
                                style: TextStyle(color: context.theme.error))),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) async {
              await _deleteTrip(trip);
            },
            child: _buildTripCard(trip),
          );
        },
      ),
    );
  }

  Widget _buildTripCard(domain.Trip trip) {
    return TripCard(
      trip: trip,
      onAction: (action, t) => _handleTripAction(action, t),
    );
  }

  void _handleTripAction(String action, domain.Trip trip) async {
    switch (action) {
      case 'edit':
        await _navigateToEditTrip(context, trip);
        break;
      case 'duplicate':
        await _duplicateTrip(trip);
        break;
      case 'toggle':
        await _toggleTrip(trip);
        break;
      case 'delete':
        await _deleteTrip(trip);
        break;
    }
  }

  Future<void> _navigateToEditTrip(
      BuildContext context, domain.Trip trip) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTripPage(trip: trip),
      ),
    );

    if (result == true) {
      _changed = true;
      _loadTrips();
    }
  }

  Future<void> _duplicateTrip(domain.Trip trip) async {
    try {
      final newTrip = trip.copyWith(
        id: domain.Trip.generateId(),
        createdAt: DateTime.now(),
      );

      await DependencyInjection.instance.tripService.saveTrip(newTrip);

      if (mounted) {
        _changed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trajet dupliqué avec succès'),
            backgroundColor: context.theme.success,
          ),
        );
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: context.theme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleTrip(domain.Trip trip) async {
    try {
      final updatedTrip = trip.copyWith(isActive: !trip.isActive);
      await DependencyInjection.instance.tripService.saveTrip(updatedTrip);

      if (mounted) {
        _changed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                updatedTrip.isActive ? 'Trajet activé' : 'Trajet désactivé'),
            backgroundColor: context.theme.success,
          ),
        );
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: context.theme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteTrip(domain.Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer le trajet "${trip.description}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.theme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DependencyInjection.instance.tripService.deleteTripAndSimilar(trip);

        if (mounted) {
          _changed = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trajet supprimé (doublons inclus)'),
              backgroundColor: context.theme.success,
            ),
          );
          _loadTrips();
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

  void _navigateToAddTrip(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTripPage(),
      ),
    );

    if (result == true) {
      _changed = true;
      _loadTrips();
    }
  }

  Widget _buildScaffold() {
    final themeService = DependencyInjection.instance.themeService;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: context.theme.primary,
        actions: [
          AnimatedBuilder(
            animation: themeService,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeService.toggleTheme(),
                tooltip: themeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context, _changed),
            tooltip: 'Fermer',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                await DependencyInjection.instance.tripService.clearAllTrips();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Données trajets réinitialisées'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTrips();
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Réinitialiser les trajets'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Mes Trajets'),
            Tab(icon: Icon(Icons.pause_circle), text: 'Pauses'),
            Tab(icon: Icon(Icons.star), text: 'Favoris'),
          ],
        ),
        ),
        body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripsTab(),
          const NotificationPausePage(),
          _buildFavoritesTab(),
        ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteStations.isEmpty) {
      return _buildEmptyFavoritesState();
    }

    return _buildFavoritesList();
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
            onPressed: () => _navigateToSearch(),
            icon: const Icon(Icons.search),
            label: const Text('Rechercher une station'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Stack(
      children: [
        RefreshIndicator(
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeFavorite(station),
                        tooltip: 'Retirer des favoris',
                      ),
                    ],
                  ),
                  onTap: () => _selectFavoriteStation(station),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _navigateToSearch(),
            child: const Icon(Icons.add),
            tooltip: 'Ajouter une station favorite',
          ),
        ),
      ],
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
      // Recharger les favoris au cas où une nouvelle station a été ajoutée
      _loadFavoriteStations();
    }
  }

  void _selectFavoriteStation(Station station) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (station.description != null) Text(station.description!),
            const SizedBox(height: 16),
            const Text('Que souhaitez-vous faire avec cette station ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'remove'),
            child: Text(
              'Retirer des favoris',
              style: TextStyle(color: context.theme.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (action == 'remove') {
      await _removeFavorite(station);
    }
  }

  Future<void> _removeFavorite(Station station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer des favoris'),
        content: Text('Retirer "${station.name}" des favoris ?'),
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
