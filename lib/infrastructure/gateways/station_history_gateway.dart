import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/station_search_service.dart';

/// Gateway pour l'historique des recherches de gares
class StationHistoryGatewayImpl implements StationHistoryGateway {
  static const String _historyKey = 'station_search_history';
  static const int _maxHistorySize = 20;

  @override
  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    List<String> history = [];
    if (historyJson != null) {
      try {
        final decoded = json.decode(historyJson) as List<dynamic>;
        history = decoded.cast<String>();
      } on Object catch (_) {
        // En cas d'erreur de décodage, on repart avec une liste vide
        history = [];
      }
    }

    // Supprimer la requête si elle existe déjà
    history.remove(query);

    // Ajouter la nouvelle requête en première position
    history.insert(0, query);

    // Limiter la taille de l'historique
    if (history.length > _maxHistorySize) {
      history = history.take(_maxHistorySize).toList();
    }

    // Sauvegarder l'historique
    await prefs.setString(_historyKey, json.encode(history));
  }

  @override
  Future<List<String>> getRecentQueries() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null) return [];

    try {
      final decoded = json.decode(historyJson) as List<dynamic>;
      return decoded.cast<String>();
    } on Object catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Récupère les requêtes les plus fréquentes
  Future<List<String>> getMostFrequentQueries() async {
    final queries = await getRecentQueries();
    final frequency = <String, int>{};

    for (final query in queries) {
      frequency[query] = (frequency[query] ?? 0) + 1;
    }

    final sortedEntries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((e) => e.key).toList();
  }

  /// Récupère les suggestions basées sur l'historique
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];

    final queries = await getRecentQueries();
    final suggestions = queries
        .where(
            (query) => query.toLowerCase().contains(partialQuery.toLowerCase()))
        .take(5)
        .toList();

    return suggestions;
  }
}
