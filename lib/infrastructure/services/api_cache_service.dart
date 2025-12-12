import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de cache simple pour les appels API
class ApiCacheService {
  static const String _cachePrefix = 'api_cache_';
  static const String _timestampPrefix = 'api_cache_ts_';

  /// Récupère une valeur du cache si elle n'est pas expirée
  Future<T?> get<T>(String key, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_timestampPrefix$key';
      final cacheKey = '$_cachePrefix$key';

      final timestampStr = prefs.getString(timestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();

      if (now.difference(timestamp) > ttl) {
        // Cache expiré, supprimer
        await prefs.remove(timestampKey);
        await prefs.remove(cacheKey);
        return null;
      }

      final cachedValue = prefs.getString(cacheKey);
      if (cachedValue == null) return null;

      // Décoder selon le type
      if (T == String) {
        return cachedValue as T;
      } else if (T == Map || T == Map<String, dynamic>) {
        return json.decode(cachedValue) as T;
      } else if (T == List || T == List<dynamic>) {
        return json.decode(cachedValue) as T;
      }

      return json.decode(cachedValue) as T?;
    } catch (_) {
      return null;
    }
  }

  /// Met une valeur en cache avec un TTL
  Future<void> set(String key, Object value, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_timestampPrefix$key';
      final cacheKey = '$_cachePrefix$key';

      String valueToStore;
      if (value is String) {
        valueToStore = value;
      } else {
        valueToStore = json.encode(value);
      }

      await prefs.setString(cacheKey, valueToStore);
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
    } catch (_) {
      // Ignorer les erreurs de cache
    }
  }

  /// Supprime une clé du cache
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_timestampPrefix$key');
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  /// Vide tout le cache
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  /// Génère une clé de cache à partir de paramètres
  static String generateKey(String base, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return base;
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final paramsStr = sortedParams.entries.map((e) => '${e.key}:${e.value}').join('&');
    return '$base?$paramsStr';
  }
}
