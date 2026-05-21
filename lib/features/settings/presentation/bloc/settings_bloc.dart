import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spend_arc/features/settings/domain/entities/settings.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_event.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoad);
    on<UpdateBudgetEvent>(_onUpdateBudget);
    on<UpdateCurrencyEvent>(_onUpdateCurrency);
  }

  void _onLoad(LoadSettingsEvent event, Emitter<SettingsState> emit) {
    emit(const SettingsLoaded(
      Settings(monthlyBudget: 5000.0, currency: 'USD'),
    ));
  }

  void _onUpdateBudget(UpdateBudgetEvent event, Emitter<SettingsState> emit) {
    final current = state is SettingsLoaded
        ? (state as SettingsLoaded).settings
        : const Settings(monthlyBudget: 5000.0, currency: 'USD');
    emit(SettingsLoaded(current.copyWith(monthlyBudget: event.monthlyBudget)));
  }

  void _onUpdateCurrency(
      UpdateCurrencyEvent event, Emitter<SettingsState> emit) {
    final current = state is SettingsLoaded
        ? (state as SettingsLoaded).settings
        : const Settings(monthlyBudget: 5000.0, currency: 'USD');
    emit(SettingsLoaded(current.copyWith(currency: event.currency)));
  }
}
