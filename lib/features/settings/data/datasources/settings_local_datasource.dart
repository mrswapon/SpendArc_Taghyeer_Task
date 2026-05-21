import 'package:hive_flutter/hive_flutter.dart';
import 'package:spend_arc/features/settings/domain/entities/settings.dart';

class SettingsLocalDataSource {
  static const _boxName = 'settings';
  static const _budgetKey = 'monthly_budget';
  static const _currencyKey = 'currency';

  final Box _box;

  SettingsLocalDataSource(this._box);

  static Future<SettingsLocalDataSource> create() async {
    final box = await Hive.openBox(_boxName);
    return SettingsLocalDataSource(box);
  }

  Settings load() {
    return Settings(
      monthlyBudget:
          (_box.get(_budgetKey, defaultValue: 5000.0) as num).toDouble(),
      currency: _box.get(_currencyKey, defaultValue: 'USD') as String,
    );
  }

  Future<void> save(Settings settings) async {
    await _box.put(_budgetKey, settings.monthlyBudget);
    await _box.put(_currencyKey, settings.currency);
  }
}
