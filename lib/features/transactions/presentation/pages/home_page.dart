import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
            onPressed: () {},
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

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  loaded: loaded,
                  transactionCount: transactions.length,
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
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final TransactionLoaded? loaded;
  final int transactionCount;

  const _SummaryHeader({this.loaded, required this.transactionCount});

  @override
  Widget build(BuildContext context) {
    final pct = loaded?.budgetUsageRatio ?? 0;
    final budget = loaded?.monthlyBudget ?? 5000;
    final spent = loaded?.totalExpenses ?? 0;
    final chartData = loaded?.last7DaysSpending ?? List.filled(7, 0.0);

    final now = DateTime.now();
    final labels = List.generate(
        7,
        (i) => DateFormat('E')
            .format(now.subtract(Duration(days: 6 - i))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arc meter card.
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
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                          label: 'Spent',
                          value: '\$${spent.toStringAsFixed(0)}',
                          color: Colors.red.shade400),
                      _StatChip(
                          label: 'Remaining',
                          value:
                              '\$${(budget - spent).clamp(0, double.infinity).toStringAsFixed(0)}',
                          color: Colors.green.shade500),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Line chart — full screen width, no card margin.
        Container(
          width: double.infinity,
          color: Colors.white,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 7 Days',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: LineChartWidget(data: chartData, labels: labels),
              ),
            ],
          ),
        ),

        // Section header.
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
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
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
            style:
                TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
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
