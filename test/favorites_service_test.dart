import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baraka_app/services/favorites_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavoritesService.instance.clear();
  });

  test('FavoritesService initializes with empty favorites when no user is logged in', () {
    expect(FavoritesService.instance.favoritesNotifier.value, isEmpty);
    expect(FavoritesService.instance.isFavorite('deal-1'), isFalse);
  });

  test('FavoritesService throws when user is not authenticated', () async {
    expect(
      () => FavoritesService.instance.toggleFavorite('deal-123'),
      throwsA(isA<Exception>()),
    );
  });

  test('Favorites can be loaded from SharedPreferences when key exists', () async {
    SharedPreferences.setMockInitialValues({
      'baraka_favorites_test_user': jsonEncode(['deal-1', 'deal-2']),
    });

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('baraka_favorites_test_user');
    expect(data, isNotNull);
    final list = jsonDecode(data!) as List;
    expect(list, contains('deal-1'));
    expect(list, contains('deal-2'));
  });
}
