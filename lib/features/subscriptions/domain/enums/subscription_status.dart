enum SubscriptionStatus {
  active,
  cancelled,
  expired;

  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Activa';
      case SubscriptionStatus.cancelled:
        return 'Cancelada';
      case SubscriptionStatus.expired:
        return 'Vencida';
    }
  }

  String get rawValue {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.expired:
        return 'expired';
    }
  }

  static SubscriptionStatus fromRawValue(String s) {
    switch (s) {
      case 'active':
        return SubscriptionStatus.active;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.expired;
    }
  }
}
