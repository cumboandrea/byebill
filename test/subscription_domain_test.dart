import 'package:byebill/features/subscriptions/domain/entities/subscription.dart';
import 'package:byebill/features/subscriptions/domain/enums/subscription_status.dart';
import 'package:byebill/features/subscriptions/domain/enums/subscription_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subscription entity', () {
    final DateTime now = DateTime(2026, 10, 1, 12, 0);
    final DateTime charge = DateTime(2026, 10, 15, 23, 59);

    test('default values are applied correctly', () {
      final Subscription s = Subscription(
        id: 'test-id',
        name: 'Netflix',
        amount: 12.99,
        chargeDate: charge,
        createdAt: now,
      );
      expect(s.currency, 'EUR');
      expect(s.type, SubscriptionType.freeTrial);
      expect(s.status, SubscriptionStatus.active);
      expect(s.cancelledAt, isNull);
    });

    test('copyWith overrides only specified fields', () {
      final Subscription base = Subscription(
        id: 'a',
        name: 'A',
        amount: 1,
        chargeDate: charge,
        createdAt: now,
      );
      final Subscription copy = base.copyWith(
        name: 'B',
        status: SubscriptionStatus.cancelled,
        cancelledAt: now,
      );
      expect(copy.id, 'a');
      expect(copy.amount, 1);
      expect(copy.name, 'B');
      expect(copy.status, SubscriptionStatus.cancelled);
      expect(copy.cancelledAt, now);
    });

    test('== and hashCode compare field-by-field', () {
      final DateTime ts = DateTime(2026, 1, 1);
      final Subscription a = Subscription(
        id: 'x',
        name: 'X',
        amount: 2.99,
        currency: 'EUR',
        chargeDate: ts,
        type: SubscriptionType.freeTrial,
        status: SubscriptionStatus.active,
        createdAt: ts,
      );
      final Subscription b = Subscription(
        id: 'x',
        name: 'X',
        amount: 2.99,
        currency: 'EUR',
        chargeDate: ts,
        type: SubscriptionType.freeTrial,
        status: SubscriptionStatus.active,
        createdAt: ts,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('chargeDateAtNine returns day at 9:00', () {
      final Subscription s = Subscription(
        id: 'id',
        name: 'N',
        amount: 1,
        chargeDate: charge,
        createdAt: now,
      );
      final DateTime nine = s.chargeDateAtNine;
      expect(nine.year, 2026);
      expect(nine.month, 10);
      expect(nine.day, 15);
      expect(nine.hour, 9);
      expect(nine.minute, 0);
    });
  });

  group('Subscription enums', () {
    test('SubscriptionType rawValue and fromRawValue roundtrip', () {
      for (final SubscriptionType t in SubscriptionType.values) {
        expect(SubscriptionType.fromRawValue(t.rawValue), t);
      }
    });

    test('SubscriptionStatus rawValue and fromRawValue roundtrip', () {
      for (final SubscriptionStatus s in SubscriptionStatus.values) {
        expect(SubscriptionStatus.fromRawValue(s.rawValue), s);
      }
    });

    test('labels are in Spanish', () {
      expect(SubscriptionType.freeTrial.label, 'Prueba gratuita');
      expect(SubscriptionType.subscription.label, 'Suscripción');
      expect(SubscriptionStatus.active.label, 'Activa');
      expect(SubscriptionStatus.cancelled.label, 'Cancelada');
      expect(SubscriptionStatus.expired.label, 'Vencida');
    });
  });
}
