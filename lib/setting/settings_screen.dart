import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/currency.dart';
import '../core/utils.dart';
import '../database/budget_database.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.database,
    required this.themeMode,
    required this.onToggleTheme,
    required this.currencyCode,
    required this.onCurrencyChanged,
    required this.selectedAccountId,
    required this.onAccountChanged,
  });

  final BudgetDatabase database;
  final ThemeMode themeMode;
  final ValueChanged<bool> onToggleTheme;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final int? selectedAccountId;
  final ValueChanged<int?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      _SettingsOption(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Add/Manage Account',
        subtitle:
            selectedAccountId == null
                ? 'No account selected'
                : 'Selected account: $selectedAccountId',
        onTap: () {
          debugPrint('Add/Manage Account tapped');
          _showAccountManager(context);
        },
      ),
      _SettingsOption(
        icon: Icons.dark_mode_outlined,
        title: 'Theme',
        subtitle: themeMode == ThemeMode.system
            ? 'System default'
            : themeMode == ThemeMode.dark
                ? 'Dark mode'
                : 'Light mode',
        trailing: Switch(
          value: themeMode == ThemeMode.dark ||
              (themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark),
          onChanged: onToggleTheme,
        ),
        onTap: () => onToggleTheme(themeMode != ThemeMode.dark),
      ),
      _SettingsOption(
        icon: Icons.currency_rupee_outlined,
        title: 'Currency',
        subtitle: '$currencyCode • ${currencyDisplayName(currencyCode)}',
        onTap: () => _showCurrencyPicker(context),
      ),
      _SettingsOption(
        icon: Icons.share_outlined,
        title: 'Share App',
        subtitle: 'Share with friends and family',
        onTap: () => _shareApp(context),
      ),
      _SettingsOption(
        icon: Icons.feedback_outlined,
        title: 'Send Feedback',
        subtitle: 'Tell us what you think',
        onTap: () => _openFeedback(context),
      ),
      _SettingsOption(
        icon: Icons.star_outline,
        title: 'Rate App',
        subtitle: 'Leave a rating in the store',
        onTap: () => _rateApp(context),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Settings'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final option = options[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Icon(option.icon, size: 28),
            title: Text(option.title),
            subtitle: option.subtitle == null ? null : Text(option.subtitle!),
            trailing: option.trailing,
            onTap: option.onTap,
          );
        },
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(
      'Try BudgetFlow, a simple app for tracking income and expenses.',
      subject: 'BudgetFlow',
    );
  }

  Future<void> _openFeedback(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final storeUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.example.budgetflow',
    );
    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the app store')),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Select Currency')),
              for (final code in supportedCurrencyCodes)
                ListTile(
                  title: Text('$code • ${currencyDisplayName(code)}'),
                  trailing:
                      code == currencyCode ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, code),
                ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != currencyCode) {
      onCurrencyChanged(selected);
    }
  }

  Future<void> _showAccountManager(BuildContext context) async {
    final accounts = await database.loadAccounts();
    if (!context.mounted) return;

    final selected = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => _AccountManagerScreen(
          database: database,
          initialAccounts: accounts,
          onAccountChanged: onAccountChanged,
        ),
      ),
    );

    if (!context.mounted) return;
    if (selected != null) {
      onAccountChanged(selected);
    }
  }

}

class _AccountManagerScreen extends StatefulWidget {
  const _AccountManagerScreen({
    required this.database,
    required this.initialAccounts,
    required this.onAccountChanged,
  });

  final BudgetDatabase database;
  final List<AccountSummary> initialAccounts;
  final ValueChanged<int?> onAccountChanged;

  @override
  State<_AccountManagerScreen> createState() => _AccountManagerScreenState();
}

class _AccountManagerScreenState extends State<_AccountManagerScreen> {
  late List<AccountSummary> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = widget.initialAccounts;
  }

  Future<void> _refreshAccounts() async {
    final accounts = await widget.database.loadAccounts();
    if (!mounted) return;
    setState(() => _accounts = accounts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_accounts.isEmpty)
              const Text('No accounts yet')
            else
              Expanded(
                child: ListView(
                  children: [
                    for (final account in _accounts)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(account.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: account.isDefault
                                  ? 'Default account'
                                  : 'Set as default',
                              icon: Icon(
                                account.isDefault
                                    ? Icons.star
                                    : Icons.star_border,
                              ),
                              onPressed: () async {
                                await widget.database.setDefaultAccount(account.id);
                                await _refreshAccounts();
                                if (!mounted) return;
                                Navigator.of(context).pop(account.id);
                              },
                            ),
                            IconButton(
                              tooltip: 'Edit account',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                final newName = await _showEditAccountDialog(
                                  context,
                                  account.name,
                                );
                                if (newName == null) return;
                                await widget.database.updateAccountName(
                                  id: account.id,
                                  name: newName,
                                );
                                await _refreshAccounts();
                              },
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(account.id),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await _showAddAccountDialog(context);
                  if (result == null) return;

                  final id = await widget.database.addAccount(
                    name: result['name'] as String,
                    currency: result['currency'] as String,
                    iconCodePoint: result['iconCodePoint'] as int,
                  );

                  await _refreshAccounts();
                  if (!mounted) return;
                  Navigator.of(context).pop(id);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAddAccountDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  hintText: 'Cash, Bank, Savings',
                ),
              ),
              const SizedBox(height: 16),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_outline),
                title: Text('Account icon'),
                subtitle: Text('Multi-user icon'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext, {
                  'name': name,
                  'currency': 'INR',
                  'iconCodePoint': AppUtils.singleAccountIconCodePoint,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showEditAccountDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Account Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Account name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.length < 2) return;
              Navigator.pop(dialogContext, name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'prabhu.tech.ai@gmail.com',
      queryParameters: {
        'subject': 'BudgetFlow feedback',
        'body': comment,
      },
    );
    try {
      if (!await canLaunchUrl(emailUri)) {
        throw StateError('No email app is available');
      }
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open email: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendFeedback,
            child: Text(_isSending ? 'Opening...' : 'Send'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Your feedback',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            autofocus: true,
            minLines: 6,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write your comment',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}

class _SettingsOption {
  const _SettingsOption({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
}
