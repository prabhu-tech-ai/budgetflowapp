import 'package:flutter/material.dart';

import '../database/budget_database.dart';

enum RepeatPeriod { day, week, month }

class _RepeatSettings {
  const _RepeatSettings(this.every, this.period);

  final int every;
  final RepeatPeriod period;
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.database,
    this.selectedAccountId,
  });

  final BudgetDatabase database;
  final int? selectedAccountId;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _repeatEndDate;
  bool _isIncome = false;
  bool _isRepeating = false;
  int _repeatEvery = 1;
  RepeatPeriod _repeatPeriod = RepeatPeriod.month;
  Category? _selectedCategory;

  Future<void> _setDefaultCategoryForIncomeType(bool isIncome) async {
    final categories = await widget.database.watchCategories().first;
    final defaultCategoryName = isIncome ? 'Salary' : null;
    final category =
        defaultCategoryName == null
            ? null
            : categories.firstWhere(
              (item) => item.name == defaultCategoryName,
              orElse: () => categories.firstWhere(
                (item) => item.name == 'Income',
                orElse: () => categories.firstWhere(
                  (item) => item.name == 'General',
                ),
              ),
            );

    if (mounted) {
      setState(() => _selectedCategory = category);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickCategory() async {
    final categories = await widget.database.watchCategories().first;
    final category = await showModalBottomSheet<Category>(
      context: context,
      builder:
          (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Choose Category')),
                for (final item in categories)
                  ListTile(
                    leading: Icon(
                      IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                    ),
                    title: Text(item.name),
                    onTap: () => Navigator.pop(context, item),
                  ),
              ],
            ),
          ),
    );
    if (category != null) setState(() => _selectedCategory = category);
  }

  Future<void> _pickRepeatSettings() async {
    final result = await showModalBottomSheet<_RepeatSettings>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var localEvery = _repeatEvery;
        var localPeriod = _repeatPeriod;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repeat every',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final value = index + 1;
                        final selected = value == localEvery;
                        return ChoiceChip(
                          label: Text('$value'),
                          selected: selected,
                          onSelected: (_) {
                            setLocalState(() => localEvery = value);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Repeat period',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<RepeatPeriod>(
                      segments: const [
                        ButtonSegment(value: RepeatPeriod.day, label: Text('Day')),
                        ButtonSegment(value: RepeatPeriod.week, label: Text('Week')),
                        ButtonSegment(value: RepeatPeriod.month, label: Text('Month')),
                      ],
                      selected: {localPeriod},
                      onSelectionChanged: (value) {
                        setLocalState(() => localPeriod = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          _RepeatSettings(localEvery, localPeriod),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _repeatEvery = result.every;
        _repeatPeriod = result.period;
        if (_repeatEndDate == null || _repeatEndDate!.isBefore(_selectedDate)) {
          _repeatEndDate = _defaultRepeatEndDate(
            _selectedDate,
            result.period,
            result.every,
          );
        }
      });
    }
  }

  Future<void> _pickRepeatEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _repeatEndDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _repeatEndDate = pickedDate);
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (!_canSave || amount == null) return;
    final title = _selectedCategory?.name ?? 'General';
    final repeatEndDate =
        _isRepeating
            ? (_repeatEndDate ?? _defaultRepeatEndDate(_selectedDate, _repeatPeriod, _repeatEvery))
            : null;
    final accountId = widget.selectedAccountId ?? await widget.database.defaultAccountId();
    await widget.database.addTransaction(
      accountId: accountId,
      categoryId: _selectedCategory?.id,
      amountCents: (_isIncome ? amount : -amount).round() * 100,
      note:
          _notesController.text.trim().isEmpty
              ? title
              : _notesController.text.trim(),
      date: _selectedDate,
      repeatUntil: repeatEndDate,
      repeatEvery: _repeatEvery,
      repeatUnit: _repeatPeriod.name,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel = _selectedCategory?.name ?? 'Choose Category';
    final amount = double.tryParse(_amountController.text.trim());
    final canSave = amount != null && amount > 0 && _selectedCategory != null;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Transaction'),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Expense')),
              ButtonSegment(value: true, label: Text('Income')),
            ],
            selected: {_isIncome},
            onSelectionChanged: (value) async {
              final selectedIncome = value.first;
              setState(() => _isIncome = selectedIncome);
              await _setDefaultCategoryForIncomeType(selectedIncome);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Expense Detail',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 32),
          ListTile(
            tileColor: Colors.white,
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(_formatDate(_selectedDate)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: '0.00',
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.white,
            leading: Icon(
              _selectedCategory == null
                  ? Icons.coffee_outlined
                  : IconData(
                    _selectedCategory!.iconCodePoint,
                    fontFamily: 'MaterialIcons',
                  ),
            ),
            title: Text(categoryLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickCategory,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Repeating Detail',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat'),
            value: _isRepeating,
            onChanged: (value) {
              setState(() {
                _isRepeating = value;
                if (value && _repeatEndDate == null) {
                  _repeatEndDate = _defaultRepeatEndDate(
                    _selectedDate,
                    _repeatPeriod,
                    _repeatEvery,
                  );
                }
              });
            },
          ),
          if (_isRepeating) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(
                'Repeats every $_repeatEvery ${_repeatPeriod.name}${_repeatEvery == 1 ? '' : 's'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickRepeatSettings,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(
                _repeatEndDate == null
                    ? 'End Date'
                    : 'Ends on ${_formatDate(_repeatEndDate!)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickRepeatEndDate,
            ),
          ],
        ],
      ),
    );
  }

  bool get _canSave {
    final amount = double.tryParse(_amountController.text.trim());
    return amount != null && amount > 0 && _selectedCategory != null;
  }

  DateTime _defaultRepeatEndDate(
    DateTime startDate,
    RepeatPeriod period,
    int every,
  ) {
    switch (period) {
      case RepeatPeriod.day:
        return startDate.add(Duration(days: every));
      case RepeatPeriod.week:
        return startDate.add(Duration(days: every * 7));
      case RepeatPeriod.month:
        return DateTime(
          startDate.year,
          startDate.month + every,
          startDate.day,
        );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${_months[date.month - 1]}-${date.year}';

  static const _months = [
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
}
