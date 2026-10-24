import 'package:flutter_test/flutter_test.dart';
import 'package:kovoit/core/router/routes.dart';
import 'package:kovoit/features/notifications/presentation/push_coordinator.dart';

void main() {
  test('push du conducteur : ouvre le trajet publié, même en mode passager', () {
    final data = {'reservation_id': 'R1', 'trajet_id': 'T1', 'destinataire': 'conducteur'};
    expect(pushRoute(data: data, driverMode: false), Routes.driverTrip('T1'));
    expect(pushRoute(data: data, driverMode: true), Routes.driverTrip('T1'));
  });

  test('push du passager : ouvre sa réservation, même en mode conducteur', () {
    final data = {'reservation_id': 'R1', 'trajet_id': 'T1', 'destinataire': 'passager'};
    expect(pushRoute(data: data, driverMode: true), Routes.booking('R1'));
  });

  test('ancien format (sans destinataire) : selon le mode affiché', () {
    expect(pushRoute(data: {'reservation_id': 'R1'}, driverMode: false), Routes.booking('R1'));
    expect(pushRoute(data: {'reservation_id': 'R1'}, driverMode: true), Routes.myTrips);
    expect(pushRoute(data: const {}, driverMode: false), Routes.myTrips);
  });
}
