import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spend_arc/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:spend_arc/features/settings/domain/entities/settings.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_event.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsLocalDataSource _dataSource;

  SettingsBloc(this._dataSource) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoad);
    on<UpdateBudgetEvent>(_onUpdateBudget);
    on<UpdateCurrencyEvent>(_onUpdateCurrency);
  }

  void _onLoad(LoadSettingsEvent event, Emitter<SettingsState> emit) {
    emit(SettingsLoaded(_dataSource.load()));
  }

  Future<void> _onUpdateBudget(
      UpdateBudgetEvent event, Emitter<SettingsState> emit) async {
    final current = _currentSettings;
    final updated = current.copyWith(monthlyBudget: event.monthlyBudget);
    await _dataSource.save(updated);
    emit(SettingsLoaded(updated));
  }

  Future<void> _onUpdateCurrency(
      UpdateCurrencyEvent event, Emitter<SettingsState> emit) async {
    final current = _currentSettings;
    final updated = current.copyWith(currency: event.currency);
    await _dataSource.save(updated);
    emit(SettingsLoaded(updated));
  }

  Settings get _currentSettings => state is SettingsLoaded
      ? (state as SettingsLoaded).settings
      : _dataSource.load();
}
