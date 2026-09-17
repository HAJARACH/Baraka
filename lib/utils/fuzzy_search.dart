import 'dart:math' as math;

/// Moteur de recherche floue (Fuzzy Search) intelligent pour l'application Baraka.
///
/// Tolère les fautes d'orthographe, fautes de frappe courantes (inversions,
/// omissions, lettres en trop, substitutions), les variations d'accents
/// et les translittérations ou synonymes fréquents au Maroc.
class FuzzySearch {
  // Liste des diacritiques à normaliser
  static const String _withDia =
      'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  static const String _withoutDia =
      'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

  // Mots de liaison / articles en français qu'on peut ignorer dans une recherche multi-mots
  static const Set<String> frenchStopWords = {
    'le',
    'la',
    'les',
    'l',
    'un',
    'une',
    'des',
    'du',
    'de',
    'd',
    'et',
    'au',
    'aux',
    'a',
    'en',
    'pour',
    'par',
    'dans',
    'sur',
    'avec',
  };

  // Synonymes, abréviations et équivalences phonétiques fréquentes
  static const Map<String, List<String>> synonyms = {
    'resto': ['restaurant', 'restauration', 'traiteur', 'snack'],
    'restau': ['restaurant'],
    'blg': ['boulangerie', 'pain', 'viennoiserie'],
    'boulange': ['boulangerie'],
    'patiss': ['patisserie', 'gateau', 'viennoiserie'],
    'patisserie': ['viennoiseries', 'pain', 'boulangerie'],
    'fleurs': ['fleuriste', 'fleur', 'bouquet', 'plante', 'roses'],
    'fleur': ['fleuriste', 'bouquet', 'plante', 'roses'],
    'legume': ['legumes', 'fruits', 'epicerie', 'primeur'],
    'legumes': ['fruits', 'epicerie', 'primeur'],
    'fruit': ['fruits', 'primeurs', 'epicerie'],
    'kech': ['marrakech'],
    'mkech': ['marrakech'],
    'tagine': ['tajine'],
    'tajin': ['tajine'],
    'kouskous': ['couscous'],
    'coscous': ['couscous'],
    'choclat': ['chocolat'],
    'choko': ['chocolat'],
  };

  /// Mots-clés sémantiques par catégorie pour enrichir la recherche
  static const Map<String, List<String>> categoryKeywords = {
    'Boulangerie': [
      'boulangerie',
      'boulangeries',
      'pain',
      'pains',
      'baguette',
      'croissant',
      'croissants',
      'viennoiserie',
      'viennoiseries',
      'patisserie',
      'patisseries',
      'brioche',
      'chocolat',
      'pain au chocolat',
      'chausson',
      'bakery',
      'gateau',
      'chou',
    ],
    'Restaurant': [
      'restaurant',
      'restaurants',
      'resto',
      'plat',
      'plats',
      'repas',
      'tajine',
      'tagine',
      'couscous',
      'poulet',
      'viande',
      'poisson',
      'citron',
      'traiteur',
      'salade',
      'burger',
      'pizza',
      'snack',
      'diner',
      'dejeuner',
      'riad',
      'saveurs',
    ],
    'Épicerie': [
      'epicerie',
      'epiceries',
      'primeur',
      'primeurs',
      'fruits',
      'fruit',
      'legumes',
      'legume',
      'bio',
      'alimentation',
      'supermarche',
      'marche',
      'frais',
      'vrac',
      'panier',
    ],
    'Fleuriste': [
      'fleuriste',
      'fleuristes',
      'fleur',
      'fleurs',
      'bouquet',
      'bouquets',
      'rose',
      'roses',
      'plante',
      'plantes',
      'eucalyptus',
      'floral',
      'fleurir',
    ],
  };

  /// Supprime les accents et diacritiques d'une chaîne
  static String removeAccents(String str) {
    var result = str;
    for (int i = 0; i < _withDia.length; i++) {
      result = result.replaceAll(_withDia[i], _withoutDia[i]);
    }
    return result;
  }

  /// Nettoie et normalise une chaîne (minuscules, sans accents, sans ponctuation inutile)
  static String normalize(String text) {
    final noAcc = removeAccents(text.toLowerCase());
    final cleaned = noAcc.replaceAll(RegExp(r"[^\w\s]"), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Découpe une requête en mots-clés significatifs
  static List<String> tokenize(String query) {
    final norm = normalize(query);
    if (norm.isEmpty) return [];
    final words = norm.split(' ').where((w) => w.isNotEmpty).toList();
    final nonStop = words.where((w) => !frenchStopWords.contains(w)).toList();
    return nonStop.isNotEmpty ? nonStop : words;
  }

  /// Calcule la distance de Damerau-Levenshtein entre deux chaînes :
  /// prend en compte insertions, suppressions, substitutions et
  /// inversions (transpositions de deux caractères adjacents).
  static int damerauLevenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    final d = List.generate(len1 + 1, (_) => List<int>.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;

        int minCost = d[i - 1][j] + 1; // suppression
        final insertCost = d[i][j - 1] + 1; // insertion
        if (insertCost < minCost) minCost = insertCost;

        final subCost = d[i - 1][j - 1] + cost; // substitution
        if (subCost < minCost) minCost = subCost;

        // Transposition de caractères adjacents (ex: "tajnie" -> "tajine")
        if (i > 1 &&
            j > 1 &&
            s1[i - 1] == s2[j - 2] &&
            s1[i - 2] == s2[j - 1]) {
          final transCost = d[i - 2][j - 2] + cost;
          if (transCost < minCost) minCost = transCost;
        }

        d[i][j] = minCost;
      }
    }

    return d[len1][len2];
  }

  /// Nombre maximum de fautes tolérées selon la longueur du mot recherché
  static int maxAllowedDistance(int queryLength) {
    if (queryLength <= 3) return 0; // 1-3 lettres : exact ou préfixe (ex: "bio")
    if (queryLength <= 5) return 1; // 4-5 lettres : max 1 faute (ex: "tajin" -> "tajine", "frui" -> "fruit")
    if (queryLength <= 8) return 2; // 6-8 lettres : max 2 fautes (ex: "croisnt" -> "croissant", "guelis" -> "gueliz")
    return 2; // 9+ lettres : max 2 fautes (ex: "boulangrie" -> "boulangerie", "restorant" -> "restaurant")
  }

  /// Vérifie si un mot recherché correspond à un mot cible avec tolérance aux fautes
  static bool wordMatches(String queryWord, String targetWord) {
    if (queryWord == targetWord) return true;

    // Correspondance par préfixe (ex: "crois" pour "croissant", "boulan" pour "boulangerie")
    if (targetWord.startsWith(queryWord) && queryWord.length >= 3) return true;

    // Correspondance par sous-chaîne directe
    if (targetWord.contains(queryWord) && queryWord.length >= 3) return true;

    final qLen = queryWord.length;
    final tLen = targetWord.length;
    final maxDist = maxAllowedDistance(qLen);

    // Test de distance globale si tailles compatibles
    if (maxDist > 0 && (qLen - tLen).abs() <= maxDist) {
      final dist = damerauLevenshtein(queryWord, targetWord);
      if (dist <= maxDist) {
        // Score de similarité relative pour éviter les faux positifs sur mots courts
        final similarity = 1.0 - (dist / math.max(qLen, tLen));
        if (similarity >= 0.72) return true;
      }
    }

    // Si le mot cible est plus long (ex: mot composé ou pluriel), tester par fenêtre glissante
    if (tLen >= 8 && qLen >= 5 && maxDist > 0) {
      for (int start = 0; start <= tLen - qLen; start++) {
        // Doit commencer par la même lettre pour éviter les faux positifs (ex: ation vs tajin)
        if (targetWord[start] != queryWord[0]) continue;
        final sub = targetWord.substring(start, start + qLen);
        if (damerauLevenshtein(queryWord, sub) <= 1) {
          return true;
        }
      }
    }

    // Vérifier les synonymes / abréviations
    final synList = synonyms[queryWord];
    if (synList != null) {
      for (final syn in synList) {
        if (wordMatches(syn, targetWord)) return true;
      }
    }

    return false;
  }

  /// Vérifie si une requête de recherche correspond à un bon plan (Deal)
  static bool matchesDeal({
    required String title,
    required String businessName,
    required String location,
    required String category,
    required String query,
  }) {
    if (query.trim().isEmpty) return true;

    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return true;

    // Construire le dictionnaire des mots cibles du bon plan
    final targetWords = <String>{};

    void addWords(String text) {
      final norm = normalize(text);
      if (norm.isNotEmpty) {
        targetWords.addAll(norm.split(' ').where((w) => w.isNotEmpty));
      }
    }

    addWords(title);
    addWords(businessName);
    addWords(location);
    addWords(category);

    // Mots-clés sémantiques de la catégorie
    final catKeywords = categoryKeywords[category] ?? [];
    for (final kw in catKeywords) {
      addWords(kw);
    }

    final targetList = targetWords.toList();

    // Chaque mot de la requête doit matcher au moins un mot cible du deal
    for (final qToken in queryTokens) {
      bool tokenMatched = false;

      for (final tWord in targetList) {
        if (wordMatches(qToken, tWord)) {
          tokenMatched = true;
          break;
        }
      }

      if (!tokenMatched) {
        return false;
      }
    }

    return true;
  }

  /// Calcule un score de pertinence pour trier les résultats de recherche
  static double calculateRelevanceScore({
    required String title,
    required String businessName,
    required String location,
    required String category,
    required String query,
  }) {
    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return 0.0;

    final normTitle = normalize(title);
    final normBusiness = normalize(businessName);
    final normLocation = normalize(location);
    final normCategory = normalize(category);
    final fullQuery = normalize(query);

    double score = 0.0;

    // Correspondance exacte sur phrase entière
    if (normTitle.contains(fullQuery)) score += 100;
    if (normBusiness.contains(fullQuery)) score += 80;

    for (final q in queryTokens) {
      // Titre
      if (normTitle.contains(q)) {
        score += 40;
      } else {
        for (final w in normTitle.split(' ')) {
          if (wordMatches(q, w)) {
            score += 25;
            break;
          }
        }
      }

      // Commerce
      if (normBusiness.contains(q)) {
        score += 30;
      } else {
        for (final w in normBusiness.split(' ')) {
          if (wordMatches(q, w)) {
            score += 20;
            break;
          }
        }
      }

      // Catégorie
      if (normCategory.contains(q)) {
        score += 25;
      }

      // Quartier / Localisation
      if (normLocation.contains(q)) {
        score += 15;
      }
    }

    return score;
  }
}
