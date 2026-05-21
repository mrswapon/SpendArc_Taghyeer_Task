import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class UpdateBudgetEvent extends SettingsEvent {
  final double monthlyBudget;
  const UpdateBudgetEvent(this.monthlyBudget);

  @override
  List<Object?> get props => [monthlyBudget];
}

class UpdateCurrencyEvent extends SettingsEvent {
  final String currency;
  const UpdateCurrencyEvent(this.currency);

  @override
  List<Object?> get props => [currency];
}
