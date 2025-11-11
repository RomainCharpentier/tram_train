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
  final Station? departureStation;
  final bool showFavoriteButton;
  final void Function(Station)? onStationTap;

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
    if (widget.departureStation != null) {
      _loadConnectedStations();
    } else {
      _loadFavorites();
    }
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final favorites = await _favoriteStationService.getAllFavoriteStations();
    setState(() {
      _favoriteStatus = {for (final fav in favorites) fav.id: true};
    });
  }

  Future<void> _loadFavorites() async {
    _setLoadingState(true);

    try {
      final favorites = await _favoriteStationService.getAllFavoriteStations();
      _setSearchResults(
        favorites.map((station) => SearchResult.favorite(station)).toList(),
      );
    } catch (e) {
      _setErrorState('Erreur lors du chargement des favoris: $e');
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

    _setLoadingState(true);

    try {
      final destinationNames =
          await ConnectedStationsService.getConnectedDestinationNames(widget.departureStation!);

      final results = destinationNames
          .map((name) => SearchResult.suggestion(Station(id: 'TEMP_${name.hashCode}', name: name),
              metadata: {'connected': true, 'suggestion': true}))
          .toList();

      _setSearchResults(results);
    } catch (e) {
      _setErrorState('Erreur lors du chargement des destinations connectées: $e');
    }
  }

  Future<void> _searchStations([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();

    if (searchQuery.isEmpty) {
      if (widget.departureStation != null) {
        await _loadConnectedStations();
      } else {
        await _loadFavorites();
      }
      return;
    }

    _setLoadingState(true);

    try {
      final results =
          await DependencyInjection.instance.stationSearchService.searchStations(searchQuery);
      _setSearchResults(results);
      _loadFavoriteStatus();
    } catch (e) {
      _setErrorState('Erreur lors de la recherche: $e');
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
      final suggestions =
          await DependencyInjection.instance.stationSearchService.getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {}
  }

  Future<void> _searchByTransportType(TransportType type) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedTransportType = type;
    });

    try {
      final results =
          await DependencyInjection.instance.stationSearchService.searchStationsByType(type);
      _setSearchResults(results);
    } catch (e) {
      _setErrorState('Erreur lors de la recherche par type: $e');
    }
  }

  Future<void> _advancedSearch() async {
    _setLoadingState(true);

    try {
      final results = await DependencyInjection.instance.stationSearchService.advancedSearch(
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        transportType: _selectedTransportType != TransportType.all ? _selectedTransportType : null,
      );
      _setSearchResults(results);
    } catch (e) {
      _setErrorState('Erreur lors de la recherche avancée: $e');
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
          _buildTransportTypeFilters(),
          const SizedBox(height: 12),
          _buildAdvancedSearchButton(),
        ],
      ),
    );
  }

  Widget _buildTransportTypeFilters() {
    return Wrap(
      spacing: 8,
      children: TransportType.values.map((type) {
        return FilterChip(
          label: Text(
            type.displayName,
            style: TextStyle(
              color: _selectedTransportType == type
                  ? context.theme.primary
                  : context.theme.textPrimary,
            ),
          ),
          selected: _selectedTransportType == type,
          onSelected: (selected) {
            if (selected) {
              _searchByTransportType(type);
            }
          },
          selectedColor: context.theme.primary.withOpacity(0.2),
          checkmarkColor: context.theme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _advancedSearch,
        icon: const Icon(Icons.search),
        label: const Text('Recherche avancée'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorState(message: 'Erreur: $_error', onRetry: () => _searchStations());
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (widget.departureStation != null &&
            _searchResults.isNotEmpty &&
            _searchController.text.isEmpty)
          InfoBanner(text: 'Gares connectées à ${widget.departureStation!.name}'),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) => _buildStationCard(_searchResults[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.search,
      title:
          widget.departureStation != null ? 'Aucune gare connectée trouvée' : 'Recherchez une gare',
      subtitle: widget.departureStation != null
          ? 'Aucune gare connectée à ${widget.departureStation!.name}'
          : 'Tapez le nom d\'une gare et cliquez sur "Rechercher"',
    );
  }

  Widget _buildStationCard(SearchResult<Station> result) {
    final station = result.data;
    final isSuggestion = result.metadata?['suggestion'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.outline, width: 1),
      ),
      child: ListTile(
        leading: _buildStationLeading(result, isSuggestion),
        title: Text(
          station.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.theme.textPrimary,
          ),
        ),
        subtitle: _buildStationSubtitle(result, station, isSuggestion),
        trailing: _buildStationTrailing(station),
        onTap: () => _handleStationTap(station, isSuggestion),
      ),
    );
  }

  Widget _buildStationLeading(SearchResult<Station> result, bool isSuggestion) {
    return CircleAvatar(
      backgroundColor: isSuggestion ? context.theme.warning : _getTypeColor(result.type),
      child: Icon(
        isSuggestion ? Icons.lightbulb_outline : _getTypeIcon(result.type),
        color: Colors.white,
      ),
    );
  }

  Widget _buildStationSubtitle(SearchResult<Station> result, Station station, bool isSuggestion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          station.description ?? '',
          style: TextStyle(color: context.theme.textSecondary),
        ),
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
    );
  }

  Widget? _buildStationTrailing(Station station) {
    if (widget.showFavoriteButton && _favoriteStatus[station.id] == true) {
      return Icon(
        Icons.star,
        color:
            Theme.of(context).brightness == Brightness.dark ? Colors.amber.shade300 : Colors.amber,
      );
    }
    return null;
  }

  void _handleStationTap(Station station, bool isSuggestion) {
    if (isSuggestion) {
      _selectSuggestion(station.name);
      return;
    }

    if (station.id.startsWith('TEMP_') || station.id.isEmpty) {
      _handleInvalidStationTap(station);
      return;
    }

    if (widget.onStationTap != null) {
      widget.onStationTap!(station);
    } else if (widget.showFavoriteButton) {
      _toggleFavorite(station);
      _selectStation(station);
    } else {
      _selectStation(station);
    }
  }

  void _handleInvalidStationTap(Station station) {
    if (station.id.startsWith('TEMP_')) {
      _selectSuggestion(station.name);
    } else {
      if (!mounted) return;
      setState(() {
        _error = 'Station invalide: ID vide pour "${station.name}"';
      });
    }
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
    if (station.id.startsWith('TEMP_')) {
      _showSnackBar(
          'Veuillez d\'abord rechercher la station "${station.name}" pour l\'ajouter aux favoris',
          context.theme.warning);
      return;
    }

    final isFavorite = _favoriteStatus[station.id] == true;

    try {
      if (isFavorite) {
        await _removeFavorite(station);
      } else {
        await _addFavorite(station);
      }

      if (!mounted) return;
      setState(() {
        _favoriteStatus[station.id] = !isFavorite;
      });
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', context.theme.error);
    }
  }

  Future<void> _removeFavorite(Station station) async {
    await _favoriteStationService.removeFavoriteStation(station.id);
    if (!mounted) return;
    _showSnackBar('${station.name} retirée des favoris', context.theme.warning);
  }

  Future<void> _addFavorite(Station station) async {
    await _favoriteStationService.addFavoriteStation(station);
    if (!mounted) return;
    _showSnackBar('${station.name} ajoutée aux favoris', context.theme.success);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
        backgroundColor: isDark ? backgroundColor.withOpacity(0.75) : backgroundColor,
      ),
    );
  }

  void _selectStation(Station station) {
    if (station.id.startsWith('TEMP_') || station.id.isEmpty) {
      if (station.id.startsWith('TEMP_')) {
        _selectSuggestion(station.name);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = 'Station invalide: ID vide pour "${station.name}"';
      });
      return;
    }
    Navigator.pop(context, station);
  }

  Future<void> _selectSuggestion(String destinationName) async {
    _setLoadingState(true);

    try {
      final results =
          await DependencyInjection.instance.stationSearchService.searchStations(destinationName);

      if (results.isEmpty) {
        _setErrorState('Aucune gare trouvée pour "$destinationName"');
        return;
      }

      final station = results.first.data;

      if (station.id.startsWith('TEMP_')) {
        _setErrorState(
            'Station invalide trouvée pour "$destinationName". Veuillez rechercher à nouveau.');
        return;
      }

      Navigator.pop(context, station);
    } catch (e) {
      _setErrorState('Erreur lors de la recherche de "$destinationName": $e');
    }
  }

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
      _error = null;
    });
  }

  void _setErrorState(String error) {
    setState(() {
      _error = error;
      _isLoading = false;
    });
  }

  void _setSearchResults(List<SearchResult<Station>> results) {
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showAdvancedFilters) _buildAdvancedFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      title: Text(
        'Recherche de Gares',
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: context.theme.primary,
      foregroundColor:
          Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
      leading: canPop
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color:
                    Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(
            _showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _showAdvancedFilters = !_showAdvancedFilters;
            });
          },
        ),
      ],
    );
  }
}
