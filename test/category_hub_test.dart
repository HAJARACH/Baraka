import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baraka_app/screens/category_hub_screen.dart';
import 'package:baraka_app/main.dart';

void main() {
  testWidgets('CategoryHubScreen renders title, options and explorer button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryHubScreen(),
      ),
    );

    // Verify Title & Subtitle
    expect(find.text("Que recherchez-vous ?"), findsOneWidget);
    expect(
      find.text(
        "Choisissez votre univers pour découvrir les meilleurs bons plans de Marrakech.",
      ),
      findsOneWidget,
    );

    // Verify Macro Cards
    expect(find.text("Alimentaire & Gastronomie"), findsOneWidget);
    expect(find.text("Services & Commerces"), findsOneWidget);

    // Verify Subcategory Chips
    expect(find.text("Boulangerie"), findsOneWidget);
    expect(find.text("Restaurant"), findsOneWidget);
    expect(find.text("Épicerie"), findsOneWidget);
    expect(find.text("Fleuriste"), findsOneWidget);

    // Verify Explorer Link
    expect(
      find.text("Explorer tous les bons plans sans filtre"),
      findsOneWidget,
    );
  });

  test('Macro category classification logic separates food vs services', () {
    final now = DateTime.now();
    final bakeryDeal = DealItem(
      id: '1',
      title: 'Panier Viennoiseries',
      businessName: 'Boulangerie Paul Guéliz',
      originalPrice: 80,
      discountedPrice: 35,
      remainingCount: 3,
      location: 'Guéliz, Marrakech',
      latitude: 31.6346,
      longitude: -8.0125,
      imageUrl: '',
      expiresAt: now.add(const Duration(hours: 2)),
      category: 'Boulangerie',
    );

    final floristDeal = DealItem(
      id: '2',
      title: 'Bouquet de Roses',
      businessName: 'Fleuriste Jasmin',
      originalPrice: 150,
      discountedPrice: 70,
      remainingCount: 2,
      location: 'Hivernage, Marrakech',
      latitude: 31.6200,
      longitude: -8.0100,
      imageUrl: '',
      expiresAt: now.add(const Duration(hours: 4)),
      category: 'Fleuriste',
    );

    bool isAlimentaire(DealItem deal) {
      final text = "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();
      return text.contains('boulang') ||
          text.contains('patiss') ||
          text.contains('pain') ||
          text.contains('croissant') ||
          text.contains('restau') ||
          text.contains('food') ||
          text.contains('plat') ||
          text.contains('épicer') ||
          text.contains('grocery');
    }

    bool isServices(DealItem deal) {
      final text = "${deal.title} ${deal.businessName} ${deal.category}".toLowerCase();
      return text.contains('fleur') ||
          text.contains('florist') ||
          text.contains('plante') ||
          text.contains('bouquet') ||
          text.contains('beauté') ||
          text.contains('soin') ||
          text.contains('coiff') ||
          text.contains('artisan');
    }

    expect(isAlimentaire(bakeryDeal), isTrue);
    expect(isServices(bakeryDeal), isFalse);

    expect(isServices(floristDeal), isTrue);
    expect(isAlimentaire(floristDeal), isFalse);
  });
}
