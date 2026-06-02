import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:master_pocket/models/transactions.dart';
import 'package:master_pocket/providers/transactions_provider.dart';
import 'package:master_pocket/theme/wallet_theme.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(transactionsProvider);

    return txsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ReportsError(
        detail: error.toString(),
        onRetry: () => ref.invalidate(transactionsProvider),
      ),
      data: (txs) {
        final months = _previousReportMonths(txs);

        if (months.isEmpty) {
          return const _ReportsEmptyState();
        }

        final selectedMonth =
            _selectedMonth != null &&
                months.any((month) => _isSameMonth(month, _selectedMonth!))
            ? _selectedMonth!
            : months.first;
        final report = _MonthReport.from(txs, selectedMonth);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                const _ReportsHeader(),
                const SizedBox(height: 16),
                _MonthSelectorCard(
                  months: months,
                  selectedMonth: selectedMonth,
                  onSelect: (month) => setState(() => _selectedMonth = month),
                ),
                const SizedBox(height: 14),
                _ReportSummaryCard(report: report),
                const SizedBox(height: 14),
                _TopCategoriesCard(report: report),
                const SizedBox(height: 14),
                _ReportTransactionsCard(report: report),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader();

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
                'Reports',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review previous months',
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
            Icons.bar_chart_outlined,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _MonthSelectorCard extends StatelessWidget {
  final List<DateTime> months;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onSelect;

  const _MonthSelectorCard({
    required this.months,
    required this.selectedMonth,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final month in months)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _isSameMonth(month, selectedMonth),
                    label: Text(_formatMonth(month)),
                    onSelected: (_) => onSelect(month),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final _MonthReport report;

  const _ReportSummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isPositive = report.net >= 0;
    final statusColor = isPositive
        ? walletSuccessColor(context)
        : walletExpenseColor(context);

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
                    _formatMonth(report.month),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(
                  label: '${report.transactionCount} entries',
                  color: scheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatSignedCurrency(report.net),
              style: textTheme.headlineSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPositive ? 'Saved after expenses' : 'Spent above income',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ReportMetricTile(
                    label: 'Income',
                    value: _formatCurrency(report.income),
                    icon: Icons.arrow_downward,
                    color: walletSuccessColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportMetricTile(
                    label: 'Spent',
                    value: _formatCurrency(report.expenses),
                    icon: Icons.arrow_upward,
                    color: walletExpenseColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportMetricTile(
                    label: 'Net',
                    value: _formatSignedCurrency(report.net),
                    icon: isPositive
                        ? Icons.savings_outlined
                        : Icons.warning_amber_outlined,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  final _MonthReport report;

  const _TopCategoriesCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top spending categories',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (report.topCategories.isEmpty)
              Text(
                'No expenses recorded for ${_formatMonth(report.month)}.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              for (final entry in report.topCategories.take(5))
                _CategoryReportRow(
                  category: entry.key,
                  amount: entry.value,
                  percent: report.expenses == 0
                      ? 0.0
                      : entry.value / report.expenses,
                ),
          ],
        ),
      ),
    );
  }
}

class _ReportTransactionsCard extends StatelessWidget {
  final _MonthReport report;

  const _ReportTransactionsCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Month activity',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final tx in report.transactions.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _txColor(context, tx).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _txIcon(tx),
                        color: _txColor(context, tx),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                    Text(
                      _formatTxAmount(tx),
                      style: textTheme.titleSmall?.copyWith(
                        color: _txAmountColor(context, tx),
                        fontWeight: FontWeight.w900,
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

class _ReportMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportMetricTile({
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

class _CategoryReportRow extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;

  const _CategoryReportRow({
    required this.category,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = _categoryColor(category);

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
              '$category (${(percent * 100).clamp(0, 999).toStringAsFixed(0)}%)',
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

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const _ReportsHeader(),
            const SizedBox(height: 16),
            Card(
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
                      child: Icon(
                        Icons.history_outlined,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No previous reports yet',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Older months will appear here after you add transactions dated before this month.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsError extends StatelessWidget {
  final String detail;
  final VoidCallback onRetry;

  const _ReportsError({required this.detail, required this.onRetry});

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
              'Could not load reports.',
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

class _MonthReport {
  final DateTime month;
  final double income;
  final double expenses;
  final double net;
  final int transactionCount;
  final List<MapEntry<String, double>> topCategories;
  final List<Tx> transactions;

  const _MonthReport({
    required this.month,
    required this.income,
    required this.expenses,
    required this.net,
    required this.transactionCount,
    required this.topCategories,
    required this.transactions,
  });

  factory _MonthReport.from(List<Tx> txs, DateTime month) {
    final monthTxs = _transactionsForMonth(txs, month);
    final income = _sumByType(monthTxs, TxType.income);
    final expenses = _sumByType(monthTxs, TxType.expense);
    final categoryTotals = <String, double>{};

    for (final tx in monthTxs) {
      if (tx.type != TxType.expense) continue;
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    monthTxs.sort((a, b) => b.date.compareTo(a.date));

    return _MonthReport(
      month: _monthStart(month),
      income: income,
      expenses: expenses,
      net: income - expenses,
      transactionCount: monthTxs.length,
      topCategories: topCategories,
      transactions: monthTxs,
    );
  }
}

List<DateTime> _previousReportMonths(List<Tx> txs) {
  final now = DateTime.now();
  final currentMonth = _monthStart(now);
  final monthsByKey = <String, DateTime>{};

  for (final tx in txs) {
    final month = _monthStart(tx.date);
    if (!month.isBefore(currentMonth)) continue;
    monthsByKey['${month.year}-${month.month}'] = month;
  }

  final months = monthsByKey.values.toList()..sort((a, b) => b.compareTo(a));
  return months;
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

DateTime _monthStart(DateTime date) {
  return DateTime(date.year, date.month);
}

bool _isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

String _formatCurrency(double value) {
  return 'RM ${value.toStringAsFixed(2)}';
}

String _formatSignedCurrency(double value) {
  if (value < 0) return '- ${_formatCurrency(value.abs())}';
  return _formatCurrency(value);
}

String _formatTxAmount(Tx tx) {
  final sign = tx.type == TxType.expense ? '-' : '+';
  return '$sign ${_formatCurrency(tx.amount)}';
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

IconData _txIcon(Tx tx) {
  return tx.type == TxType.income
      ? Icons.trending_up
      : _categoryIcon(tx.category);
}

Color _txColor(BuildContext context, Tx tx) {
  return tx.type == TxType.income
      ? walletSuccessColor(context)
      : _categoryColor(tx.category);
}

Color _txAmountColor(BuildContext context, Tx tx) {
  return tx.type == TxType.income
      ? walletSuccessColor(context)
      : walletExpenseColor(context);
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
