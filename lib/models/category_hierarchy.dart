import 'package:flutter/material.dart';
import '../main.dart' show DealItem;

/// Représente une sous-catégorie avec son libellé, icône, description et mots-clés sémantiques.
class BarakaSubcategory {
  final String label;
  final IconData icon;
  final String description;
  final List<String> keywords;

  const BarakaSubcategory({
    required this.label,
    required this.icon,
    required this.description,
    required this.keywords,
  });
}

/// Représente une grande catégorie regroupant ses sous-catégories.
class BarakaCategory {
  final String label;
  final IconData icon;
  final List<BarakaSubcategory> subcategories;

  const BarakaCategory({
    required this.label,
    required this.icon,
    required this.subcategories,
  });
}

/// Référentiel centralisé des catégories et sous-catégories de Baraka.
class BarakaCategoryHierarchy {
  static const List<BarakaCategory> allCategories = [
    BarakaCategory(
      label: 'Restauration & Cafés',
      icon: Icons.restaurant_rounded,
      subcategories: [
        BarakaSubcategory(
          label: 'Restaurants & Tables',
          icon: Icons.table_restaurant_rounded,
          description:
              'cuisine marocaine, internationale, poisson/fruits de mer, tables gastronomiques',
          keywords: [
            'restaurant',
            'restaurants',
            'table',
            'tables',
            'cuisine marocaine',
            'marocain',
            'marocaine',
            'internationale',
            'poisson',
            'fruits de mer',
            'gastronomique',
            'gastronomie',
            'tajine',
            'couscous',
            'pastilla',
            'tanjiya',
            'tanjia',
            'plat',
            'plats',
            'repas',
            'diner',
            'dejeuner',
            'terrasse',
          ],
        ),
        BarakaSubcategory(
          label: 'Snacks & Street Food',
          icon: Icons.fastfood_rounded,
          description: 'burgers, tacos, pizzas, sandwicheries',
          keywords: [
            'snack',
            'snacks',
            'street food',
            'burger',
            'burgers',
            'tacos',
            'pizza',
            'pizzas',
            'sandwich',
            'sandwicherie',
            'sandwichs',
            'panini',
            'shawarma',
            'chawarma',
            'frites',
            'nuggets',
            'fast food',
          ],
        ),
        BarakaSubcategory(
          label: 'Cafés, Salons de thé & Glaces',
          icon: Icons.local_cafe_rounded,
          description:
              'petits-déjeuners, formules goûter/afterwork, pâtisseries, glaciers',
          keywords: [
            'café',
            'cafe',
            'cafés',
            'coffee',
            'salon de thé',
            'salon de the',
            'thé',
            'the',
            'glace',
            'glaces',
            'glacier',
            'petit-déjeuner',
            'petit dejeuner',
            'breakfast',
            'brunch',
            'goûter',
            'gouter',
            'afterwork',
            'milkshake',
            'smoothie',
            'jus frais',
            'jus',
          ],
        ),
        BarakaSubcategory(
          label: 'Boulangeries & Pâtisseries',
          icon: Icons.bakery_dining_rounded,
          description: 'paniers ou lots anti-gaspi, invendus du jour',
          keywords: [
            'boulangerie',
            'boulangeries',
            'pâtisserie',
            'patisserie',
            'viennoiserie',
            'viennoiseries',
            'pain',
            'pains',
            'baguette',
            'baguettes',
            'croissant',
            'croissants',
            'pain au chocolat',
            'brioche',
            'brioches',
            'gateau',
            'gâteau',
            'lots anti-gaspi',
            'invendus',
            'panier anti-gaspi',
            'bakery',
          ],
        ),
      ],
    ),
    BarakaCategory(
      label: 'Beauté & Bien-être',
      icon: Icons.spa_rounded,
      subcategories: [
        BarakaSubcategory(
          label: 'Hammam & Spa',
          icon: Icons.hot_tub_rounded,
          description:
              'hammam traditionnel ou moderne, gommage, massages, forfaits détente',
          keywords: [
            'hammam',
            'spa',
            'gommage',
            'massage',
            'massages',
            'détente',
            'detente',
            'forfait détente',
            'bains',
            'savon noir',
            'kessa',
            'relaxation',
            'zen',
            'sauna',
            'jacuzzi',
          ],
        ),
        BarakaSubcategory(
          label: 'Coiffure & Barbershop',
          icon: Icons.content_cut_rounded,
          description:
              'coupes hommes/femmes, lissages, brushings, soins barbe',
          keywords: [
            'coiffure',
            'coiffeur',
            'coiffeuse',
            'barber',
            'barbershop',
            'barbier',
            'barbe',
            'coupe homme',
            'coupe femme',
            'lissage',
            'brushing',
            'brushings',
            'soin barbe',
            'cheveux',
            'coloration',
            'mèches',
            'balayage',
          ],
        ),
        BarakaSubcategory(
          label: 'Soins & Esthétique',
          icon: Icons.face_retouching_natural_rounded,
          description:
              'manucure/pédicure, onglerie, soins du visage, épilation',
          keywords: [
            'soin',
            'soins',
            'esthétique',
            'esthetique',
            'manucure',
            'pédicure',
            'pedicure',
            'onglerie',
            'ongles',
            'vernis',
            'soin du visage',
            'visage',
            'épilation',
            'epilation',
            'cire',
            'sourcils',
            'cils',
            'beauté',
          ],
        ),
      ],
    ),
    BarakaCategory(
      label: 'Hébergement & Séjours',
      icon: Icons.hotel_rounded,
      subcategories: [
        BarakaSubcategory(
          label: "Riads & Maisons d'hôtes",
          icon: Icons.villa_rounded,
          description: "nuitées dernière minute, chambres d'hôtes",
          keywords: [
            'riad',
            'riads',
            "maison d'hôte",
            "maisons d'hôtes",
            "chambre d'hôte",
            "chambres d'hôtes",
            'dernière minute',
            'derniere minute',
            'nuitée',
            'nuitee',
            'patio',
            'médina riad',
          ],
        ),
        BarakaSubcategory(
          label: 'Hôtels & Résidences',
          icon: Icons.apartment_rounded,
          description: 'séjours express, boutique-hôtels, appart-hôtels',
          keywords: [
            'hôtel',
            'hotel',
            'hôtels',
            'hotels',
            'résidence',
            'residence',
            'séjour express',
            'sejour express',
            'boutique-hôtel',
            'boutique hotel',
            'appart-hôtel',
            'appart hotel',
            'suite',
            'chambre',
            'chambres',
            'resort',
          ],
        ),
        BarakaSubcategory(
          label: 'Day Pass (Journées détente)',
          icon: Icons.pool_rounded,
          description:
              'accès piscine + transat, déjeuners au bord de l\'eau sans nuitée',
          keywords: [
            'day pass',
            'daypass',
            'journée détente',
            'journee detente',
            'piscine',
            'transat',
            'accès piscine',
            'acces piscine',
            "déjeuner au bord de l'eau",
            'dejeuner piscine',
            'pool day',
            'sans nuitée',
            'sans nuitee',
            'bain de soleil',
          ],
        ),
      ],
    ),
    BarakaCategory(
      label: 'Activités & Loisirs',
      icon: Icons.attractions_rounded,
      subcategories: [
        BarakaSubcategory(
          label: 'Excursions & Plein air',
          icon: Icons.terrain_rounded,
          description:
              'balades en quad/buggy, dromadaire, randonnées, balades en bateau',
          keywords: [
            'excursion',
            'excursions',
            'plein air',
            'quad',
            'buggy',
            'dromadaire',
            'dromadaires',
            'chameau',
            'randonnée',
            'randonnee',
            'balade en bateau',
            'bateau',
            'désert',
            'desert',
            'palmeraie',
            'agafay',
            'ourika',
            'montgolfière',
            'trek',
            'aventure',
          ],
        ),
        BarakaSubcategory(
          label: 'Divertissement indoor',
          icon: Icons.sports_esports_rounded,
          description:
              'escape games, bowling, karting, parcs de jeux pour enfants',
          keywords: [
            'indoor',
            'escape game',
            'escape games',
            'bowling',
            'karting',
            'kart',
            'parc de jeux',
            'jeux enfants',
            'trampoline',
            'laser game',
            'arcade',
            'cinéma',
            'cinema',
            'billard',
            'divertissement',
          ],
        ),
        BarakaSubcategory(
          label: 'Sport & Remise en forme',
          icon: Icons.fitness_center_rounded,
          description:
              'cours collectifs (yoga, pilates, padel), accès ponctuel en salle de sport',
          keywords: [
            'sport',
            'sports',
            'remise en forme',
            'cours collectif',
            'cours collectifs',
            'yoga',
            'pilates',
            'padel',
            'tennis',
            'salle de sport',
            'gym',
            'fitness',
            'musculation',
            'coach',
            'crossfit',
            'natation',
          ],
        ),
      ],
    ),
    BarakaCategory(
      label: 'Mobilité & Transports',
      icon: Icons.directions_car_rounded,
      subcategories: [
        BarakaSubcategory(
          label: 'Location de voitures',
          icon: Icons.car_rental_rounded,
          description: 'citadines, SUV/4x4, berlines, utilitaires',
          keywords: [
            'location de voitures',
            'location de voiture',
            'location voiture',
            'citadine',
            'citadines',
            'suv',
            '4x4',
            'berline',
            'berlines',
            'utilitaire',
            'utilitaires',
            'auto',
            'voiture',
            'rent a car',
          ],
        ),
        BarakaSubcategory(
          label: 'Deux-roues & Mobilité douce',
          icon: Icons.two_wheeler_rounded,
          description: 'scooters, motos, vélos électriques',
          keywords: [
            'deux-roues',
            'deux roues',
            'scooter',
            'scooters',
            'moto',
            'motos',
            'vélo',
            'velo',
            'vélos',
            'velos',
            'vélo électrique',
            'velo electrique',
            'trottinette',
            'mobilité douce',
            'cyclotourisme',
          ],
        ),
        BarakaSubcategory(
          label: 'Chauffeurs & Transferts',
          icon: Icons.airport_shuttle_rounded,
          description: 'navettes aéroport, trajets interurbains privés',
          keywords: [
            'chauffeur',
            'chauffeurs',
            'transfert',
            'transferts',
            'navette',
            'navettes',
            'aéroport',
            'aeroport',
            'navette aéroport',
            'vtc',
            'taxi privé',
            'trajets privés',
            'trajet interurbain',
            'transport touristique',
          ],
        ),
      ],
    ),
    BarakaCategory(
      label: 'Shopping & Services',
      icon: Icons.shopping_bag_rounded,
      subcategories: [
        BarakaSubcategory(
          label: 'Mode & Accessoires',
          icon: Icons.checkroom_rounded,
          description: 'prêt-à-porter, maroquinerie, lunettes/optique',
          keywords: [
            'mode',
            'accessoire',
            'accessoires',
            'prêt-à-porter',
            'pret a porter',
            'maroquinerie',
            'lunettes',
            'optique',
            'vêtement',
            'vetement',
            'vêtements',
            'chaussures',
            'sac',
            'sacs',
            'bijoux',
            'bijou',
            'boutique',
            'caftan',
          ],
        ),
        BarakaSubcategory(
          label: 'Maison & Décoration',
          icon: Icons.chair_rounded,
          description: 'artisanat sélectionné, mobilier, linge de maison',
          keywords: [
            'maison',
            'décoration',
            'decoration',
            'artisanat',
            'mobilier',
            'linge de maison',
            'tapis',
            'poterie',
            'luminaire',
            'luminaires',
            'artisanat marocain',
            'design',
            'vannerie',
            'cuir décor',
          ],
        ),
        BarakaSubcategory(
          label: 'Services du quotidien',
          icon: Icons.home_repair_service_rounded,
          description:
              'lavage auto (détaillant / pressing auto), pressing textile, réparations express',
          keywords: [
            'service',
            'services',
            'services du quotidien',
            'lavage auto',
            'pressing auto',
            'détaillant auto',
            'pressing',
            'pressing textile',
            'blanchisserie',
            'réparation express',
            'reparation express',
            'cordonnerie',
            'retouche',
            'fleuriste',
            'fleur',
            'fleurs',
            'plante',
            'bouquet',
          ],
        ),
      ],
    ),
  ];

  static const Map<String, String> defaultImages = {
    // 1. Restauration & Cafés
    'Restaurants & Tables':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
    'Snacks & Street Food':
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
    'Cafés, Salons de thé & Glaces':
        'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
    'Boulangeries & Pâtisseries':
        'https://images.unsplash.com/photo-1509440159596-0249088772ff',

    // 2. Beauté & Bien-être
    'Hammam & Spa':
        'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
    'Coiffure & Barbershop':
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1',
    'Soins & Esthétique':
        'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881',

    // 3. Hébergement & Séjours
    "Riads & Maisons d'hôtes":
        'https://images.unsplash.com/photo-1590073844006-33379778ae09',
    'Hôtels & Résidences':
        'https://images.unsplash.com/photo-1566073771259-6a8506099945',
    'Day Pass (Journées détente)':
        'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7',

    // 4. Activités & Loisirs
    'Excursions & Plein air':
        'https://images.unsplash.com/photo-1533105079780-92b9be482077',
    'Divertissement indoor':
        'https://images.unsplash.com/photo-1511512578047-dfb367046420',
    'Sport & Remise en forme':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48',

    // 5. Mobilité & Transports
    'Location de voitures':
        'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d',
    'Deux-roues & Mobilité douce':
        'https://images.unsplash.com/photo-1558981806-ec527fa84c39',
    'Chauffeurs & Transferts':
        'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2',

    // 6. Shopping & Services
    'Mode & Accessoires':
        'https://images.unsplash.com/photo-1445205170230-053b83016050',
    'Maison & Décoration':
        'https://images.unsplash.com/photo-1513519245088-0e12902e5a38',
    'Services du quotidien':
        'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f',

    // Parents & Fallbacks
    'Restauration & Cafés':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
    'Beauté & Bien-être':
        'https://images.unsplash.com/photo-1540555700478-4be289fbecef',
    'Hébergement & Séjours':
        'https://images.unsplash.com/photo-1566073771259-6a8506099945',
    'Activités & Loisirs':
        'https://images.unsplash.com/photo-1533105079780-92b9be482077',
    'Mobilité & Transports':
        'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d',
    'Shopping & Services':
        'https://images.unsplash.com/photo-1472851294608-062f824d29cc',
    'Boulangerie':
        'https://images.unsplash.com/photo-1509440159596-0249088772ff',
    'Restaurant':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
    'Épicerie': 'https://images.unsplash.com/photo-1542838132-92c53300491e',
    'Fleuriste': 'https://images.unsplash.com/photo-1526047932273-341f2a7631f9',
  };

  static List<String> getSubcategoriesFor(String categoryLabel) {
    for (final cat in allCategories) {
      if (cat.label == categoryLabel) {
        return cat.subcategories.map((s) => s.label).toList();
      }
    }
    return [];
  }

  static BarakaCategory? getCategory(String categoryLabel) {
    for (final cat in allCategories) {
      if (cat.label == categoryLabel) return cat;
    }
    return null;
  }

  static String? getParentCategoryFor(String subcategoryLabel) {
    for (final cat in allCategories) {
      for (final sub in cat.subcategories) {
        if (sub.label == subcategoryLabel) {
          return cat.label;
        }
      }
    }
    return null;
  }

  static IconData getIcon(String label) {
    final l = label.toLowerCase();
    for (final cat in allCategories) {
      if (cat.label.toLowerCase() == l) {
        return cat.icon;
      }
      for (final sub in cat.subcategories) {
        if (sub.label.toLowerCase() == l) {
          return sub.icon;
        }
      }
    }
    if (l.contains('restau') || l.contains('table')) {
      return Icons.restaurant_rounded;
    }
    if (l.contains('snack') || l.contains('burger') || l.contains('pizza')) {
      return Icons.fastfood_rounded;
    }
    if (l.contains('café') || l.contains('cafe') || l.contains('thé')) {
      return Icons.local_cafe_rounded;
    }
    if (l.contains('boulang') || l.contains('patiss') || l.contains('pain')) {
      return Icons.bakery_dining_rounded;
    }
    if (l.contains('hammam') || l.contains('spa')) {
      return Icons.hot_tub_rounded;
    }
    if (l.contains('coiff') || l.contains('barber')) {
      return Icons.content_cut_rounded;
    }
    if (l.contains('soin') || l.contains('beauté') || l.contains('ongle')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (l.contains('riad')) return Icons.villa_rounded;
    if (l.contains('hotel') || l.contains('hôtel')) return Icons.hotel_rounded;
    if (l.contains('day pass') || l.contains('piscine')) {
      return Icons.pool_rounded;
    }
    if (l.contains('excursion') || l.contains('quad')) {
      return Icons.terrain_rounded;
    }
    if (l.contains('indoor') || l.contains('escape') || l.contains('bowling')) {
      return Icons.sports_esports_rounded;
    }
    if (l.contains('sport') || l.contains('fitness') || l.contains('yoga')) {
      return Icons.fitness_center_rounded;
    }
    if (l.contains('voiture') || l.contains('auto')) {
      return Icons.car_rental_rounded;
    }
    if (l.contains('deux-roues') ||
        l.contains('scooter') ||
        l.contains('moto') ||
        l.contains('vélo')) {
      return Icons.two_wheeler_rounded;
    }
    if (l.contains('chauffeur') || l.contains('navette')) {
      return Icons.airport_shuttle_rounded;
    }
    if (l.contains('mode') || l.contains('accessoire')) {
      return Icons.checkroom_rounded;
    }
    if (l.contains('maison') || l.contains('décor')) {
      return Icons.chair_rounded;
    }
    if (l.contains('service') || l.contains('lavage')) {
      return Icons.home_repair_service_rounded;
    }
    return Icons.storefront_rounded;
  }

  static bool matchesSubcategory(DealItem deal, String subcategoryLabel) {
    if (subcategoryLabel == 'Tous' ||
        subcategoryLabel == 'Toutes' ||
        subcategoryLabel.isEmpty) {
      return true;
    }

    final dealCat = deal.category.toLowerCase();
    final target = subcategoryLabel.toLowerCase();

    if (dealCat.contains(target) || target.contains(dealCat)) {
      return true;
    }

    final text =
        "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();

    for (final cat in allCategories) {
      for (final sub in cat.subcategories) {
        if (sub.label == subcategoryLabel) {
          for (final kw in sub.keywords) {
            if (text.contains(kw.toLowerCase())) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }
}
