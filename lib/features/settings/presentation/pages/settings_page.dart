import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_event.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _budgetCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _currency = 'USD';
  bool _saved = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'INR', 'BDT'];

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    if (state is SettingsLoaded) {
      _budgetCtrl.text = state.settings.monthlyBudget.toStringAsFixed(0);
      _currency = state.settings.currency;
    }
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final budget = double.parse(_budgetCtrl.text.trim());
    context.read<SettingsBloc>()
      ..add(UpdateBudgetEvent(budget))
      ..add(UpdateCurrencyEvent(_currency));
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          // Reflect external changes (e.g. from TransactionBloc) if any.
          if (state is SettingsLoaded && !_saved) {
            _budgetCtrl.text =
                state.settings.monthlyBudget.toStringAsFixed(0);
            setState(() => _currency = state.settings.currency);
          }
          _saved = false;
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // ── Budget ────────────────────────────────────────────────────
              _SectionHeader(title: 'Budget'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monthly budget',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Used to calculate the arc meter on the home screen',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Enter a positive number';
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // ── Currency ──────────────────────────────────────────────────
              _SectionHeader(title: 'Currency'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(
                  labelText: 'Display currency',
                  prefixIcon: Icon(Icons.currency_exchange),
                  border: OutlineInputBorder(),
                ),
                items: _currencies
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),

              const SizedBox(height: 40),

              // ── About ─────────────────────────────────────────────────────
              _SectionHeader(title: 'About'),
              const SizedBox(height: 12),
              _AboutTile(
                icon: Icons.info_outline,
                label: 'Version',
                value: '1.0.0',
              ),
              _AboutTile(
                icon: Icons.code,
                label: 'Architecture',
                value: 'Clean + BLoC',
              ),

              const SizedBox(height: 40),

              // ── Save ──────────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Settings'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey.shade500),
      title: Text(label),
      trailing: Text(
        value,
        style: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }
}
