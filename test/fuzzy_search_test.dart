import 'package:flutter_test/flutter_test.dart';
import 'package:baraka_app/utils/fuzzy_search.dart';

void main() {
  group('FuzzySearch - Normalisation et tokenisation', () {
    test('Suppression des accents français et arabes translittérés', () {
      expect(FuzzySearch.removeAccents('Guéliz'), 'Gueliz');
      expect(FuzzySearch.removeAccents('Médina'), 'Medina');
      expect(FuzzySearch.removeAccents('Épicerie'), 'Epicerie');
      expect(FuzzySearch.removeAccents('Pâtisserie'), 'Patisserie');
      expect(FuzzySearch.removeAccents('Crème brûlée'), 'Creme brulee');
    });

    test('Normalisation en minuscules et sans ponctuation', () {
      expect(FuzzySearch.normalize('  L\'Épicerie - Bio !  '), 'l epicerie bio');
      expect(FuzzySearch.normalize('Pain & Viennoiserie'), 'pain viennoiserie');
    });

    test('Tokenisation avec exclusion intelligente des petits mots de liaison', () {
      final tokens = FuzzySearch.tokenize('Panier de viennoiseries au chocolat');
      expect(tokens, containsAll(['panier', 'viennoiseries', 'chocolat']));
      expect(tokens, isNot(contains('de')));
      expect(tokens, isNot(contains('au')));
    });

    test('Tokenisation quand la requête ne contient qu un stop word', () {
      final tokens = FuzzySearch.tokenize('de');
      expect(tokens, ['de']);
    });
  });

  group('FuzzySearch - Distance Damerau-Levenshtein', () {
    test('Chaînes identiques = distance 0', () {
      expect(FuzzySearch.damerauLevenshtein('tajine', 'tajine'), 0);
    });

    test('Omission de lettre (1 faute)', () {
      expect(FuzzySearch.damerauLevenshtein('tajin', 'tajine'), 1);
      expect(FuzzySearch.damerauLevenshtein('croisant', 'croissant'), 1);
      expect(FuzzySearch.damerauLevenshtein('boulangrie', 'boulangerie'), 1);
    });

    test('Substitution de lettre (1 ou 2 fautes)', () {
      expect(FuzzySearch.damerauLevenshtein('tagine', 'tajine'), 1);
      expect(FuzzySearch.damerauLevenshtein('guelis', 'gueliz'), 1);
      expect(FuzzySearch.damerauLevenshtein('restorant', 'restaurant'), 2);
    });

    test('Inversion / Transposition de lettres adjacentes', () {
      // Damerau-Levenshtein compte l'inversion comme 1 seule opération
      expect(FuzzySearch.damerauLevenshtein('tajnie', 'tajine'), 1);
      expect(FuzzySearch.damerauLevenshtein('flueriste', 'fleuriste'), 1);
    });
  });

  group('FuzzySearch - Correspondance de mots (wordMatches)', () {
    test('Tolère les fautes d orthographe courantes', () {
      // Croissant
      expect(FuzzySearch.wordMatches('croisant', 'croissant'), isTrue);
      expect(FuzzySearch.wordMatches('croissnt', 'croissant'), isTrue);

      // Tajine
      expect(FuzzySearch.wordMatches('tajin', 'tajine'), isTrue);
      expect(FuzzySearch.wordMatches('tagine', 'tajine'), isTrue);
      expect(FuzzySearch.wordMatches('tajnie', 'tajine'), isTrue);

      // Boulangerie
      expect(FuzzySearch.wordMatches('boulangrie', 'boulangerie'), isTrue);
      expect(FuzzySearch.wordMatches('boulange', 'boulangerie'), isTrue);
      expect(FuzzySearch.wordMatches('boulan', 'boulangerie'), isTrue);

      // Restaurant
      expect(FuzzySearch.wordMatches('restorant', 'restaurant'), isTrue);
      expect(FuzzySearch.wordMatches('resto', 'restaurant'), isTrue);

      // Fleuriste
      expect(FuzzySearch.wordMatches('fleurist', 'fleuriste'), isTrue);
      expect(FuzzySearch.wordMatches('floriste', 'fleuriste'), isTrue);
      expect(FuzzySearch.wordMatches('flueriste', 'fleuriste'), isTrue);

      // Épicerie
      expect(FuzzySearch.wordMatches('episerie', 'epicerie'), isTrue);
      expect(FuzzySearch.wordMatches('epiceri', 'epicerie'), isTrue);

      // Quartiers de Marrakech
      expect(FuzzySearch.wordMatches('guelis', 'gueliz'), isTrue);
      expect(FuzzySearch.wordMatches('mdina', 'medina'), isTrue);
      expect(FuzzySearch.wordMatches('hivernag', 'hivernage'), isTrue);
    });

    test('Ne matche PAS les mots complètement différents (pas de faux positifs)', () {
      expect(FuzzySearch.wordMatches('pizza', 'pain'), isFalse);
      expect(FuzzySearch.wordMatches('avion', 'tajine'), isFalse);
      expect(FuzzySearch.wordMatches('voiture', 'fleuriste'), isFalse);
      expect(FuzzySearch.wordMatches('ordinateur', 'epicerie'), isFalse);
    });
  });

  group('FuzzySearch - Recherche complète sur des bons plans (matchesDeal)', () {
    const dealBakery = {
      'title': 'Panier Viennoiseries & Pains',
      'businessName': 'Boulangerie Paul Guéliz',
      'location': 'Guéliz, Marrakech',
      'category': 'Boulangerie',
    };

    const dealTajine = {
      'title': 'Tajine Poulet Citron Confite',
      'businessName': 'Riad Saveurs Médina',
      'location': 'Médina, Marrakech',
      'category': 'Restaurant',
    };

    const dealBio = {
      'title': 'Panier Fruits et Primeurs Bio',
      'businessName': 'Épicerie Fine Hivernage',
      'location': 'Hivernage, Marrakech',
      'category': 'Épicerie',
    };

    const dealFlowers = {
      'title': 'Bouquet de Roses & Eucalyptus',
      'businessName': 'Fleuriste Majorelle',
      'location': 'Guéliz, Marrakech',
      'category': 'Fleuriste',
    };

    test('Recherche exacte', () {
      expect(
        FuzzySearch.matchesDeal(
          title: dealBakery['title']!,
          businessName: dealBakery['businessName']!,
          location: dealBakery['location']!,
          category: dealBakery['category']!,
          query: 'Paul',
        ),
        isTrue,
      );
    });

    test('Recherche avec faute d orthographe sur le produit (ex: croisant, tajin, frui)', () {
      // "croisant" -> correspond au deal boulangerie (mots-clés de catégorie)
      expect(
        FuzzySearch.matchesDeal(
          title: dealBakery['title']!,
          businessName: dealBakery['businessName']!,
          location: dealBakery['location']!,
          category: dealBakery['category']!,
          query: 'croisant',
        ),
        isTrue,
      );

      // "tagine" -> correspond au tajine
      expect(
        FuzzySearch.matchesDeal(
          title: dealTajine['title']!,
          businessName: dealTajine['businessName']!,
          location: dealTajine['location']!,
          category: dealTajine['category']!,
          query: 'tagine',
        ),
        isTrue,
      );

      // "tajnie" (inversion de lettres)
      expect(
        FuzzySearch.matchesDeal(
          title: dealTajine['title']!,
          businessName: dealTajine['businessName']!,
          location: dealTajine['location']!,
          category: dealTajine['category']!,
          query: 'tajnie',
        ),
        isTrue,
      );

      // "frui bio" (frui sans t)
      expect(
        FuzzySearch.matchesDeal(
          title: dealBio['title']!,
          businessName: dealBio['businessName']!,
          location: dealBio['location']!,
          category: dealBio['category']!,
          query: 'frui bio',
        ),
        isTrue,
      );
    });

    test('Recherche avec faute d orthographe sur le quartier ou commerce', () {
      // "guelis" pour Guéliz
      expect(
        FuzzySearch.matchesDeal(
          title: dealBakery['title']!,
          businessName: dealBakery['businessName']!,
          location: dealBakery['location']!,
          category: dealBakery['category']!,
          query: 'guelis',
        ),
        isTrue,
      );

      // "majorel" pour Fleuriste Majorelle
      expect(
        FuzzySearch.matchesDeal(
          title: dealFlowers['title']!,
          businessName: dealFlowers['businessName']!,
          location: dealFlowers['location']!,
          category: dealFlowers['category']!,
          query: 'majorel',
        ),
        isTrue,
      );

      // "mdina" pour Médina
      expect(
        FuzzySearch.matchesDeal(
          title: dealTajine['title']!,
          businessName: dealTajine['businessName']!,
          location: dealTajine['location']!,
          category: dealTajine['category']!,
          query: 'mdina',
        ),
        isTrue,
      );
    });

    test('Recherche multi-mots avec faute et mot de liaison', () {
      // "panier de croisant"
      expect(
        FuzzySearch.matchesDeal(
          title: dealBakery['title']!,
          businessName: dealBakery['businessName']!,
          location: dealBakery['location']!,
          category: dealBakery['category']!,
          query: 'panier de croisant',
        ),
        isTrue,
      );

      // "tajin au poule"
      expect(
        FuzzySearch.matchesDeal(
          title: dealTajine['title']!,
          businessName: dealTajine['businessName']!,
          location: dealTajine['location']!,
          category: dealTajine['category']!,
          query: 'tajin au poule',
        ),
        isTrue,
      );
    });

    test('Recherche insensible aux accents', () {
      // "gueliz" sans accent pour "Guéliz"
      expect(
        FuzzySearch.matchesDeal(
          title: dealBakery['title']!,
          businessName: dealBakery['businessName']!,
          location: dealBakery['location']!,
          category: dealBakery['category']!,
          query: 'gueliz',
        ),
        isTrue,
      );

      // "epicerie" sans accent pour "Épicerie"
      expect(
        FuzzySearch.matchesDeal(
          title: dealBio['title']!,
          businessName: dealBio['businessName']!,
          location: dealBio['location']!,
          category: dealBio['category']!,
          query: 'epicerie',
        ),
        isTrue,
      );
    });

    test('Requête non concordante retourne false', () {
      expect(
        FuzzySearch.matchesDeal(
          title: dealBakery['title']!,
          businessName: dealBakery['businessName']!,
          location: dealBakery['location']!,
          category: dealBakery['category']!,
          query: 'ordinateur portable',
        ),
        isFalse,
      );
    });
  });
}
