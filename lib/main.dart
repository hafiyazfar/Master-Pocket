import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:master_pocket/models/transactions.dart';
import 'package:master_pocket/pages/add_transaction_page.dart';
import 'package:master_pocket/providers/budget_provider.dart';
import 'package:master_pocket/providers/category_totals_provider.dart';
import 'package:master_pocket/providers/transactions_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MasterPocketApp()));
}

class MasterPocketApp extends StatelessWidget {
  const MasterPocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Master Pocket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF7F8F5),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: scheme.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  String? _promptedBudgetMonthKey;
  bool _budgetDialogOpen = false;

  Future<void> _openBudgetDialog({bool fromMonthlyPrompt = false}) async {
    if (_budgetDialogOpen || !mounted) return;

    _budgetDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => _SetBudgetDialog(fromMonthlyPrompt: fromMonthlyPrompt),
      );
    } finally {
      _budgetDialogOpen = false;
    }
  }

  void _queueMonthlyBudgetPrompt(double budget) {
    if (budget > 0 || _budgetDialogOpen) return;

    final now = DateTime.now();
    final monthKey = _budgetPromptMonthKey(now);
    if (_promptedBudgetMonthKey == monthKey) return;

    _promptedBudgetMonthKey = monthKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openBudgetDialog(fromMonthlyPrompt: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(transactionsProvider);
    final budgetAsync = ref.watch(monthlyBudgetProvider);
    final spent = ref.watch(monthlyExpenseTotalProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);

    budgetAsync.when<void>(
      data: _queueMonthlyBudgetPrompt,
      loading: () {},
      error: (_, __) {},
    );

    return Scaffold(
      body: SafeArea(
        child: txsAsync.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(
            message: 'Could not load your transactions.',
            detail: error.toString(),
            onRetry: () => ref.invalidate(transactionsProvider),
          ),
          data: (txs) {
            final now = DateTime.now();
            final monthlyTxs = _transactionsForMonth(txs, now);
            final income = _sumByType(monthlyTxs, TxType.income);
            final budget = budgetAsync.when(
              data: (value) => value,
              loading: () => 0.0,
              error: (_, __) => 0.0,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    _DashboardHeader(monthLabel: _formatMonth(now)),
                    const SizedBox(height: 18),
                    budgetAsync.when(
                      loading: () => const _BudgetLoadingCard(),
                      error: (error, _) => _InlineErrorCard(
                        title: 'Budget unavailable',
                        message: error.toString(),
                      ),
                      data: (budgetValue) => _BudgetOverviewCard(
                        spent: spent,
                        income: income,
                        budget: budgetValue,
                        onSetBudget: () => _openBudgetDialog(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CategoryPieCard(
                      categoryTotals: categoryTotals,
                      spent: spent,
                      budget: budget,
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Recent activity',
                      trailing: txs.isEmpty
                          ? null
                          : Text(
                              '${txs.length} total',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                    ),
                    const SizedBox(height: 10),
                    if (txs.isEmpty)
                      const _EmptyTransactions()
                    else
                      ...txs.map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DismissibleTransactionTile(
                            tx: tx,
                            onDelete: () async {
                              await ref
                                  .read(transactionsProvider.notifier)
                                  .deleteTx(tx.id);
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('${tx.title} deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        ref
                                            .read(transactionsProvider.notifier)
                                            .addTx(tx);
                                      },
                                    ),
                                  ),
                                );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddTransactionPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String monthLabel;

  const _DashboardHeader({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Master Pocket',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monthLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  final double spent;
  final double income;
  final double budget;
  final VoidCallback onSetBudget;

  const _BudgetOverviewCard({
    required this.spent,
    required this.income,
    required this.budget,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasBudget = budget > 0;
    final remaining = budget - spent;
    final overBudget = hasBudget && remaining < 0;
    final progress = hasBudget
        ? (spent / budget).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final statusColor = !hasBudget
        ? scheme.secondary
        : overBudget
        ? scheme.error
        : progress >= 0.85
        ? const Color(0xFFB7791F)
        : const Color(0xFF15803D);
    final statusLabel = !hasBudget
        ? 'Budget not set'
        : overBudget
        ? 'Over budget'
        : progress >= 0.85
        ? 'Close to limit'
        : 'On track';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monthly budget',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              hasBudget
                  ? overBudget
                        ? 'Over by ${_formatCurrency(remaining.abs())}'
                        : 'Available ${_formatCurrency(remaining)}'
                  : "Add this month's budget",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: overBudget ? scheme.error : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: hasBudget ? progress : null,
                color: overBudget ? scheme.error : scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Spent',
                    value: _formatCurrency(spent),
                    icon: Icons.arrow_upward,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Budget',
                    value: _formatCurrency(budget),
                    icon: Icons.savings_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Income',
                    value: _formatCurrency(income),
                    icon: Icons.arrow_downward,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onSetBudget,
                icon: const Icon(Icons.edit_outlined),
                label: Text(hasBudget ? 'Update this month' : 'Set this month'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetLoadingCard extends StatelessWidget {
  const _BudgetLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Text(
              'Loading budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 88,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieCard extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double spent;
  final double budget;

  const _CategoryPieCard({
    required this.categoryTotals,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (budget <= 0) {
      return _InfoCard(
        icon: Icons.pie_chart_outline,
        title: 'Budget breakdown',
        message: "Set this month's budget to compare spending by category.",
      );
    }

    final remaining = (budget - spent).clamp(0.0, double.infinity).toDouble();
    final overBudget = spent > budget;
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sections = <PieChartSectionData>[
      for (final entry in entries)
        PieChartSectionData(
          value: entry.value,
          color: _categoryColor(entry.key),
          title: _sectionTitle(entry.value, budget),
          radius: 58,
          titleStyle: textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      if (remaining > 0)
        PieChartSectionData(
          value: remaining,
          color: scheme.surfaceContainerHighest,
          title: '',
          radius: 52,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Budget breakdown',
              trailing: Text(
                '${((spent / budget) * 100).clamp(0, 999).toStringAsFixed(0)}% used',
                style: textTheme.labelLarge?.copyWith(
                  color: overBudget ? scheme.error : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 214,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: PieChart(
                      PieChartData(
                        sections: sections.isEmpty
                            ? [
                                PieChartSectionData(
                                  value: 1,
                                  color: scheme.surfaceContainerHighest,
                                  radius: 52,
                                  title: '',
                                ),
                              ]
                            : sections,
                        centerSpaceRadius: 58,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCurrency(spent),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'spent',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Text(
                'No expenses recorded this month.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              ...entries
                  .take(5)
                  .map(
                    (entry) => _LegendRow(
                      label: entry.key,
                      amount: entry.value,
                      percent: entry.value / budget,
                      color: _categoryColor(entry.key),
                    ),
                  ),
            _LegendRow(
              label: 'Remaining',
              amount: remaining,
              percent: remaining / budget,
              color: scheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final double amount;
  final double percent;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label (${(percent * 100).clamp(0, 999).toStringAsFixed(0)}%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DismissibleTransactionTile extends StatelessWidget {
  final Tx tx;
  final Future<void> Function() onDelete;

  const _DismissibleTransactionTile({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onError),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete transaction'),
                content: Text('Delete "${tx.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: _TransactionTile(tx: tx),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Tx tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isExpense = tx.type == TxType.expense;
    final amountColor = isExpense
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);
    final sign = isExpense ? '-' : '+';
    final color = isExpense
        ? _categoryColor(tx.category)
        : const Color(0xFF16A34A);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExpense ? _categoryIcon(tx.category) : Icons.trending_up,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tx.category} - ${_formatDate(tx.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$sign ${_formatCurrency(tx.amount)}',
                style: textTheme.titleSmall?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetBudgetDialog extends ConsumerStatefulWidget {
  final bool fromMonthlyPrompt;

  const _SetBudgetDialog({this.fromMonthlyPrompt = false});

  @override
  ConsumerState<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends ConsumerState<_SetBudgetDialog> {
  final _ctrl = TextEditingController();
  bool _seeded = false;
  String? _errorText;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_ctrl.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Enter a budget greater than 0');
      return;
    }

    await ref.read(monthlyBudgetProvider.notifier).set(value);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref
        .watch(monthlyBudgetProvider)
        .when(
          data: (value) => value,
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );

    if (!_seeded) {
      _ctrl.text = current == 0 ? '' : current.toStringAsFixed(0);
      _seeded = true;
    }

    return AlertDialog(
      title: const Text("This month's budget"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fromMonthlyPrompt) ...[
            Text(
              'Enter your budget for ${_formatMonth(DateTime.now())}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: 'RM ',
              hintText: '1000',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.fromMonthlyPrompt ? 'Not now' : 'Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing case final trailing?) trailing,
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.receipt_long_outlined,
      title: 'No transactions yet',
      message: 'Tap Add transaction to record your first entry.',
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  final String title;
  final String message;

  const _InlineErrorCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: scheme.error, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

List<Tx> _transactionsForMonth(List<Tx> txs, DateTime month) {
  return txs
      .where((tx) => tx.date.year == month.year && tx.date.month == month.month)
      .toList();
}

double _sumByType(List<Tx> txs, TxType type) {
  return txs
      .where((tx) => tx.type == type)
      .fold(0.0, (total, tx) => total + tx.amount);
}

String _formatCurrency(double value) {
  return 'RM ${value.toStringAsFixed(2)}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatMonth(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _budgetPromptMonthKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

String _sectionTitle(double value, double budget) {
  final percent = (value / budget) * 100;
  return percent >= 7 ? '${percent.toStringAsFixed(0)}%' : '';
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Food' => Icons.restaurant_outlined,
    'Transport' => Icons.directions_car_outlined,
    'Bills' => Icons.receipt_long_outlined,
    'Shopping' => Icons.shopping_bag_outlined,
    'Health' => Icons.health_and_safety_outlined,
    'Fun' => Icons.local_activity_outlined,
    'Salary' => Icons.payments_outlined,
    'Side job' => Icons.work_outline,
    'Gift' => Icons.card_giftcard_outlined,
    'Refund' => Icons.replay_outlined,
    _ => Icons.category_outlined,
  };
}

Color _categoryColor(String category) {
  return switch (category) {
    'Food' => const Color(0xFFEA580C),
    'Transport' => const Color(0xFF2563EB),
    'Bills' => const Color(0xFF7C3AED),
    'Shopping' => const Color(0xFFDB2777),
    'Health' => const Color(0xFF0891B2),
    'Fun' => const Color(0xFFCA8A04),
    'Salary' => const Color(0xFF16A34A),
    'Side job' => const Color(0xFF0F766E),
    'Gift' => const Color(0xFFD97706),
    'Refund' => const Color(0xFF4F46E5),
    _ => const Color(0xFF64748B),
  };
}
