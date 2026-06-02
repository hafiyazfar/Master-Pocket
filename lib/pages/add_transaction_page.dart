import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:master_pocket/models/transactions.dart';
import 'package:master_pocket/providers/transactions_provider.dart';
import 'package:master_pocket/theme/wallet_theme.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  static const _expenseCategories = [
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Fun',
    'Other',
  ];
  static const _incomeCategories = [
    'Salary',
    'Side job',
    'Gift',
    'Refund',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  TxType _type = TxType.expense;
  String _category = _expenseCategories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  List<String> get _categories =>
      _type == TxType.expense ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (_saving || formState == null || !formState.validate()) return;

    setState(() => _saving = true);

    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', ''));
    final tx = Tx(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      amount: amount,
      date: _date,
      type: _type,
      category: _category,
    );

    try {
      await ref.read(transactionsProvider.notifier).addTx(tx);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    }
  }

  void _setType(TxType type) {
    setState(() {
      _type = type;
      final nextCategories = type == TxType.expense
          ? _expenseCategories
          : _incomeCategories;
      if (!nextCategories.contains(_category)) {
        _category = nextCategories.first;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDate: _date,
    );

    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actionColor = _type == TxType.expense
        ? walletExpenseColor(context)
        : walletSuccessColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New transaction'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentedButton<TxType>(
                            segments: const [
                              ButtonSegment(
                                value: TxType.expense,
                                icon: Icon(Icons.arrow_upward),
                                label: Text('Expense'),
                              ),
                              ButtonSegment(
                                value: TxType.income,
                                icon: Icon(Icons.arrow_downward),
                                label: Text('Income'),
                              ),
                            ],
                            selected: {_type},
                            onSelectionChanged: (selected) =>
                                _setType(selected.first),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _amountCtrl,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            style: textTheme.headlineSmall?.copyWith(
                              color: actionColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: 'RM ',
                              hintText: '12.50',
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: actionColor,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter amount';
                              }
                              final amount = double.tryParse(
                                value.trim().replaceAll(',', ''),
                              );
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _titleCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Lunch',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter a title'
                                : null,
                            onFieldSubmitted: (_) => _save(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormSectionTitle(
                            title: 'Category',
                            icon: Icons.category_outlined,
                            color: actionColor,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final category in _categories)
                                ChoiceChip(
                                  selected: category == _category,
                                  selectedColor: actionColor.withValues(
                                    alpha: 0.14,
                                  ),
                                  backgroundColor: scheme.surfaceContainerLow,
                                  side: BorderSide(
                                    color: category == _category
                                        ? actionColor
                                        : scheme.outlineVariant,
                                  ),
                                  avatar: Icon(
                                    _categoryIcon(category),
                                    size: 18,
                                    color: category == _category
                                        ? actionColor
                                        : _categoryColor(category),
                                  ),
                                  label: Text(category),
                                  labelStyle: TextStyle(
                                    color: category == _category
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                    fontWeight: category == _category
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _category = category),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _FormSectionTitle(
                            title: 'Date',
                            icon: Icons.calendar_today_outlined,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _pickDate,
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: scheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      color: scheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _formatDate(_date),
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Saving' : 'Save transaction'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _FormSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
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
