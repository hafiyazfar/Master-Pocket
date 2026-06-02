import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:master_pocket/models/transactions.dart';
import 'package:master_pocket/providers/budget_provider.dart';
import 'package:master_pocket/providers/transactions_provider.dart';
import 'package:master_pocket/theme/wallet_theme.dart';

class SavingsPage extends ConsumerStatefulWidget {
  const SavingsPage({super.key});

  @override
  ConsumerState<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends ConsumerState<SavingsPage> {
  final _itemCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _itemCtrl.addListener(_onGoalChanged);
    _priceCtrl.addListener(_onGoalChanged);
  }

  @override
  void dispose() {
    _itemCtrl
      ..removeListener(_onGoalChanged)
      ..dispose();
    _priceCtrl
      ..removeListener(_onGoalChanged)
      ..dispose();
    super.dispose();
  }

  void _onGoalChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: _targetDate.isBefore(now) ? now : _targetDate,
    );

    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final txsAsync = ref.watch(transactionsProvider);
    final budget = ref
        .watch(monthlyBudgetProvider)
        .when(
          data: (value) => value,
          loading: () => 0.0,
          error: (_, __) => 0.0,
        );
    final item = _itemCtrl.text.trim();
    final targetAmount = _parseMoney(_priceCtrl.text);

    return txsAsync.when(
      loading: () => const _SavingsLoading(),
      error: (error, _) => _SavingsError(
        detail: error.toString(),
        onRetry: () => ref.invalidate(transactionsProvider),
      ),
      data: (txs) {
        final plan = _SavingsPlan.from(
          txs: txs,
          budget: budget,
          item: item,
          targetAmount: targetAmount,
          targetDate: _targetDate,
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                const _SavingsHeader(),
                const SizedBox(height: 16),
                _SavingsGoalCard(
                  itemCtrl: _itemCtrl,
                  priceCtrl: _priceCtrl,
                  targetDate: _targetDate,
                  onPickTargetDate: _pickTargetDate,
                ),
                const SizedBox(height: 14),
                if (plan.isReady)
                  _SavingsPlanCard(plan: plan)
                else
                  const _SavingsEmptyCard(),
                if (plan.isReady) ...[
                  const SizedBox(height: 14),
                  _SavingsSuggestionsCard(plan: plan),
                  const SizedBox(height: 14),
                  _SavingsCashflowCard(plan: plan),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavingsHeader extends StatelessWidget {
  const _SavingsHeader();

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
                'Savings',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AI savings coach',
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
          child: Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
        ),
      ],
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  final TextEditingController itemCtrl;
  final TextEditingController priceCtrl;
  final DateTime targetDate;
  final VoidCallback onPickTargetDate;

  const _SavingsGoalCard({
    required this.itemCtrl,
    required this.priceCtrl,
    required this.targetDate,
    required this.onPickTargetDate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: scheme.onPrimaryContainer,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Saving goal',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: itemCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'What do you want to buy?',
                hintText: 'Laptop, phone, trip',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Target price',
                hintText: '2500',
                prefixText: 'RM ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPickTargetDate,
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_outlined,
                        color: scheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target date',
                            style: textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(targetDate),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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

class _SavingsEmptyCard extends StatelessWidget {
  const _SavingsEmptyCard();

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
              child: Icon(
                Icons.auto_awesome,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready for a goal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter an item and target price to generate a savings plan.',
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

class _SavingsPlanCard extends StatelessWidget {
  final _SavingsPlan plan;

  const _SavingsPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = walletBalanceCardColor(context);
    const onCard = Colors.white;
    final subdued = onCard.withValues(alpha: 0.72);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onCard.withValues(alpha: 0.10)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: walletPrimary.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI plan for ${plan.item}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _OnCardPill(
                  label: plan.canBuyNow ? 'Ready' : '${plan.days} days',
                ),
              ],
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                plan.canBuyNow
                    ? 'Covered by balance'
                    : '${_formatCurrency(plan.weeklyRequired)} weekly',
                style: textTheme.headlineSmall?.copyWith(
                  color: onCard,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.canBuyNow
                  ? 'Keep your spending buffer before checkout.'
                  : '${_formatCurrency(plan.monthlyRequired)} per month until ${_formatDate(plan.targetDate)}',
              style: textTheme.bodyMedium?.copyWith(
                color: subdued,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: plan.progress,
                color: plan.canBuyNow ? walletSuccessDark : Colors.white,
                backgroundColor: onCard.withValues(alpha: 0.16),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _OnCardStat(
                    label: 'Current',
                    value: _formatCurrency(plan.currentBalance),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OnCardStat(
                    label: 'Shortfall',
                    value: _formatCurrency(plan.shortfall),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OnCardStat(
                    label: 'Target',
                    value: _formatCurrency(plan.targetAmount),
                    icon: Icons.flag_outlined,
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

class _SavingsSuggestionsCard extends StatelessWidget {
  final _SavingsPlan plan;

  const _SavingsSuggestionsCard({required this.plan});

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI recommendations',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            for (final suggestion in plan.suggestions)
              _SuggestionRow(suggestion: suggestion),
          ],
        ),
      ),
    );
  }
}

class _SavingsCashflowCard extends StatelessWidget {
  final _SavingsPlan plan;

  const _SavingsCashflowCard({required this.plan});

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
              'Monthly snapshot',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CashflowTile(
                    label: 'Income',
                    value: _formatCurrency(plan.monthlyIncome),
                    icon: Icons.arrow_downward,
                    color: walletSuccessColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CashflowTile(
                    label: 'Spent',
                    value: _formatCurrency(plan.monthlySpent),
                    icon: Icons.arrow_upward,
                    color: walletExpenseColor(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CashflowTile(
                    label: 'Buffer',
                    value: _formatCurrency(plan.monthlyBuffer),
                    icon: Icons.shield_outlined,
                    color: plan.monthlyBuffer > 0
                        ? walletSuccessColor(context)
                        : walletWarningColor(context),
                  ),
                ),
              ],
            ),
            if (plan.topCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Top spending levers',
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final entry in plan.topCategories.take(3))
                _CategoryLeverRow(category: entry.key, amount: entry.value),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final _SavingsSuggestion suggestion;

  const _SuggestionRow({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: suggestion.color(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              suggestion.icon,
              color: suggestion.color(context),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  suggestion.detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashflowTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CashflowTile({
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

class _CategoryLeverRow extends StatelessWidget {
  final String category;
  final double amount;

  const _CategoryLeverRow({required this.category, required this.amount});

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
            child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _OnCardPill extends StatelessWidget {
  final String label;

  const _OnCardPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OnCardStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _OnCardStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 78,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.82), size: 17),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsLoading extends StatelessWidget {
  const _SavingsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SavingsError extends StatelessWidget {
  final String detail;
  final VoidCallback onRetry;

  const _SavingsError({required this.detail, required this.onRetry});

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
              'Could not load savings data.',
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

class _SavingsPlan {
  final String item;
  final double targetAmount;
  final DateTime targetDate;
  final double currentBalance;
  final double shortfall;
  final double weeklyRequired;
  final double monthlyRequired;
  final double monthlyIncome;
  final double monthlySpent;
  final double monthlyBuffer;
  final double progress;
  final int days;
  final List<MapEntry<String, double>> topCategories;
  final List<_SavingsSuggestion> suggestions;

  const _SavingsPlan({
    required this.item,
    required this.targetAmount,
    required this.targetDate,
    required this.currentBalance,
    required this.shortfall,
    required this.weeklyRequired,
    required this.monthlyRequired,
    required this.monthlyIncome,
    required this.monthlySpent,
    required this.monthlyBuffer,
    required this.progress,
    required this.days,
    required this.topCategories,
    required this.suggestions,
  });

  bool get isReady => item.isNotEmpty && targetAmount > 0;

  bool get canBuyNow => isReady && shortfall <= 0.01;

  factory _SavingsPlan.from({
    required List<Tx> txs,
    required double budget,
    required String item,
    required double targetAmount,
    required DateTime targetDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedTarget = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final days = normalizedTarget
        .difference(today)
        .inDays
        .clamp(1, 3650)
        .toInt();
    final monthlyTxs = txs
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();
    final monthlyIncome = _sumByType(monthlyTxs, TxType.income);
    final monthlySpent = _sumByType(monthlyTxs, TxType.expense);
    final totalIncome = _sumByType(txs, TxType.income);
    final totalExpense = _sumByType(txs, TxType.expense);
    final currentBalance = (totalIncome - totalExpense)
        .clamp(0.0, double.infinity)
        .toDouble();
    final shortfall = (targetAmount - currentBalance)
        .clamp(0.0, double.infinity)
        .toDouble();
    final weeks = (days / 7).clamp(1.0, double.infinity).toDouble();
    final months = (days / 30.4375).clamp(0.25, double.infinity).toDouble();
    final weeklyRequired = shortfall / weeks;
    final monthlyRequired = shortfall / months;
    final monthlySurplus = monthlyIncome - monthlySpent;
    final budgetBuffer = budget > 0 ? budget - monthlySpent : monthlySurplus;
    final monthlyBuffer = budgetBuffer.clamp(0.0, double.infinity).toDouble();
    final progress = targetAmount <= 0
        ? 0.0
        : (currentBalance / targetAmount).clamp(0.0, 1.0).toDouble();
    final categoryTotals = _categoryTotals(monthlyTxs);
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final basePlan = _SavingsPlan(
      item: item,
      targetAmount: targetAmount,
      targetDate: normalizedTarget,
      currentBalance: currentBalance,
      shortfall: shortfall,
      weeklyRequired: weeklyRequired,
      monthlyRequired: monthlyRequired,
      monthlyIncome: monthlyIncome,
      monthlySpent: monthlySpent,
      monthlyBuffer: monthlyBuffer,
      progress: progress,
      days: days,
      topCategories: topCategories,
      suggestions: const [],
    );

    return _SavingsPlan(
      item: basePlan.item,
      targetAmount: basePlan.targetAmount,
      targetDate: basePlan.targetDate,
      currentBalance: basePlan.currentBalance,
      shortfall: basePlan.shortfall,
      weeklyRequired: basePlan.weeklyRequired,
      monthlyRequired: basePlan.monthlyRequired,
      monthlyIncome: basePlan.monthlyIncome,
      monthlySpent: basePlan.monthlySpent,
      monthlyBuffer: basePlan.monthlyBuffer,
      progress: basePlan.progress,
      days: basePlan.days,
      topCategories: basePlan.topCategories,
      suggestions: _buildSuggestions(basePlan),
    );
  }
}

class _SavingsSuggestion {
  final IconData icon;
  final String title;
  final String detail;
  final _SuggestionTone tone;

  const _SavingsSuggestion({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tone,
  });

  Color color(BuildContext context) {
    return switch (tone) {
      _SuggestionTone.primary => Theme.of(context).colorScheme.primary,
      _SuggestionTone.success => walletSuccessColor(context),
      _SuggestionTone.warning => walletWarningColor(context),
    };
  }
}

enum _SuggestionTone { primary, success, warning }

List<_SavingsSuggestion> _buildSuggestions(_SavingsPlan plan) {
  if (!plan.isReady) return const [];

  final suggestions = <_SavingsSuggestion>[];

  if (plan.canBuyNow) {
    final cushion = (plan.currentBalance - plan.targetAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
    suggestions.add(
      _SavingsSuggestion(
        icon: Icons.check_circle_outline,
        title: 'Ready to buy',
        detail:
            'Your recorded balance covers it with ${_formatCurrency(cushion)} left.',
        tone: _SuggestionTone.success,
      ),
    );
  } else {
    suggestions.add(
      _SavingsSuggestion(
        icon: Icons.calendar_view_week_outlined,
        title: 'Automate ${_formatCurrency(plan.weeklyRequired)} weekly',
        detail: 'Move it into savings before daily spending starts.',
        tone: _SuggestionTone.primary,
      ),
    );

    if (plan.monthlyBuffer >= plan.monthlyRequired &&
        plan.monthlyRequired > 0) {
      suggestions.add(
        _SavingsSuggestion(
          icon: Icons.shield_outlined,
          title: 'Use monthly buffer',
          detail:
              'Your current buffer can cover the ${_formatCurrency(plan.monthlyRequired)} monthly target.',
          tone: _SuggestionTone.success,
        ),
      );
    } else if (plan.monthlyBuffer > 0) {
      final gap = plan.monthlyRequired - plan.monthlyBuffer;
      suggestions.add(
        _SavingsSuggestion(
          icon: Icons.speed_outlined,
          title: 'Close a ${_formatCurrency(gap)} gap',
          detail: 'Pair your monthly buffer with one small category cut.',
          tone: _SuggestionTone.warning,
        ),
      );
    }

    for (final entry in plan.topCategories.take(3)) {
      final percent = _flexCutPercent(entry.key);
      final savings = entry.value * percent;
      if (savings < 5) continue;

      suggestions.add(
        _SavingsSuggestion(
          icon: _categoryIcon(entry.key),
          title: 'Trim ${entry.key} by ${(percent * 100).toStringAsFixed(0)}%',
          detail:
              'That frees about ${_formatCurrency(savings)} this month for ${plan.item}.',
          tone: _SuggestionTone.primary,
        ),
      );
    }
  }

  if (suggestions.length < 4 && !plan.canBuyNow) {
    suggestions.add(
      _SavingsSuggestion(
        icon: Icons.toll_outlined,
        title: 'Round up purchases',
        detail: 'Move spare change into this goal after every transaction.',
        tone: _SuggestionTone.success,
      ),
    );
  }

  return suggestions.take(5).toList();
}

Map<String, double> _categoryTotals(List<Tx> txs) {
  final totals = <String, double>{};
  for (final tx in txs) {
    if (tx.type != TxType.expense) continue;
    totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
  }
  return totals;
}

double _sumByType(List<Tx> txs, TxType type) {
  return txs
      .where((tx) => tx.type == type)
      .fold(0.0, (total, tx) => total + tx.amount);
}

double _parseMoney(String raw) {
  return double.tryParse(raw.trim().replaceAll(',', '')) ?? 0.0;
}

double _flexCutPercent(String category) {
  return switch (category) {
    'Shopping' || 'Fun' => 0.18,
    'Food' || 'Transport' => 0.12,
    'Bills' || 'Health' => 0.06,
    _ => 0.10,
  };
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

IconData _categoryIcon(String category) {
  return switch (category) {
    'Food' => Icons.restaurant_outlined,
    'Transport' => Icons.directions_car_outlined,
    'Bills' => Icons.receipt_long_outlined,
    'Shopping' => Icons.shopping_bag_outlined,
    'Health' => Icons.health_and_safety_outlined,
    'Fun' => Icons.local_activity_outlined,
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
    _ => const Color(0xFF64748B),
  };
}
