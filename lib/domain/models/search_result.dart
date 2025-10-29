/// Modèle représentant un résultat de recherche
class SearchResult<T> {
  final T data;
  final double score;
  final String? highlight;
  final SearchResultType type;
  final Map<String, dynamic>? metadata;

  const SearchResult({
    required this.data,
    required this.score,
    this.highlight,
    required this.type,
    this.metadata,
  });

  /// Crée un résultat exact
  factory SearchResult.exact(T data, {Map<String, dynamic>? metadata}) {
    return SearchResult(
      data: data,
      score: 1.0,
      type: SearchResultType.exact,
      metadata: metadata,
    );
  }

  /// Crée un résultat avec correspondance partielle
  factory SearchResult.partial(T data, double score,
      {String? highlight, Map<String, dynamic>? metadata}) {
    return SearchResult(
      data: data,
      score: score,
      highlight: highlight,
      type: SearchResultType.partial,
      metadata: metadata,
    );
  }

  /// Crée un résultat suggéré
  factory SearchResult.suggestion(T data, {Map<String, dynamic>? metadata}) {
    return SearchResult(
      data: data,
      score: 0.8,
      type: SearchResultType.suggestion,
      metadata: metadata,
    );
  }

  /// Crée un résultat récent
  factory SearchResult.recent(T data, {Map<String, dynamic>? metadata}) {
    return SearchResult(
      data: data,
      score: 0.9,
      type: SearchResultType.recent,
      metadata: metadata,
    );
  }

  /// Crée un résultat favori
  factory SearchResult.favorite(T data, {Map<String, dynamic>? metadata}) {
    return SearchResult(
      data: data,
      score: 1.0,
      type: SearchResultType.favorite,
      metadata: metadata,
    );
  }

  /// Vérifie si le résultat est de haute qualité
  bool get isHighQuality => score >= 0.8;

  /// Vérifie si le résultat est exact
  bool get isExact => type == SearchResultType.exact;

  /// Vérifie si le résultat est une suggestion
  bool get isSuggestion => type == SearchResultType.suggestion;

  @override
  String toString() {
    return 'SearchResult(data: $data, score: $score, type: $type)';
  }
}

/// Types de résultats de recherche
enum SearchResultType {
  exact('Correspondance exacte'),
  partial('Correspondance partielle'),
  suggestion('Suggestion'),
  recent('Récent'),
  favorite('Favori');

  const SearchResultType(this.displayName);
  final String displayName;
}
