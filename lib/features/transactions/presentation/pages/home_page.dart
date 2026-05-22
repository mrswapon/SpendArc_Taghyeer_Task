import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:spend_arc/features/settings/presentation/bloc/settings_state.dart';
import 'package:spend_arc/features/settings/presentation/pages/settings_page.dart';
import 'package:spend_arc/features/transactions/domain/entities/transaction.dart';
import 'package:spend_arc/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:spend_arc/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:spend_arc/features/transactions/presentation/widgets/arc_meter_widget.dart';
import 'package:spend_arc/features/transactions/presentation/widgets/line_chart_widget.dart';
import 'package:spend_arc/features/transactions/presentation/widgets/transaction_list_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const LoadTransactionsEvent());
  }

  Future<void> _openAddPage() async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (result != null && mounted) {
      context.read<TransactionBloc>().add(AddTransactionEvent(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'SpendArc',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              final settingsBloc = context.read<SettingsBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: settingsBloc,
                    child: const SettingsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = state is TransactionLoaded
              ? state.transactions
              : state is TransactionError
                  ? state.transactions
                  : <Transaction>[];

          final loaded = state is TransactionLoaded ? state : null;

          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              final currency = settingsState is SettingsLoaded
                  ? settingsState.settings.currency
                  : 'USD';
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _SummaryHeader(
                      loaded: loaded,
                      transactionCount: transactions.length,
                      currency: currency,
                    ),
                  ),
                  if (transactions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final tx = transactions[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionListItem(
                                key: ValueKey(tx.id),
                                transaction: tx,
                                onDelete: () => context
                                    .read<TransactionBloc>()
                                    .add(DeleteTransactionEvent(tx.id)),
                              ),
                            );
                          },
                          childCount: transactions.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final TransactionLoaded? loaded;
  final int transactionCount;
  final String currency;

  const _SummaryHeader({
    this.loaded,
    required this.transactionCount,
    this.currency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final pct = loaded?.budgetUsageRatio ?? 0;
    final budget = loaded?.monthlyBudget ?? 5000;
    final spent = loaded?.totalExpenses ?? 0;
    final expenseChartData =
        loaded?.last7DaysSpending ?? List.filled(7, 0.0);
    final incomeChartData = loaded?.last7DaysIncome ?? List.filled(7, 0.0);

    final totalIncome =
        incomeChartData.fold(0.0, (sum, value) => sum + value);
    final totalExpense =
        expenseChartData.fold(0.0, (sum, value) => sum + value);

    final now = DateTime.now();
    final labels = List.generate(
        7, (i) => DateFormat('E').format(now.subtract(Duration(days: 6 - i))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //============================>  Arc Meter Card. <========================
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Monthly Budget',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ArcMeterWidget(
                    percentage: pct,
                    spent: spent,
                    budget: budget,
                    currency: currency,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                          label: 'Spent',
                          value: '$currency ${spent.toStringAsFixed(0)}',
                          color: Colors.red.shade400),
                      _StatChip(
                          label: 'Remaining',
                          value:
                              '$currency ${(budget - spent).clamp(0, double.infinity).toStringAsFixed(0)}',
                          color: Colors.green.shade500),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        //============================>  Line Chart Card. <========================
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last 7 Days',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                          ),
                          Text(
                            'Income vs expense trend',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ChartSummaryTile(
                        label: 'Income',
                        value: '$currency ${totalIncome.toStringAsFixed(0)}',
                        color: const Color(0xFF2E7D32),
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChartSummaryTile(
                        label: 'Expense',
                        value: '$currency ${totalExpense.toStringAsFixed(0)}',
                        color: const Color(0xFFE53935),
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _ChartLegendItem(
                      color: Color(0xFF66BB6A),
                      label: 'Income',
                    ),
                    SizedBox(width: 12),
                    _ChartLegendItem(
                      color: Color(0xFFEF5350),
                      label: 'Expense',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 240,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(4, 12, 8, 0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  child: LineChartWidget(
                    expenseData: expenseChartData,
                    incomeData: incomeChartData,
                    labels: labels,
                  ),
                ),
              ],
            ),
          ),
        ),

        //============================>  Section Header. <========================
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
          child: Row(
            children: [
              Text(
                'Transactions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '$transactionCount total',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ChartSummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Tap + to add your first one',
              style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
