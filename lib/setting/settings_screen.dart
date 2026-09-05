import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/currency.dart';
import '../database/budget_database.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.database,
    required this.isDarkTheme,
    required this.onToggleTheme,
    required this.currencyCode,
    required this.onCurrencyChanged,
    required this.selectedAccountId,
    required this.onAccountChanged,
  });

  final BudgetDatabase database;
  final bool isDarkTheme;
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
        onTap: () => _showAccountManager(context),
      ),
      _SettingsOption(
        icon: Icons.dark_mode_outlined,
        title: 'Dark Theme',
        subtitle: 'Switch between light and dark appearance',
        trailing: Switch(
          value: isDarkTheme,
          onChanged: onToggleTheme,
        ),
        onTap: () => onToggleTheme(!isDarkTheme),
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
    final rootContext = context;
    final accounts = await database.watchAccountsWithIcons().first;
    if (!rootContext.mounted) return;

    final selected = await showModalBottomSheet<int>(
      context: rootContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accounts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (accounts.isEmpty)
                  const Text('No accounts yet'),
                for (final account in accounts)
                  ListTile(
                    leading: Icon(
                      IconData(account.iconCodePoint, fontFamily: 'MaterialIcons'),
                    ),
                    title: Text(account.name),
                    trailing:
                        account.id == selectedAccountId
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(sheetContext, account.id),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await _showAddAccountDialog(rootContext);
                      if (result == null) return;

                      final id = await database.addAccount(
                        name: result['name'] as String,
                        currency: result['currency'] as String,
                        iconCodePoint: result['iconCodePoint'] as int,
                      );

                      if (!rootContext.mounted) return;
                      Navigator.pop(rootContext, id);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!rootContext.mounted) return;
    if (selected != null) {
      onAccountChanged(selected);
    }
  }

  Future<Map<String, dynamic>?> _showAddAccountDialog(BuildContext context) async {
    final controller = TextEditingController();
    var selectedIcon = 0xe7fe;
    final icons = [0xe7fe, 0xe88a, 0xe25d, 0xe0af, 0xe8d1];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setState) {
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
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final icon in icons)
                        ChoiceChip(
                          label: Icon(
                            IconData(icon, fontFamily: 'MaterialIcons'),
                            size: 22,
                          ),
                          selected: selectedIcon == icon,
                          onSelected: (_) => setState(() => selectedIcon = icon),
                        ),
                    ],
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
                      'iconCodePoint': selectedIcon,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
