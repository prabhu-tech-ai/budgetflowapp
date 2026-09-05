import 'package:flutter/material.dart';

import '../database/budget_database.dart';

enum _EditRepeatPeriod { day, week, month }
enum _RepeatEditChoice { cancel, justThis, allFuture }

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({
    super.key,
    required this.database,
    required this.transaction,
    required this.category,
    required this.account,
  });

  final BudgetDatabase database;
  final Transaction transaction;
  final Category? category;
  final Account account;

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late bool _isIncome;
  late Category? _category;
  late int _accountId;
  late Future<List<Category>> _categories;
  late Future<List<AccountSummary>> _accounts;
  DateTime? _repeatEndDate;
  bool _isRepeating = false;
  int _repeatEvery = 1;
  _EditRepeatPeriod _repeatPeriod = _EditRepeatPeriod.month;
  late final bool _wasRepeating = widget.transaction.repeatSeriesId != null;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.transaction.amountCents.abs() / 100).toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
    _date = widget.transaction.transactionDate;
    _isIncome = widget.transaction.amountCents >= 0;
    _category = widget.category;
    _accountId = widget.transaction.accountId;
    _categories = widget.database.watchCategories().first;
    _accounts = widget.database.loadAccounts();
    _isRepeating = _wasRepeating;
    _repeatEndDate = widget.transaction.repeatUntil;
    _repeatEvery = widget.transaction.repeatEvery;
    _repeatPeriod = _parseRepeatPeriod(widget.transaction.repeatUnit);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final category = await showModalBottomSheet<Category?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Choose Category')),
            ListTile(
              title: const Text('No Category'),
              trailing: _category == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(sheetContext),
            ),
            for (final item in categories)
              ListTile(
                leading: Icon(
                  IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                ),
                title: Text(item.name),
                trailing: item.id == _category?.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, item),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _category = category);
  }

  Future<void> _pickAccount(List<AccountSummary> accounts) async {
    final account = await showModalBottomSheet<AccountSummary>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Choose Account')),
            for (final item in accounts)
              ListTile(
                title: Text(item.name),
                trailing: item.id == _accountId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, item),
              ),
          ],
        ),
      ),
    );
    if (!mounted || account == null) return;
    setState(() => _accountId = account.id);
  }

  Future<void> _pickRepeatSettings() async {
    final result = await showModalBottomSheet<({int every, _EditRepeatPeriod period})>(
      context: context,
      builder: (sheetContext) {
        var every = _repeatEvery;
        var period = _repeatPeriod;
        return StatefulBuilder(
          builder: (context, setLocalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Repeat every', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var value = 1; value <= 12; value++)
                        ChoiceChip(
                          label: Text('$value'),
                          selected: value == every,
                          onSelected: (_) => setLocalState(() => every = value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<_EditRepeatPeriod>(
                    segments: const [
                      ButtonSegment(value: _EditRepeatPeriod.day, label: Text('Day')),
                      ButtonSegment(value: _EditRepeatPeriod.week, label: Text('Week')),
                      ButtonSegment(value: _EditRepeatPeriod.month, label: Text('Month')),
                    ],
                    selected: {period},
                    onSelectionChanged: (value) => setLocalState(() => period = value.first),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, (every: every, period: period)),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() {
      _repeatEvery = result.every;
      _repeatPeriod = result.period;
      _repeatEndDate ??= _defaultRepeatEndDate(_date, _repeatPeriod, _repeatEvery);
    });
  }

  Future<void> _pickRepeatEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _repeatEndDate ?? _defaultRepeatEndDate(_date, _repeatPeriod, _repeatEvery),
      firstDate: _date,
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _repeatEndDate = date);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || _isSaving) return;
    var repeatChoice = _RepeatEditChoice.justThis;
    if (_wasRepeating) {
      repeatChoice = await _showRepeatEditDialog();
      if (!mounted || repeatChoice == _RepeatEditChoice.cancel) return;
    }
    setState(() => _isSaving = true);
    try {
      final repeatSeriesId = widget.transaction.repeatSeriesId ??
          (_isRepeating ? DateTime.now().microsecondsSinceEpoch : null);
      final repeatUntil = _isRepeating ? _repeatEndDate : null;
      await widget.database.updateTransaction(
        id: widget.transaction.id,
        accountId: _accountId,
        categoryId: _category?.id,
        amountCents: ((_isIncome ? amount : -amount) * 100).round(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _date,
        repeatSeriesId: repeatSeriesId,
        repeatUntil: repeatUntil,
        repeatEvery: _repeatEvery,
        repeatUnit: _repeatPeriod.name,
      );
      if (repeatChoice == _RepeatEditChoice.allFuture &&
          repeatSeriesId != null) {
        await widget.database.updateFutureTransactions(
          repeatSeriesId: repeatSeriesId,
          fromDate: _date,
          accountId: _accountId,
          categoryId: _category?.id,
          amountCents: ((_isIncome ? amount : -amount) * 100).round(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          repeatUntil: repeatUntil,
          repeatEvery: _repeatEvery,
          repeatUnit: _repeatPeriod.name,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update transaction: $error')),
      );
    }
  }

  Future<_RepeatEditChoice> _showRepeatEditDialog() async {
    return await showDialog<_RepeatEditChoice>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('This is a repeating transaction'),
            content: const Text(
              'Choose whether you want to update just this occurrence, or this and all future occurrences.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, _RepeatEditChoice.cancel),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, _RepeatEditChoice.justThis),
                child: const Text('Just This'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, _RepeatEditChoice.allFuture),
                child: const Text('All Future'),
              ),
            ],
          ),
        ) ??
        _RepeatEditChoice.cancel;
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          TextButton(
            onPressed: amount != null && amount > 0 && !_isSaving ? _save : null,
            child: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Expense')),
              ButtonSegment(value: true, label: Text('Income')),
            ],
            selected: {_isIncome},
            onSelectionChanged: (value) =>
                setState(() => _isIncome = value.first),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(_formatDate(_date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          TextField(
            controller: _amountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<Category>>(
            future: _categories,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const <Category>[];
              return ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(_category?.name ?? 'No Category'),
                trailing: const Icon(Icons.chevron_right),
                onTap: categories.isEmpty ? null : () => _pickCategory(categories),
              );
            },
          ),
          FutureBuilder<List<AccountSummary>>(
            future: _accounts,
            builder: (context, snapshot) {
              final accounts = snapshot.data ?? const <AccountSummary>[];
              final account = accounts.where((item) => item.id == _accountId).firstOrNull;
              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(account?.name ?? widget.account.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: accounts.isEmpty ? null : () => _pickAccount(accounts),
              );
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat'),
            value: _isRepeating,
            onChanged: (value) {
              setState(() {
                _isRepeating = value;
                if (value) {
                  _repeatEndDate ??= _defaultRepeatEndDate(_date, _repeatPeriod, _repeatEvery);
                }
              });
            },
          ),
          if (_isRepeating) ...[
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text('Repeats every $_repeatEvery ${_repeatPeriod.name}${_repeatEvery == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickRepeatSettings,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(_repeatEndDate == null ? 'End Date' : 'Ends on ${_formatDate(_repeatEndDate!)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickRepeatEndDate,
            ),
          ],
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes_outlined),
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${_months[date.month - 1]}-${date.year}';

  DateTime _advanceDate(DateTime date, int every, _EditRepeatPeriod period) {
    switch (period) {
      case _EditRepeatPeriod.day:
        return date.add(Duration(days: every));
      case _EditRepeatPeriod.week:
        return date.add(Duration(days: every * 7));
      case _EditRepeatPeriod.month:
        final monthIndex = date.month - 1 + every;
        final year = date.year + monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        final day = date.day;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        return DateTime(year, month, day > daysInMonth ? daysInMonth : day);
    }
  }

  DateTime _defaultRepeatEndDate(DateTime date, _EditRepeatPeriod period, int every) =>
      _advanceDate(date, every, period);

  _EditRepeatPeriod _parseRepeatPeriod(String value) {
    return switch (value) {
      'day' => _EditRepeatPeriod.day,
      'week' => _EditRepeatPeriod.week,
      _ => _EditRepeatPeriod.month,
    };
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
