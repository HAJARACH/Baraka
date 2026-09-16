import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  static FavoritesService get instance => _instance;

  FavoritesService._internal();

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final ValueNotifier<Set<String>> favoritesNotifier = ValueNotifier<Set<String>>({});

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Charger les favoris au démarrage si un utilisateur est connecté
    await loadFavorites();

    // Écouter les changements d'état d'authentification
    try {
      _supabase?.auth.onAuthStateChange.listen((data) async {
        await loadFavorites();
      });
    } catch (_) {}
  }

  String? get _currentUserId {
    try {
      return _supabase?.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => _currentUserId != null;

  /// Charger les favoris de l'utilisateur connecté
  Future<Set<String>> loadFavorites() async {
    final userId = _currentUserId;
    if (userId == null) {
      favoritesNotifier.value = {};
      return {};
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'baraka_favorites_$userId';
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> list = jsonDecode(jsonString);
        final set = list.map((e) => e.toString()).toSet();
        favoritesNotifier.value = set;
        return set;
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des favoris : $e");
    }

    favoritesNotifier.value = {};
    return {};
  }

  /// Vérifie si un deal est en favori
  bool isFavorite(String dealId) {
    return favoritesNotifier.value.contains(dealId);
  }

  /// Basculer l'état favori d'un deal (ajoute si absent, supprime si présent)
  /// Retourne true si maintenant favori, false si retiré
  Future<bool> toggleFavorite(String dealId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception("Utilisateur non connecté");
    }

    final currentSet = Set<String>.from(favoritesNotifier.value);
    final isFav = currentSet.contains(dealId);

    if (isFav) {
      currentSet.remove(dealId);
    } else {
      currentSet.add(dealId);
    }

    favoritesNotifier.value = currentSet;

    // Sauvegarder dans SharedPreferences sous la clé de l'utilisateur
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'baraka_favorites_$userId';
      await prefs.setString(key, jsonEncode(currentSet.toList()));
    } catch (e) {
      debugPrint("Erreur de sauvegarde locale des favoris : $e");
    }

    // Tentative de synchronisation Supabase (si table présente, silencieux sinon)
    try {
      if (!isFav) {
        await _supabase?.from('favorites').insert({
          'user_id': userId,
          'deal_id': dealId,
        });
      } else {
        await _supabase
            ?.from('favorites')
            .delete()
            .match({'user_id': userId, 'deal_id': dealId});
      }
    } catch (_) {
      // Ignorer si la table Supabase n'est pas configurée
    }

    return !isFav;
  }

  /// Efface les favoris en mémoire lors de la déconnexion
  void clear() {
    favoritesNotifier.value = {};
  }
}
