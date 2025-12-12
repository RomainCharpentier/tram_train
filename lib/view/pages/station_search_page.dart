import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme_x.dart';
import '../theme/page_theme_provider.dart';
import '../../domain/models/station.dart';
import '../../domain/models/search_result.dart';
import '../../domain/services/station_search_service.dart';
import '../../domain/services/connected_stations_service.dart';
import '../../domain/services/favorite_station_service.dart';
import '../../infrastructure/dependency_injection.dart';
import '../../infrastructure/utils/error_message_mapper.dart';
import '../../infrastructure/services/api_cache_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/info_banner.dart';
import '../widgets/glass_container.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/cache_indicator.dart';
import '../widgets/network_status_indicator.dart';

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
  bool _isFromCache = false;

  Timer? _debounceTimer;

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
      if (!mounted) return;
      _setSearchResults(
        favorites.map((station) => SearchResult.favorite(station)).toList(),
      );
    } on Object catch (e) {
      _setErrorState(ErrorMessageMapper.toUserFriendlyMessage(e));
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
      if (!mounted) return;
      _setSearchResults(results);
    } on Object catch (e) {
      _setErrorState(ErrorMessageMapper.toUserFriendlyMessage(e));
    }
  }

  Future<void> _searchStations([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();

    // Annuler le debounce en cours
    _debounceTimer?.cancel();

    if (searchQuery.isEmpty) {
      setState(() {
        _isFromCache = false;
        _error = null;
      });
      if (widget.departureStation != null) {
        await _loadConnectedStations();
      } else {
        await _loadFavorites();
      }
      return;
    }

    _setLoadingState(true);
    setState(() {
      _isFromCache = false; // Reset cache indicator
    });

    try {
      // Vérifier le cache AVANT la recherche pour l'indicateur visuel
      final cacheService = ApiCacheService();
      final cacheKey = ApiCacheService.generateKey('search_stations', {'query': searchQuery});
      final cached = await cacheService.get<Map<String, dynamic>>(
        cacheKey,
        const Duration(hours: 1),
      );

      // Si cache existe, ne pas afficher le loader
      if (cached != null) {
        setState(() {
          _isFromCache = true;
          _isLoading = false; // Pas de loader si cache
        });
      }

      final results =
          await DependencyInjection.instance.stationSearchService.searchStations(searchQuery);
      if (!mounted) return;

      // Mettre à jour l'indicateur de cache seulement si on avait un cache au début
      if (cached != null) {
        setState(() {
          _isFromCache = true;
        });
      }

      _setSearchResults(results);
      _loadFavoriteStatus();
    } on Object catch (e) {
      _setErrorState(ErrorMessageMapper.toUserFriendlyMessage(e));
    }
  }

  Future<void> _getSuggestions(String query) async {
    _debounceTimer?.cancel();

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions =
            await DependencyInjection.instance.stationSearchService.getSearchSuggestions(query);
        if (!mounted) return;
        setState(() {
          _suggestions = suggestions;
        });
      } on Object catch (_) {}
    });
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
      if (!mounted) return;
      _setSearchResults(results);
    } on Object catch (e) {
      _setErrorState(ErrorMessageMapper.toUserFriendlyMessage(e));
    }
  }

  Future<void> _advancedSearch() async {
    _setLoadingState(true);

    try {
      final results = await DependencyInjection.instance.stationSearchService.advancedSearch(
        query: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        transportType: _selectedTransportType != TransportType.all ? _selectedTransportType : null,
      );
      if (!mounted) return;
      _setSearchResults(results);
    } on Object catch (e) {
      _setErrorState(ErrorMessageMapper.toUserFriendlyMessage(e));
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
              setState(() {
                // Réinitialiser l'indicateur de cache quand on tape
                if (v.isEmpty) {
                  _isFromCache = false;
                }
              });
              _getSuggestions(v);
            },
            onSubmitted: (value) {
              _debounceTimer?.cancel();
              // Forcer la recherche immédiatement
              Future.microtask(() => _searchStations(value));
            },
            onSearchPressed: () {
              _debounceTimer?.cancel();
              _searchStations();
            },
          ),
          if (_suggestions.isNotEmpty) _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return GlassContainer(
      margin: const EdgeInsets.only(top: 8),
      opacity: 0.9,
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
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres avancés',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.theme.textPrimary),
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
              color: _selectedTransportType == type ? Colors.white : context.theme.textPrimary,
            ),
          ),
          selected: _selectedTransportType == type,
          onSelected: (selected) {
            if (selected) {
              _searchByTransportType(type);
            }
          },
          selectedColor: context.theme.primary,
          checkmarkColor: Colors.white,
          backgroundColor: context.theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _selectedTransportType == type ? Colors.transparent : context.theme.outline,
            ),
          ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Afficher skeleton si chargement ET (pas de résultats OU pas de cache)
    if (_isLoading && (!_isFromCache || _searchResults.isEmpty)) {
      return Column(
        children: [
          const NetworkStatusIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: List.generate(
                5,
                (index) => const StationCardSkeleton(),
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const NetworkStatusIndicator(),
          Expanded(
            child: ErrorState(message: _error!, onRetry: () => _searchStations()),
          ),
        ],
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return Column(
        children: [
          const NetworkStatusIndicator(),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    return Column(
      children: [
        const NetworkStatusIndicator(),
        if (_isFromCache && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.theme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.theme.info.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cached,
                  size: 16,
                  color: context.theme.info,
                ),
                const SizedBox(width: 8),
                Text(
                  'Résultats en cache',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
        if (widget.departureStation != null &&
            _searchResults.isNotEmpty &&
            _searchController.text.isEmpty)
          InfoBanner(text: 'Gares connectées à ${widget.departureStation!.name}'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) => _buildStationCard(_searchResults[index])
                .animate()
                .fadeIn(delay: (50 * index).ms)
                .slideY(begin: 0.1, end: 0),
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

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: 0.8,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleStationTap(station, isSuggestion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStationLeading(result, isSuggestion),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStationSubtitle(result, station, isSuggestion),
                    ],
                  ),
                ),
                if (widget.showFavoriteButton) ...[
                  const SizedBox(width: 8),
                  _buildStationTrailing(station) ?? const SizedBox.shrink(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationLeading(SearchResult<Station> result, bool isSuggestion) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSuggestion
            ? context.theme.warning.withValues(alpha: 0.1)
            : _getTypeColor(result.type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSuggestion ? Icons.lightbulb_outline : _getTypeIcon(result.type),
        color: isSuggestion ? context.theme.warning : _getTypeColor(result.type),
        size: 24,
      ),
    );
  }

  Widget _buildStationSubtitle(SearchResult<Station> result, Station station, bool isSuggestion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (station.description != null)
          Text(
            station.description!,
            style: TextStyle(color: context.theme.textSecondary, fontSize: 13),
          ),
        if (isSuggestion)
          Text(
            'Suggestion - Cliquez pour rechercher',
            style:
                TextStyle(color: context.theme.warning, fontStyle: FontStyle.italic, fontSize: 12),
          ),
        if (result.metadata?['distance'] != null)
          Text(
            'Distance: ${(result.metadata!['distance'] as double).toStringAsFixed(1)} km',
            style: TextStyle(color: context.theme.muted, fontSize: 12),
          ),
        if (result.highlight != null)
          Text(
            'Correspondance: ${result.highlight}',
            style: TextStyle(color: context.theme.primary, fontSize: 12),
          ),
      ],
    );
  }

  Widget? _buildStationTrailing(Station station) {
    final isFavorite = _favoriteStatus[station.id] == true;
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.amber.shade300
                : Colors.amber)
            : context.theme.textSecondary,
      ),
      onPressed: () => _toggleFavorite(station),
    );
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
      // If just toggling favorite, do that. But usually tapping selects it.
      // Let's assume tapping selects it, and the star button toggles favorite.
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
    } on Object catch (e) {
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
        backgroundColor: isDark ? backgroundColor.withValues(alpha: 0.75) : backgroundColor,
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

      if (!mounted) return;

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
    } on Object catch (e) {
      _setErrorState(ErrorMessageMapper.toUserFriendlyMessage(e));
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
    final pageColors = PageThemeProvider.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pageColors.primary.withValues(alpha: 0.2),
              context.theme.surface,
              pageColors.accent.withValues(alpha: 0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              if (_showAdvancedFilters) _buildAdvancedFilters(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      title: const Text(
        'Recherche de Gares',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.theme.primary,
              context.theme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
      foregroundColor: Colors.white,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
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
    );
  }
}
