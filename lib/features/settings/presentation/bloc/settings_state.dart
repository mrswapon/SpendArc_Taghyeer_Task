import 'package:equatable/equatable.dart';
import 'package:spend_arc/features/settings/domain/entities/settings.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  final Settings settings;
  const SettingsLoaded(this.settings);

  SettingsLoaded copyWith({Settings? settings}) =>
      SettingsLoaded(settings ?? this.settings);

  @override
  List<Object?> get props => [settings];
}
