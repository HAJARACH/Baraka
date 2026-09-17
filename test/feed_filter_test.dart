import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:baraka_app/main.dart';

double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371.0;
  final dLat = (lat2 - lat1) * (math.pi / 180.0);
  final dLon = (lon2 - lon1) * (math.pi / 180.0);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * (math.pi / 180.0)) *
          math.cos(lat2 * (math.pi / 180.0)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)));
}

bool matchesCategory(DealItem deal, String category) {
  if (category == 'Tous') return true;
  final dealCategory = deal.category.toLowerCase();
  final target = category.toLowerCase();
  if (dealCategory.contains(target)) return true;

  final text = "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();

  switch (category) {
    case 'Boulangerie':
      return text.contains('boulang') ||
          text.contains('patiss') ||
          text.contains('pâtiss') ||
          text.contains('pain') ||
          text.contains('croissant') ||
          text.contains('viennoiserie') ||
          text.contains('bakery');
    case 'Restaurant':
      return text.contains('restau') ||
          text.contains('food') ||
          text.contains('plat') ||
          text.contains('repas') ||
          text.contains('traiteur') ||
          text.contains('snack') ||
          text.contains('café') ||
          text.contains('cafe') ||
          text.contains('burger') ||
          text.contains('pizza') ||
          text.contains('tajine') ||
          text.contains('couscous');
    case 'Épicerie':
      return text.contains('épicer') ||
          text.contains('epicer') ||
          text.contains('supermarch') ||
          text.contains('grocery') ||
          text.contains('primeur') ||
          text.contains('fruit') ||
          text.contains('légume') ||
          text.contains('alimentation');
    case 'Fleuriste':
      return text.contains('fleur') ||
          text.contains('florist') ||
          text.contains('plante') ||
          text.contains('bouquet');
    default:
      return dealCategory.contains(target);
  }
}

bool matchesQuartier(DealItem deal, String quartier) {
  if (quartier == 'Tous') return true;
  final q = quartier.toLowerCase();
  final location = deal.location.toLowerCase();
  final business = deal.businessName.toLowerCase();
  final title = deal.title.toLowerCase();
  return location.contains(q) || business.contains(q) || title.contains(q);
}

bool matchesSearch(DealItem deal, String query) {
  return deal.matchesSearch(query);
}

void main() {
  final now = DateTime.now();

  final dealBoulangerieGueliz = DealItem(
    id: '1',
    title: 'Panier Viennoiseries & Pains',
    businessName: 'Boulangerie Paul Guéliz',
    originalPrice: 80,
    discountedPrice: 35,
    remainingCount: 3,
    location: 'Guéliz, Marrakech',
    latitude: 31.6346,
    longitude: -8.0125,
    imageUrl: 'https://example.com/boulangerie.jpg',
    expiresAt: now.add(const Duration(hours: 1)),
    category: 'Boulangerie',
  );

  final dealRestaurantMedina = DealItem(
    id: '2',
    title: 'Tajine Poulet Citron Confite',
    businessName: 'Riad Saveurs Médina',
    originalPrice: 120,
    discountedPrice: 50,
    remainingCount: 2,
    location: 'Médina, Marrakech',
    latitude: 31.6258, // Place Jemaa el-Fna area
    longitude: -7.9891,
    imageUrl: 'https://example.com/tajine.jpg',
    expiresAt: now.add(const Duration(hours: 4)),
    category: 'Restaurant',
  );

  final dealEpicerieHivernage = DealItem(
    id: '3',
    title: 'Panier Fruits et Primeurs Bio',
    businessName: 'Épicerie Fine Hivernage',
    originalPrice: 90,
    discountedPrice: 40,
    remainingCount: 5,
    location: 'Hivernage, Marrakech',
    latitude: 31.6234,
    longitude: -8.0062,
    imageUrl: 'https://example.com/epicerie.jpg',
    expiresAt: now.add(const Duration(hours: 6)),
    category: 'Épicerie',
  );

  final dealFleuristeGueliz = DealItem(
    id: '4',
    title: 'Bouquet de Roses & Eucalyptus',
    businessName: 'Fleuriste Majorelle',
    originalPrice: 150,
    discountedPrice: 60,
    remainingCount: 1,
    location: 'Guéliz, Marrakech',
    latitude: 31.6380,
    longitude: -8.0080,
    imageUrl: 'https://example.com/fleuriste.jpg',
    expiresAt: now.add(const Duration(minutes: 30)),
    category: 'Fleuriste',
  );

  final allDeals = [
    dealBoulangerieGueliz,
    dealRestaurantMedina,
    dealEpicerieHivernage,
    dealFleuristeGueliz,
  ];

  group('Filtrage par catégorie', () {
    test('Tous retourne toutes les offres', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Tous')).toList();
      expect(results.length, 4);
    });

    test('Boulangerie filtre uniquement les boulangeries', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Boulangerie')).toList();
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('Restaurant filtre uniquement les restaurants', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Restaurant')).toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('Épicerie filtre uniquement les épiceries', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Épicerie')).toList();
      expect(results.length, 1);
      expect(results.first.id, '3');
    });

    test('Fleuriste filtre uniquement les fleuristes', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Fleuriste')).toList();
      expect(results.length, 1);
      expect(results.first.id, '4');
    });
  });

  group('Filtrage par quartier de Marrakech', () {
    test('Tous les quartiers retourne toutes les offres', () {
      final results = allDeals.where((d) => matchesQuartier(d, 'Tous')).toList();
      expect(results.length, 4);
    });

    test('Guéliz retourne les 2 offres de Guéliz', () {
      final results = allDeals.where((d) => matchesQuartier(d, 'Guéliz')).toList();
      expect(results.length, 2);
      expect(results.map((d) => d.id), containsAll(['1', '4']));
    });

    test('Médina retourne les offres de la Médina', () {
      final results = allDeals.where((d) => matchesQuartier(d, 'Médina')).toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('Hivernage retourne les offres de l\'Hivernage', () {
      final results = allDeals.where((d) => matchesQuartier(d, 'Hivernage')).toList();
      expect(results.length, 1);
      expect(results.first.id, '3');
    });

    test('Quartier inexistant retourne vide', () {
      final results = allDeals.where((d) => matchesQuartier(d, 'Agdal')).toList();
      expect(results, isEmpty);
    });
  });

  group('Recherche textuelle intelligente et tolérante aux fautes d\'orthographe', () {
    test('Recherche par nom de commerce', () {
      final results = allDeals.where((d) => matchesSearch(d, 'Majorelle')).toList();
      expect(results.length, 1);
      expect(results.first.id, '4');
    });

    test('Recherche par mot du titre (ex: tajine)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'tajine')).toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('Recherche insensible à la casse et espaces', () {
      final results = allDeals.where((d) => matchesSearch(d, '  Viennoiseries  ')).toList();
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('Faute d\'orthographe : omission de lettre (croisant au lieu de croissant)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'croisant')).toList();
      expect(results.length, 1);
      expect(results.first.id, '1'); // Boulangerie Paul
    });

    test('Faute d\'orthographe : omission de lettre (tajin au lieu de tajine)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'tajin')).toList();
      expect(results.length, 1);
      expect(results.first.id, '2'); // Riad Saveurs Médina
    });

    test('Faute de frappe : inversion de lettres / transposition (tajnie au lieu de tajine)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'tajnie')).toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('Faute de frappe : substitution / translittération (tagine pour tajine)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'tagine')).toList();
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('Faute d\'orthographe sur le commerce (majorel pour Majorelle)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'majorel')).toList();
      expect(results.length, 1);
      expect(results.first.id, '4');
    });

    test('Recherche sans accent (gueliz pour Guéliz, medina pour Médina)', () {
      final resultsGueliz = allDeals.where((d) => matchesSearch(d, 'gueliz')).toList();
      expect(resultsGueliz.length, 2); // 1 et 4
      expect(resultsGueliz.map((d) => d.id), containsAll(['1', '4']));

      final resultsMedina = allDeals.where((d) => matchesSearch(d, 'medina')).toList();
      expect(resultsMedina.length, 1);
      expect(resultsMedina.first.id, '2');
    });

    test('Recherche avec faute et mot de liaison (panier de frui)', () {
      final results = allDeals.where((d) => matchesSearch(d, 'panier de frui')).toList();
      expect(results.length, 1);
      expect(results.first.id, '3'); // Épicerie Bio
    });
  });

  group('Tri des offres', () {
    test('Tri par heure d\'expiration (le plus urgent d\'abord)', () {
      final sorted = List<DealItem>.from(allDeals)
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

      // 4 (30 min) < 1 (1 heure) < 2 (4 heures) < 3 (6 heures)
      expect(sorted.first.id, '4'); // Fleuriste expire en 30 min
      expect(sorted[1].id, '1');
      expect(sorted[2].id, '2');
      expect(sorted.last.id, '3');
    });

    test('Tri par distance GPS par rapport à la Médina', () {
      // Position utilisateur : Place Jemaa el-Fna (31.6258, -7.9891)
      const userLat = 31.6258;
      const userLng = -7.9891;

      final sorted = List<DealItem>.from(allDeals)
        ..sort((a, b) {
          final distA = calculateDistanceKm(userLat, userLng, a.latitude, a.longitude);
          final distB = calculateDistanceKm(userLat, userLng, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });

      // Le plus proche de la Médina est le restaurant en Médina (0 km)
      expect(sorted.first.id, '2');
    });
  });

  group('Combinaison de filtres multiples', () {
    test('Filtre Guéliz + Fleuriste', () {
      final results = allDeals.where((d) {
        return matchesQuartier(d, 'Guéliz') && matchesCategory(d, 'Fleuriste');
      }).toList();

      expect(results.length, 1);
      expect(results.first.id, '4');
    });

    test('Filtre Médina + Boulangerie donne vide', () {
      final results = allDeals.where((d) {
        return matchesQuartier(d, 'Médina') && matchesCategory(d, 'Boulangerie');
      }).toList();

      expect(results, isEmpty);
    });
  });
}
