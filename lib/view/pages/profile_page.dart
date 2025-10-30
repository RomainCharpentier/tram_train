import 'package:flutter/material.dart';
import '../../domain/models/trip.dart' as domain;
import '../../infrastructure/dependency_injection.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import 'notification_pause_page.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
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
          const Icon(Icons.route, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucun trajet enregistré',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez vos trajets pour les retrouver ici',
            style: TextStyle(color: Colors.grey),
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
              color: Colors.red,
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
                            child: const Text('Supprimer',
                                style: TextStyle(color: Colors.red))),
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
          const SnackBar(
            content: Text('Trajet dupliqué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.green,
          ),
        );
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            const SnackBar(
              content: Text('Trajet supprimé (doublons inclus)'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTrips();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
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
        backgroundColor: const Color(0xFF4A90E2),
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
          ],
        ),
        ),
        body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripsTab(),
          const NotificationPausePage(),
        ],
        ),
      ),
    );
  }
}
