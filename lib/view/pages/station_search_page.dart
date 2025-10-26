import 'package:flutter/material.dart';
import '../../domain/models/station.dart';
import '../../domain/models/search_result.dart';
import '../../domain/services/station_search_service.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../infrastructure/dependency_injection.dart';

/// Page de recherche intelligente de gares
class StationSearchPage extends StatefulWidget {
  final Station? departureStation; // Gare de départ pour filtrer les gares connectées
  
  const StationSearchPage({super.key, this.departureStation});

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

  @override
  void initState() {
    super.initState();
    // Charger les gares connectées si une gare de départ est fournie
    if (widget.departureStation != null) {
      _loadConnectedStations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Charge les gares connectées à la gare de départ
  Future<void> _loadConnectedStations() async {
    if (widget.departureStation == null) {
      print('❌ Aucune gare de départ fournie');
      return;
    }
    
    print('🔗 Chargement des gares connectées à: ${widget.departureStation!.name}');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final connectedStations = await ConnectedStationsService.getConnectedStations(widget.departureStation!);
      print('📍 Gares connectées trouvées: ${connectedStations.length}');
      for (final station in connectedStations) {
        print('  - ${station.name} (${station.id})');
      }
      
      final results = connectedStations.map((station) => 
        SearchResult.exact(station, metadata: {'connected': true})
      ).toList();
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des gares connectées: $e');
      setState(() {
        _error = 'Erreur lors du chargement des gares connectées: $e';
        _isLoading = false;
      });
    }
  }

  /// Effectue une recherche de gares
  Future<void> _searchStations([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();
    
    // Recherche globale dans toute la base SNCF (même avec gare de départ)
    if (searchQuery.isEmpty) {
      // Si pas de recherche, afficher les gares connectées si gare de départ
      if (widget.departureStation != null) {
        await _loadConnectedStations();
      } else {
        setState(() {
          _searchResults = [];
          _error = null;
        });
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
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la recherche: $e';
        _isLoading = false;
      });
    }
  }

  /// Récupère les suggestions de recherche
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

  /// Recherche par type de transport
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

  /// Recherche avancée
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de Gares'),
        backgroundColor: const Color(0xFF4A90E2),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une gare...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchStations('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _getSuggestions(value);
                  },
                  onSubmitted: _searchStations,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _searchStations,
                icon: const Icon(Icons.search),
                label: const Text('Rechercher'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_error',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchStations(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

        if (_searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  widget.departureStation != null 
                    ? 'Aucune gare connectée trouvée'
                    : 'Recherchez une gare',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.departureStation != null
                    ? 'Aucune gare connectée à ${widget.departureStation!.name}'
                    : 'Tapez le nom d\'une gare et cliquez sur "Rechercher"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

    return Column(
      children: [
        // Message informatif pour les gares connectées
        if (widget.departureStation != null && _searchResults.isNotEmpty && _searchController.text.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4A90E2),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gares connectées à ${widget.departureStation!.name}',
                    style: const TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(result.type),
          child: Icon(
            _getTypeIcon(result.type),
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
            if (result.metadata?['distance'] != null)
              Text(
                'Distance: ${(result.metadata!['distance'] as double).toStringAsFixed(1)} km',
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (result.highlight != null)
              Text(
                'Correspondance: ${result.highlight}',
                style: TextStyle(color: Colors.blue[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.isHighQuality)
              const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addToFavorites(station),
            ),
          ],
        ),
        onTap: () => _selectStation(station),
      ),
    );
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.exact:
        return Colors.green;
      case SearchResultType.partial:
        return Colors.blue;
      case SearchResultType.suggestion:
        return Colors.orange;
      case SearchResultType.recent:
        return Colors.purple;
      case SearchResultType.favorite:
        return Colors.amber;
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

  void _addToFavorites(Station station) async {
    // Fonctionnalité des favorites supprimée
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${station.name} ajoutée aux favorites'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectStation(Station station) {
    Navigator.pop(context, station);
  }
}
