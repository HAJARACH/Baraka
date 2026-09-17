import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baraka_app/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders logo, Baraka brand and slogan', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // Vérifie la présence du slogan, de la ville et des images (fond zellige et logo)
    expect(find.text("Des petits gestes, des grands impacts."), findsOneWidget);
    expect(find.text("MARRAKECH"), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });
}
