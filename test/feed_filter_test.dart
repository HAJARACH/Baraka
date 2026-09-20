import 'dart:math' as math;
import 'package:flutter/material.dart';
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
    case 'Restauration & Cafés':
      return text.contains('restau') ||
          text.contains('café') ||
          text.contains('cafe') ||
          text.contains('food') ||
          text.contains('plat') ||
          text.contains('repas') ||
          text.contains('traiteur') ||
          text.contains('snack') ||
          text.contains('burger') ||
          text.contains('pizza') ||
          text.contains('tajine') ||
          text.contains('couscous') ||
          text.contains('boulang') ||
          text.contains('patiss') ||
          text.contains('pâtiss') ||
          text.contains('pain') ||
          text.contains('croissant') ||
          text.contains('viennoiserie') ||
          text.contains('bakery') ||
          text.contains('brunch') ||
          text.contains('coffee');
    case 'Beauté & Bien-être':
      return text.contains('beauté') ||
          text.contains('beaute') ||
          text.contains('bien-être') ||
          text.contains('bien etre') ||
          text.contains('spa') ||
          text.contains('massage') ||
          text.contains('hammam') ||
          text.contains('coiff') ||
          text.contains('barber') ||
          text.contains('soin') ||
          text.contains('ongle');
    case 'Hébergement & Séjours':
      return text.contains('héberg') ||
          text.contains('heberg') ||
          text.contains('séjour') ||
          text.contains('sejour') ||
          text.contains('hôtel') ||
          text.contains('hotel') ||
          text.contains('riad') ||
          text.contains('villa') ||
          text.contains('resort') ||
          text.contains('chambre') ||
          text.contains('suite') ||
          text.contains('nuit');
    case 'Activités & Loisirs':
      return text.contains('activité') ||
          text.contains('activite') ||
          text.contains('loisir') ||
          text.contains('excursion') ||
          text.contains('quad') ||
          text.contains('buggy') ||
          text.contains('dromadaire') ||
          text.contains('visite') ||
          text.contains('musée') ||
          text.contains('parc') ||
          text.contains('piscine');
    case 'Mobilité & Transports':
      return text.contains('mobilité') ||
          text.contains('mobilite') ||
          text.contains('transport') ||
          text.contains('location') ||
          text.contains('voiture') ||
          text.contains('auto') ||
          text.contains('scooter') ||
          text.contains('moto') ||
          text.contains('vélo') ||
          text.contains('velo') ||
          text.contains('navette') ||
          text.contains('transfert') ||
          text.contains('taxi');
    case 'Shopping & Services':
      return text.contains('shopping') ||
          text.contains('service') ||
          text.contains('fleur') ||
          text.contains('florist') ||
          text.contains('plante') ||
          text.contains('bouquet') ||
          text.contains('boutique') ||
          text.contains('magasin') ||
          text.contains('mode') ||
          text.contains('vêtement') ||
          text.contains('vetement') ||
          text.contains('artisanat') ||
          text.contains('souk') ||
          text.contains('épicer') ||
          text.contains('epicer') ||
          text.contains('supermarch') ||
          text.contains('grocery') ||
          text.contains('primeur');
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

    test('Restauration & Cafés filtre les offres de restauration et boulangerie', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Restauration & Cafés')).toList();
      expect(results.length, 2); // Boulangerie Paul + Restaurant Al Fassia
    });

    test('Shopping & Services filtre les offres de shopping, services, épicerie et fleuriste', () {
      final results = allDeals.where((d) => matchesCategory(d, 'Shopping & Services')).toList();
      expect(results.length, 2); // Épicerie Bio + Fleuriste Jasmin
    });

    test('Beauté & Bien-être filtre les établissements de soins ou spa', () {
      final spaDeal = DealItem(
        id: '5',
        title: 'Hammam & Massage Zen',
        businessName: 'Spa Les Bains d\'Orient',
        originalPrice: 300,
        discountedPrice: 150,
        remainingCount: 2,
        location: 'Médina, Marrakech',
        latitude: 31.625,
        longitude: -7.989,
        imageUrl: '',
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
        category: 'Beauté & Bien-être',
      );
      expect(matchesCategory(spaDeal, 'Beauté & Bien-être'), isTrue);
      expect(matchesCategory(spaDeal, 'Restauration & Cafés'), isFalse);
    });

    test('Hébergement & Séjours filtre les riads et hôtels', () {
      final riadDeal = DealItem(
        id: '6',
        title: 'Nuitée Romantique en Riad',
        businessName: 'Riad Marrakech Charm',
        originalPrice: 1000,
        discountedPrice: 500,
        remainingCount: 1,
        location: 'Médina, Marrakech',
        latitude: 31.625,
        longitude: -7.989,
        imageUrl: '',
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
        category: 'Hébergement & Séjours',
      );
      expect(matchesCategory(riadDeal, 'Hébergement & Séjours'), isTrue);
      expect(matchesCategory(riadDeal, 'Activités & Loisirs'), isFalse);
    });

    test('Activités & Loisirs filtre les excursions et loisirs', () {
      final quadDeal = DealItem(
        id: '7',
        title: 'Excursion Quad dans la Palmeraie',
        businessName: 'Marrakech Aventure Quad',
        originalPrice: 400,
        discountedPrice: 200,
        remainingCount: 4,
        location: 'Palmeraie, Marrakech',
        latitude: 31.650,
        longitude: -7.950,
        imageUrl: '',
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
        category: 'Activités & Loisirs',
      );
      expect(matchesCategory(quadDeal, 'Activités & Loisirs'), isTrue);
      expect(matchesCategory(quadDeal, 'Mobilité & Transports'), isFalse);
    });

    test('Mobilité & Transports filtre la location et transport', () {
      final carDeal = DealItem(
        id: '8',
        title: 'Location Voiture Économique',
        businessName: 'Atlas Auto Location',
        originalPrice: 350,
        discountedPrice: 200,
        remainingCount: 2,
        location: 'Guéliz, Marrakech',
        latitude: 31.634,
        longitude: -8.012,
        imageUrl: '',
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
        category: 'Mobilité & Transports',
      );
      expect(matchesCategory(carDeal, 'Mobilité & Transports'), isTrue);
      expect(matchesCategory(carDeal, 'Restauration & Cafés'), isFalse);
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

  group('Regroupement par établissement', () {
    test('Regroupe plusieurs offres d\'un même établissement', () {
      final deals = [
        DealItem(
          id: '1',
          title: 'Panier Viennoiseries',
          businessName: 'Boulangerie Al Baraka',
          originalPrice: 40,
          discountedPrice: 20,
          remainingCount: 3,
          location: 'Guéliz',
          latitude: 31.63,
          longitude: -8.01,
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          category: 'Boulangerie',
        ),
        DealItem(
          id: '2',
          title: 'Panier Salé',
          businessName: 'Snack Atlas',
          originalPrice: 50,
          discountedPrice: 25,
          remainingCount: 2,
          location: 'Médina',
          latitude: 31.62,
          longitude: -7.99,
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
          category: 'Restaurant',
        ),
        DealItem(
          id: '3',
          title: 'Panier Baguettes',
          businessName: 'Boulangerie Al Baraka',
          originalPrice: 30,
          discountedPrice: 15,
          remainingCount: 4,
          location: 'Guéliz',
          latitude: 31.63,
          longitude: -8.01,
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
          category: 'Boulangerie',
        ),
      ];

      final Map<String, EstablishmentGroup> map = {};
      for (final deal in deals) {
        final key = deal.businessName.trim().toLowerCase();
        if (!map.containsKey(key)) {
          map[key] = EstablishmentGroup(
            businessName: deal.businessName.trim(),
            location: deal.location,
            latitude: deal.latitude,
            longitude: deal.longitude,
            category: deal.category,
            deals: [deal],
          );
        } else {
          map[key]!.deals.add(deal);
        }
      }
      final groups = map.values.toList();

      expect(groups.length, 2);
      expect(groups.first.businessName, 'Boulangerie Al Baraka');
      expect(groups.first.deals.length, 2);
      expect(groups.first.deals[0].title, 'Panier Viennoiseries');
      expect(groups.first.deals[1].title, 'Panier Baguettes');
      expect(groups.first.totalRemaining, 7);

      expect(groups[1].businessName, 'Snack Atlas');
      expect(groups[1].deals.length, 1);
      expect(groups[1].totalRemaining, 2);
    });

    test('Préserve l\'ordre de tri des établissements', () {
      final deals = [
        DealItem(
          id: '1',
          title: 'Fleurs',
          businessName: 'Fleuriste Jasmin',
          originalPrice: 80,
          discountedPrice: 40,
          remainingCount: 1,
          location: 'Hivernage',
          latitude: 31.62,
          longitude: -8.01,
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          category: 'Fleuriste',
        ),
        DealItem(
          id: '2',
          title: 'Pâtisserie',
          businessName: 'Pâtisserie Amandine',
          originalPrice: 60,
          discountedPrice: 30,
          remainingCount: 2,
          location: 'Guéliz',
          latitude: 31.63,
          longitude: -8.01,
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          category: 'Boulangerie',
        ),
        DealItem(
          id: '3',
          title: 'Plantes',
          businessName: 'Fleuriste Jasmin',
          originalPrice: 50,
          discountedPrice: 25,
          remainingCount: 3,
          location: 'Hivernage',
          latitude: 31.62,
          longitude: -8.01,
          imageUrl: '',
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
          category: 'Fleuriste',
        ),
      ];

      final Map<String, EstablishmentGroup> map = {};
      for (final deal in deals) {
        final key = deal.businessName.trim().toLowerCase();
        if (!map.containsKey(key)) {
          map[key] = EstablishmentGroup(
            businessName: deal.businessName.trim(),
            location: deal.location,
            latitude: deal.latitude,
            longitude: deal.longitude,
            category: deal.category,
            deals: [deal],
          );
        } else {
          map[key]!.deals.add(deal);
        }
      }
      final groups = map.values.toList();

      expect(groups.length, 2);
      expect(groups[0].businessName, 'Fleuriste Jasmin');
      expect(groups[1].businessName, 'Pâtisserie Amandine');
    });

    testWidgets('EstablishmentGroupWidget renders pro card with cover image and toggles deals on tap',
        (tester) async {
      final now = DateTime.now();
      final group = EstablishmentGroup(
        businessName: 'Boulangerie Amine',
        location: 'Maârif, Casablanca',
        latitude: 33.5898,
        longitude: -7.6038,
        category: 'Boulangerie',
        deals: [
          DealItem(
            id: 'd1',
            title: 'Panier Croissants',
            businessName: 'Boulangerie Amine',
            originalPrice: 40,
            discountedPrice: 20,
            remainingCount: 2,
            location: 'Maârif, Casablanca',
            latitude: 33.5898,
            longitude: -7.6038,
            imageUrl: '',
            expiresAt: now.add(const Duration(hours: 2)),
            category: 'Boulangerie',
          ),
          DealItem(
            id: 'd2',
            title: 'Baguettes traditionnelles',
            businessName: 'Boulangerie Amine',
            originalPrice: 20,
            discountedPrice: 10,
            remainingCount: 5,
            location: 'Maârif, Casablanca',
            latitude: 33.5898,
            longitude: -7.6038,
            imageUrl: '',
            expiresAt: now.add(const Duration(hours: 3)),
            category: 'Boulangerie',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EstablishmentGroupWidget(
                group: group,
                userLat: 33.5898,
                userLng: -7.6038,
                onSelectDeal: (_) {},
                onBookDeal: (_) {},
                onToggleFavorite: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify business name, category and "Voir les offres (2)" are rendered
      expect(find.text('Boulangerie Amine'), findsAtLeastNWidgets(1));
      expect(find.text('Voir les offres (2)'), findsOneWidget);
      expect(find.text('🔥 2 offres'), findsOneWidget);
      expect(find.text('Dès 10 MAD'), findsOneWidget);

      // Tap on the pro case to open the dedicated offers window
      await tester.tap(find.text('Voir les offres (2)'));
      await tester.pumpAndSettle();

      // Now the dedicated window (EstablishmentDetailScreen) is opened
      expect(find.text('Offres disponibles (2)'), findsOneWidget);
      expect(find.text('Panier Croissants'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Baguettes traditionnelles'),
        200.0,
      );
      expect(find.text('Baguettes traditionnelles'), findsOneWidget);

      // Tap back button to return to feed
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Voir les offres (2)'), findsOneWidget);
    });
  });
}
