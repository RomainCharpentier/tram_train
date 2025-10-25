import 'package:flutter/material.dart';
import '../../domain/models/favorite_station.dart';
import '../../domain/models/station.dart';
import '../../dependency_injection.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;

class FavoriteStationsPage extends StatefulWidget {
  const FavoriteStationsPage({super.key});

  @override
  State<FavoriteStationsPage> createState() => _FavoriteStationsPageState();
}

class _FavoriteStationsPageState extends State<FavoriteStationsPage> {
  List<FavoriteStation> _favorites = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await DependencyInjection.instance.favoriteStationService.getAllFavoriteStations();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addFavorite() async {
    final result = await showDialog<FavoriteStation?>(
      context: context,
      builder: (context) => _AddFavoriteDialog(),
    );

    if (result != null) {
      try {
        await DependencyInjection.instance.favoriteStationService.addFavoriteStation(
          station: result.station,
          nickname: result.nickname,
        );
        _loadFavorites();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gare ajoutée aux favorites')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _removeFavorite(FavoriteStation favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer des favorites'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${favorite.displayName}" des favorites ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DependencyInjection.instance.favoriteStationService.removeFavoriteStation(favorite.id);
        _loadFavorites();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gare supprimée des favorites')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _editNickname(FavoriteStation favorite) async {
    final controller = TextEditingController(text: favorite.nickname ?? '');
    
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le surnom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Surnom',
            hintText: 'Ex: Ma gare préférée',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await DependencyInjection.instance.favoriteStationService.updateNickname(
          favorite.id,
          result.isEmpty ? null : result,
        );
        _loadFavorites();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surnom modifié')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gares Favorites'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFavorite,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return custom.CustomErrorWidget(
        message: _error!,
        onRetry: _loadFavorites,
      );
    }

    if (_favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune gare favorite',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Appuyez sur + pour ajouter une gare',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      onReorder: _reorderFavorites,
      itemBuilder: (context, index) {
        final favorite = _favorites[index];
        return _buildFavoriteCard(favorite, index);
      },
    );
  }

  Widget _buildFavoriteCard(FavoriteStation favorite, int index) {
    return Card(
      key: ValueKey(favorite.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(favorite.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(favorite.station.name),
            if (favorite.nickname != null) ...[
              const SizedBox(height: 2),
              Text(
                'Surnom: ${favorite.nickname}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            Text(
              'Ajoutée le ${_formatDate(favorite.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editNickname(favorite),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFavorite(favorite),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reorderFavorites(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _favorites.removeAt(oldIndex);
    _favorites.insert(newIndex, item);

    setState(() {});

    try {
      final favoriteIds = _favorites.map((f) => f.id).toList();
      await DependencyInjection.instance.favoriteStationService.updateSortOrder(favoriteIds);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du réordonnement: $e')),
      );
      _loadFavorites(); // Recharger en cas d'erreur
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddFavoriteDialog extends StatefulWidget {
  @override
  State<_AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

class _AddFavoriteDialogState extends State<_AddFavoriteDialog> {
  final _nicknameController = TextEditingController();
  Station _selectedStation = const Station(
    id: 'SNCF:87590349',
    name: 'Babinière',
    description: 'Gare de Babinière',
  );

  final List<Station> _availableStations = [
    const Station(
      id: 'SNCF:87590349',
      name: 'Babinière',
      description: 'Gare de Babinière',
    ),
    const Station(
      id: 'SNCF:87590350',
      name: 'Nantes',
      description: 'Gare de Nantes',
    ),
    const Station(
      id: 'SNCF:87590351',
      name: 'Chantenay',
      description: 'Gare de Chantenay',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une gare favorite'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Station>(
              value: _selectedStation,
              decoration: const InputDecoration(
                labelText: 'Gare',
                border: OutlineInputBorder(),
              ),
              items: _availableStations.map((station) {
                return DropdownMenuItem(
                  value: station,
                  child: Text(station.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStation = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Surnom (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ex: Ma gare préférée',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous pourrez réorganiser l\'ordre des gares en les glissant-déposant.',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _addFavorite,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _addFavorite() {
    final favorite = FavoriteStation(
      id: FavoriteStation.generateId(),
      station: _selectedStation,
      nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
      sortOrder: 0, // Sera mis à jour par le service
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(favorite);
  }
}
