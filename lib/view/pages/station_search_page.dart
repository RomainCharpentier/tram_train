import 'package:flutter/material.dart';
import '../theme/theme_x.dart';
import '../../domain/models/station.dart';
import '../../domain/models/search_result.dart';
import '../../domain/services/station_search_service.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../domain/services/favorite_station_service.dart';
import '../../infrastructure/dependency_injection.dart';
import '../widgets/search_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/info_banner.dart';

class StationSearchPage extends StatefulWidget {
  final Station? departureStation; // Gare de départ pour filtrer les gares connectées
  final bool showFavoriteButton; // Afficher le bouton favori
  final void Function(Station)? onStationTap; // Callback personnalisé pour le clic
  
  const StationSearchPage({
    super.key,
    this.departureStation,
    this.showFavoriteButton = true,
    this.onStationTap,
  });

  @override
  State<StationSearchPage> createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<SearchResult<Station>> _searchResults = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _error;
  TransportType _selectedTransportType = TransportType.all;
  bool _showAdvancedFilters = false;
  final FavoriteStationService _favoriteStationService =
      DependencyInjection.instance.favoriteStationService;
  Map<String, bool> _favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    // Charger les gares connectées si une gare de départ est fournie
    if (widget.departureStation != null) {
      _loadConnectedStations();
    } else {
      // Si pas de station de départ, afficher les favoris par défaut
      _loadFavorites();
    }
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final favorites = await _favoriteStationService.getAllFavoriteStations();
    setState(() {
      _favoriteStatus = {
        for (var fav in favorites) fav.id: true
      };
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favorites = await _favoriteStationService.getAllFavoriteStations();
      setState(() {
        // Convertir les favoris en SearchResult pour l'affichage
        _searchResults = favorites.map((station) {
          return SearchResult.favorite(station);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des favoris: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConnectedStations() async {
    if (widget.departureStation == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer les noms des destinations connectées
      final destinationNames = await ConnectedStationsService.getConnectedDestinationNames(widget.departureStation!);
      
      // Créer des résultats de recherche avec des suggestions
      final results = destinationNames.map((name) => 
        SearchResult.suggestion(Station(id: 'TEMP_${name.hashCode}', name: name), metadata: {'connected': true, 'suggestion': true})
      ).toList();
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des destinations connectées: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStations([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();
    
    // Recherche globale dans toute la base SNCF (même avec gare de départ)
    if (searchQuery.isEmpty) {
      // Si pas de recherche, afficher les gares connectées si gare de départ
      if (widget.departureStation != null) {
        await _loadConnectedStations();
      } else {
        // Sinon, afficher les favoris
        await _loadFavorites();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Recherche globale dans toute la base SNCF
      final results = await DependencyInjection.instance.stationSearchService.searchStations(searchQuery);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      // Recharger le statut des favoris après une recherche
      _loadFavoriteStatus();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      final suggestions = await DependencyInjection.instance.stationSearchService.getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      // Ignorer les erreurs de suggestions
    }
  }

  Future<void> _searchByTransportType(TransportType type) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedTransportType = type;
    });

    try {
      final results = await DependencyInjection.instance.stationSearchService.searchStationsByType(type);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche par type: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _advancedSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await DependencyInjection.instance.stationSearchService.advancedSearch(
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        transportType: _selectedTransportType != TransportType.all ? _selectedTransportType : null,
      );
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche avancée: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: 'Rechercher une gare...',
            onChanged: (v) {
              setState(() {});
              _getSuggestions(v);
            },
            onSubmitted: _searchStations,
            onSearchPressed: () => _searchStations(),
          ),
          if (_suggestions.isNotEmpty) _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.theme.outline),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(suggestion),
            onTap: () {
              _searchController.text = suggestion;
              _searchStations(suggestion);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.surface,
        border: Border(
          top: BorderSide(color: context.theme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TransportType.values.map((type) {
              return FilterChip(
                label: Text(type.displayName),
                selected: _selectedTransportType == type,
                onSelected: (selected) {
                  if (selected) {
                    _searchByTransportType(type);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _advancedSearch,
              icon: const Icon(Icons.search),
              label: const Text('Recherche avancée'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ErrorState(message: 'Erreur: $_error', onRetry: () => _searchStations());
    }

        if (_searchResults.isEmpty) {
          return EmptyState(
            icon: Icons.search,
            title: widget.departureStation != null
                ? 'Aucune gare connectée trouvée'
                : 'Recherchez une gare',
            subtitle: widget.departureStation != null
                ? 'Aucune gare connectée à ${widget.departureStation!.name}'
                : 'Tapez le nom d\'une gare et cliquez sur "Rechercher"',
          );
        }

    return Column(
      children: [
        if (widget.departureStation != null && _searchResults.isNotEmpty && _searchController.text.isEmpty)
          InfoBanner(text: 'Gares connectées à ${widget.departureStation!.name}'),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildStationCard(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard(SearchResult<Station> result) {
    final station = result.data;
    final isSuggestion = result.metadata?['suggestion'] == true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuggestion ? context.theme.warning : _getTypeColor(result.type),
          child: Icon(
            isSuggestion ? Icons.lightbulb_outline : _getTypeIcon(result.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          station.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.description ?? ''),
            if (isSuggestion)
              Text(
                'Suggestion - Cliquez pour rechercher cette gare',
                style: TextStyle(color: context.theme.warning, fontStyle: FontStyle.italic),
              ),
            if (result.metadata?['distance'] != null)
              Text(
                'Distance: ${(result.metadata!['distance'] as double).toStringAsFixed(1)} km',
                style: TextStyle(color: context.theme.muted),
              ),
            if (result.highlight != null)
              Text(
                'Correspondance: ${result.highlight}',
                style: TextStyle(color: context.theme.primary),
              ),
          ],
        ),
        trailing: widget.showFavoriteButton && _favoriteStatus[station.id] == true
            ? Icon(
                Icons.star,
                color: Colors.amber,
              )
            : null,
        onTap: () {
          // Toujours valider avant de sélectionner
          if (isSuggestion) {
            _selectSuggestion(station.name);
            return;
          }
          
          // Vérifier que la station n'est pas temporaire ou invalide
          if (station.id.startsWith('TEMP_') || station.id.isEmpty) {
            if (station.id.startsWith('TEMP_')) {
              _selectSuggestion(station.name);
            } else {
              if (!mounted) return;
              setState(() {
                _error = 'Station invalide: ID vide pour "${station.name}"';
              });
            }
            return;
          }
          
          if (widget.onStationTap != null) {
            // Utiliser le callback personnalisé (station déjà validée)
            widget.onStationTap!(station);
          } else if (widget.showFavoriteButton) {
            // Mode favoris par défaut : toggle favori puis sélectionner
            _toggleFavorite(station);
            _selectStation(station);
          } else {
            // Mode sélection trajet : sélectionner uniquement
            _selectStation(station);
          }
        },
      ),
    );
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.exact:
        return context.theme.success;
      case SearchResultType.partial:
        return context.theme.primary;
      case SearchResultType.suggestion:
        return context.theme.warning;
      case SearchResultType.recent:
        return context.theme.tertiary;
      case SearchResultType.favorite:
        return context.theme.secondary;
    }
  }

  IconData _getTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.exact:
        return Icons.check_circle;
      case SearchResultType.partial:
        return Icons.search;
      case SearchResultType.suggestion:
        return Icons.lightbulb;
      case SearchResultType.recent:
        return Icons.history;
      case SearchResultType.favorite:
        return Icons.star;
    }
  }

  Future<void> _toggleFavorite(Station station) async {
    // Ne pas permettre d'ajouter des stations temporaires aux favoris
    if (station.id.startsWith('TEMP_')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez d\'abord rechercher la station "${station.name}" pour l\'ajouter aux favoris'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final isFavorite = _favoriteStatus[station.id] == true;
    
    try {
      if (isFavorite) {
        await _favoriteStationService.removeFavoriteStation(station.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${station.name} retirée des favoris'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _favoriteStationService.addFavoriteStation(station);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${station.name} ajoutée aux favoris'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (!mounted) return;
      setState(() {
        _favoriteStatus[station.id] = !isFavorite;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectStation(Station station) {
    // Vérifier que ce n'est pas une station temporaire (suggestion)
    if (station.id.startsWith('TEMP_') || station.id.isEmpty) {
      // Si c'est une suggestion, rechercher la vraie station
      if (station.id.startsWith('TEMP_')) {
        _selectSuggestion(station.name);
        return;
      }
      // Si ID vide, afficher une erreur
      if (!mounted) return;
      setState(() {
        _error = 'Station invalide: ID vide pour "${station.name}"';
      });
      return;
    }
    Navigator.pop(context, station);
  }
  
  /// Gère la sélection d'une suggestion de destination
  Future<void> _selectSuggestion(String destinationName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Rechercher la vraie station correspondant à cette destination
      final results = await DependencyInjection.instance.stationSearchService.searchStations(destinationName);
      
      if (results.isNotEmpty) {
        // Prendre le premier résultat (le plus pertinent)
        final station = results.first.data;
        
        // Vérifier que la station trouvée n'est pas temporaire
        if (station.id.startsWith('TEMP_')) {
          setState(() {
            _error = 'Station invalide trouvée pour "$destinationName". Veuillez rechercher à nouveau.';
            _isLoading = false;
          });
          return;
        }
        
        Navigator.pop(context, station);
      } else {
        setState(() {
          _error = 'Aucune gare trouvée pour "$destinationName"';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche de "$destinationName": $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de Gares'),
        backgroundColor: context.theme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showAdvancedFilters) _buildAdvancedFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
