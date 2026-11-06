import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/config/env.dart';
import 'package:kovoit/core/constants/api_constants.dart';

void main() {
  test('sans option, flutter run vise le backend en ligne', () {
    expect(Env.apiBaseUrl, ApiConstants.prodBaseUrl);
    expect(ApiConstants.prodBaseUrl, 'https://api.kovoittg.com/api/v1');
  });

  test('sans option, la fausse API est désactivée (seuls les tests la forcent)', () {
    final avant = Env.debugUseMockApiOverride;
    addTearDown(() => Env.debugUseMockApiOverride = avant);
    Env.debugUseMockApiOverride = null;
    expect(Env.useMockApi, isFalse);
  });
}
