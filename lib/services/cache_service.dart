import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Service to manage WebView cache and offline content
class CacheService {
  static const String _lastUrlKey = 'last_url';
  static const String _hasCacheKey = 'has_cache';
  static const String _cachedPagesKey = 'cached_pages';
  static const String _lastCacheTimeKey = 'last_cache_time';
  static const int _maxCachedPages = 50; // Limite pagine in cache

  /// Save the last visited URL
  Future<void> saveLastUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUrlKey, url);
      await prefs.setBool(_hasCacheKey, true);
      await prefs.setInt(_lastCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail if cache save fails
    }
  }

  /// Get the last visited URL
  Future<String?> getLastUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUrlKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if cache exists
  Future<bool> hasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasCacheKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Save a page to cache
  Future<void> cachePage(String url, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ottieni lista pagine cached
      List<Map<String, dynamic>> cachedPages = await getCachedPages();

      // Rimuovi duplicati dello stesso URL
      cachedPages.removeWhere((page) => page['url'] == url);

      // Aggiungi nuova pagina
      cachedPages.insert(0, {
        'url': url,
        'title': title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Mantieni solo le ultime N pagine
      if (cachedPages.length > _maxCachedPages) {
        cachedPages = cachedPages.sublist(0, _maxCachedPages);
      }

      // Salva
      await prefs.setString(_cachedPagesKey, jsonEncode(cachedPages));
    } catch (e) {
      // Silently fail
    }
  }

  /// Get list of cached pages
  Future<List<Map<String, dynamic>>> getCachedPages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cachedPagesKey);

      if (cachedData == null) return [];

      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a specific URL is cached
  Future<bool> isUrlCached(String url) async {
    try {
      final cachedPages = await getCachedPages();
      return cachedPages.any((page) => page['url'] == url);
    } catch (e) {
      return false;
    }
  }

  /// Get cached page info
  Future<Map<String, dynamic>?> getCachedPageInfo(String url) async {
    try {
      final cachedPages = await getCachedPages();
      return cachedPages.firstWhere(
        (page) => page['url'] == url,
        orElse: () => {},
      );
    } catch (e) {
      return null;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPages = await getCachedPages();
      final lastCacheTime = prefs.getInt(_lastCacheTimeKey);

      return {
        'totalPages': cachedPages.length,
        'hasCache': cachedPages.isNotEmpty,
        'lastCacheTime': lastCacheTime != null
            ? DateTime.fromMillisecondsSinceEpoch(lastCacheTime)
            : null,
        'oldestPage': cachedPages.isNotEmpty
            ? DateTime.fromMillisecondsSinceEpoch(cachedPages.last['timestamp'])
            : null,
        'newestPage': cachedPages.isNotEmpty
            ? DateTime.fromMillisecondsSinceEpoch(cachedPages.first['timestamp'])
            : null,
      };
    } catch (e) {
      return {
        'totalPages': 0,
        'hasCache': false,
        'lastCacheTime': null,
        'oldestPage': null,
        'newestPage': null,
      };
    }
  }

  /// Enable WebView caching
  Future<void> enableWebViewCache(WebViewController controller) async {
    try {
      // Il caching della WebView è gestito nativamente dal sistema
      // Questo metodo è un placeholder per future configurazioni

      // Su Android/iOS la WebView cache è automatica quando:
      // 1. Non chiami clearCache()
      // 2. Usi il controller persistente
      // 3. Non usi modalità incognito
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all cache
  Future<void> clearCache(WebViewController controller) async {
    try {
      await controller.clearCache();
      await controller.clearLocalStorage();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUrlKey);
      await prefs.remove(_hasCacheKey);
      await prefs.remove(_cachedPagesKey);
      await prefs.remove(_lastCacheTimeKey);
    } catch (e) {
      // Silently fail if cache clear fails
    }
  }

  /// Clear only SharedPreferences cache (mantiene WebView cache)
  Future<void> clearPreferencesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUrlKey);
      await prefs.remove(_hasCacheKey);
      await prefs.remove(_cachedPagesKey);
      await prefs.remove(_lastCacheTimeKey);
    } catch (e) {
      // Silently fail if cache clear fails
    }
  }

  /// Clear old cached pages (older than N days)
  Future<void> clearOldCache({int daysOld = 7}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPages = await getCachedPages();

      final cutoffTime = DateTime.now()
          .subtract(Duration(days: daysOld))
          .millisecondsSinceEpoch;

      // Mantieni solo pagine recenti
      final recentPages = cachedPages
          .where((page) => page['timestamp'] > cutoffTime)
          .toList();

      await prefs.setString(_cachedPagesKey, jsonEncode(recentPages));

      debugPrint('🧹 Cleared ${cachedPages.length - recentPages.length} old cached pages');
    } catch (e) {
      // Silently fail
    }
  }

  /// Get cache size estimate (in pages)
  Future<int> getCacheSize() async {
    final pages = await getCachedPages();
    return pages.length;
  }

  /// Mark page as favorite (pinned for offline)
  Future<void> markAsFavorite(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorite_pages') ?? [];

      if (!favorites.contains(url)) {
        favorites.add(url);
        await prefs.setStringList('favorite_pages', favorites);
        debugPrint('⭐ Marked as favorite: $url');
      }
    } catch (e) {
      debugPrint('❌ Error marking favorite: $e');
    }
  }

  /// Get favorite pages
  Future<List<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('favorite_pages') ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorite_pages') ?? [];
      favorites.remove(url);
      await prefs.setStringList('favorite_pages', favorites);
      debugPrint('⭐ Removed from favorites: $url');
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
    }
  }
}
