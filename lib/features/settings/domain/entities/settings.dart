// DOMAIN LAYER — no Flutter imports allowed

class Settings {
  final double monthlyBudget;
  final String currency;

  const Settings({
    required this.monthlyBudget,
    required this.currency,
  });

  Settings copyWith({double? monthlyBudget, String? currency}) {
    return Settings(
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          monthlyBudget == other.monthlyBudget &&
          currency == other.currency;

  @override
  int get hashCode => monthlyBudget.hashCode ^ currency.hashCode;
}
