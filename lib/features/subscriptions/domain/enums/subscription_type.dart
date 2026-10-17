enum SubscriptionType {
  freeTrial,
  subscription;

  String get label {
    switch (this) {
      case SubscriptionType.freeTrial:
        return 'Prueba gratuita';
      case SubscriptionType.subscription:
        return 'Suscripción';
    }
  }

  String get rawValue {
    switch (this) {
      case SubscriptionType.freeTrial:
        return 'free_trial';
      case SubscriptionType.subscription:
        return 'subscription';
    }
  }

  static SubscriptionType fromRawValue(String s) {
    switch (s) {
      case 'free_trial':
        return SubscriptionType.freeTrial;
      default:
        return SubscriptionType.subscription;
    }
  }
}
