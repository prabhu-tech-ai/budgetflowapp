import 'package:flutter/material.dart';

import '../database/budget_database.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.database});

  final BudgetDatabase database;

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
  int _repeatEveryMonths = 1;
  Category? _selectedCategory;

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
    await widget.database.addTransaction(
      accountId: await widget.database.defaultAccountId(),
      categoryId: _selectedCategory?.id,
      amountCents: (_isIncome ? amount : -amount).round() * 100,
      note:
          _notesController.text.trim().isEmpty
              ? title
              : _notesController.text.trim(),
      date: _selectedDate,
      repeatUntil: _isRepeating ? (_repeatEndDate ?? _selectedDate) : null,
      repeatEveryMonths: _repeatEveryMonths,
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
            onSelectionChanged:
                (value) => setState(() => _isIncome = value.first),
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
                  _repeatEndDate = _selectedDate;
                }
              });
            },
          ),
          if (_isRepeating) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text('Repeats every $_repeatEveryMonths month${_repeatEveryMonths == 1 ? '' : 's'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _repeatEveryMonths = _repeatEveryMonths == 1 ? 2 : 1;
                });
              },
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
