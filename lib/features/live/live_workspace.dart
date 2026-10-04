import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_routes.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/scorch_mascot.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Live workspace only consumes server snapshots. The demo repository and its
/// seeded balances, timers and simulated providers are never instantiated here.
class LiveWorkspace extends StatefulWidget {
  const LiveWorkspace({super.key});
  @override
  State<LiveWorkspace> createState() => _LiveWorkspaceState();
}

class _LiveWorkspaceState extends State<LiveWorkspace>
    with WidgetsBindingObserver {
  final _api = ApiClient.instance;
  Map<String, dynamic>? _user, _wallet, _pending;
  String? _error;
  bool _busy = false;
  final _otp = TextEditingController();
  String get _pendingKey => 'scorchepay_live_pending_${_user!['id']}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otp.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await _api.me();
      if (!mounted) return;
      _user = user;
      if (user['phone_verified'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString(_pendingKey);
        _pending = stored == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(stored) as Map);
        if (_pending != null) {
          final operation = await _api.operation(_pending!['id'] as String);
          if (operation['status'] == 'completed' ||
              operation['status'] == 'failed') {
            await prefs.remove(_pendingKey);
            _pending = null;
          }
        }
        _wallet = await _api.wallet();
      }
    } catch (error) {
      if (mounted) _error = error.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify({bool resend = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (resend) {
        await _api.resendOtp();
      } else {
        await _api.verifyOtp(
            phone: _user!['phone'] as String, code: _otp.text.trim());
      }
    } catch (error) {
      if (mounted) _error = error.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && !resend && _error == null) await _refresh();
    if (mounted && resend && _error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification code sent')));
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false);
    }
  }

  Future<void> _send() async {
    if (_busy || _user == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LiveTransferScreen(
            userId: _user!['id'] as String, pending: _pending)));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final verified = _user?['phone_verified'] == true;
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(title: const Text('ScorchePay'), actions: [
        IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded)),
        IconButton(
            tooltip: 'Log out',
            onPressed: _busy ? null : _logout,
            icon: const Icon(Icons.logout_rounded))
      ]),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(padding: const EdgeInsets.all(22), children: [
                ScorchCompanion(
                    activity: verified
                        ? ScorchActivity.wallet
                        : ScorchActivity.protect,
                    title: verified
                        ? 'Hello, ${_user!['display_name']}'
                        : 'A safer start',
                    message: verified
                        ? 'Your wallet, with every move accounted for.'
                        : 'Verify your number to unlock your wallet.'),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(_error!,
                          style: TextStyle(color: AppColors.loss))),
                if (_user == null && !_busy)
                  PrimaryButton(label: 'Try again', onPressed: _refresh),
                if (_user != null && !verified) ...[
                  Text('Verify your phone', style: AppText.pageTitle),
                  const SizedBox(height: 8),
                  Text(
                      'Enter the code sent to ${_user!['phone']}. If it has not arrived, request another code.',
                      style: AppText.bodyMuted),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                          labelText: 'Verification code')),
                  PrimaryButton(
                      label: 'Verify',
                      onPressed: _busy ? null : () => _verify()),
                  TextButton(
                      onPressed: _busy ? null : () => _verify(resend: true),
                      child: const Text('Send another code')),
                ],
                if (verified) ...[
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(24)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _error == null
                                    ? 'Available balance · NGN'
                                    : 'Last loaded balance · refresh needed',
                                style: AppText.caption),
                            const SizedBox(height: 12),
                            Text(
                                _wallet == null
                                    ? '—'
                                    : _money(
                                        (_wallet!['balances'] as Map)['NGN']
                                                ?.toString() ??
                                            '0'),
                                style:
                                    AppText.pageTitle.copyWith(fontSize: 32)),
                            const SizedBox(height: 20),
                            PrimaryButton(
                                label: _pending != null
                                    ? 'Review pending transfer'
                                    : 'Send money',
                                onPressed:
                                    _busy || _wallet == null || _error != null
                                        ? null
                                        : _send),
                          ])),
                  if (_pending != null) ...[
                    const SizedBox(height: 16),
                    Text('Transfer awaiting confirmation',
                        style: AppText.cardTitle),
                    Text(
                        'Reference: ${_pending!['id']}. Check its status before sending again.',
                        style: AppText.bodyMuted),
                    TextButton(
                        onPressed: _busy ? null : _send,
                        child: const Text('Check transfer')),
                  ],
                  const SizedBox(height: 28),
                  Text('Recent activity', style: AppText.sectionTitle),
                  if (_wallet != null && (_wallet!['ledger'] as List).isEmpty)
                    const ScorchCompanion(
                        activity: ScorchActivity.explore,
                        title: 'A fresh start',
                        message:
                            'Your confirmed wallet activity will appear here.'),
                  for (final entry in (_wallet?['ledger'] as List? ?? []))
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                            entry['amount'].toString().startsWith('-')
                                ? Icons.north_east
                                : Icons.south_west,
                            color: AppColors.accent),
                        title: Text(entry['title'] as String),
                        subtitle:
                            Text('${entry['status']} · ${entry['currency']}'),
                        trailing: Text(_money(entry['amount'].toString()))),
                  for (final operation
                      in (_wallet?['operations'] as List? ?? [])
                          .where((entry) => entry['status'] == 'failed'))
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Transfer not completed'),
                        subtitle: Text(
                            '${operation['error']}\nReference: ${operation['id']}')),
                  const SizedBox(height: 24),
                  Text('More is on the way', style: AppText.cardTitle),
                  const SizedBox(height: 8),
                  Text(
                      'Deposits, bills, crypto and savings will appear here when they are ready for your account.',
                      style: AppText.bodyMuted),
                ],
              ]))),
    );
  }
}

String _money(String decimal) {
  final parts = decimal.split('.');
  final fraction =
      parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
  return '${parts[0]}.$fraction';
}

class LiveTransferScreen extends StatefulWidget {
  const LiveTransferScreen({super.key, required this.userId, this.pending});
  final String userId;
  final Map<String, dynamic>? pending;
  @override
  State<LiveTransferScreen> createState() => _LiveTransferScreenState();
}

class _LiveTransferScreenState extends State<LiveTransferScreen> {
  final _api = ApiClient.instance;
  final _recipient = TextEditingController(),
      _amount = TextEditingController(),
      _note = TextEditingController(),
      _pin = TextEditingController();
  Map<String, dynamic>? _resolved, _operation, _request;
  String? _error;
  bool _busy = false;
  String get _key => 'scorchepay_live_pending_${widget.userId}';
  bool get _finished =>
      _operation?['status'] == 'completed' || _operation?['status'] == 'failed';
  @override
  void initState() {
    super.initState();
    _request = widget.pending;
    if (_request != null) _check();
  }

  @override
  void dispose() {
    for (final controller in [_recipient, _amount, _note, _pin]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _busy = true;
      _error = null;
      _resolved = null;
    });
    try {
      _resolved = await _api.resolveRecipient(_recipient.text.trim());
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    if (_busy || _request == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _accept(await _api.operation(_request!['id'] as String));
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(Map<String, dynamic> operation) async {
    _operation = operation;
    if (_finished) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!RegExp(r'^\d{4}$').hasMatch(_pin.text)) {
      setState(() => _error = 'Enter your four-digit PIN');
      return;
    }
    if (_request == null &&
        (!RegExp(r'^(0|[1-9]\d{0,11})(\.\d{1,2})?$')
                .hasMatch(_amount.text.trim()) ||
            RegExp(r'^0(\.0{1,2})?$').hasMatch(_amount.text.trim()))) {
      setState(() => _error =
          'Enter a positive NGN amount with at most two decimal places');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = _request ??
          {
            'id': _api.newOperationId(),
            'toUsername': _resolved!['username'],
            'recipient': _resolved!['display_name'],
            'amount': _amount.text.trim(),
            'currency': 'NGN',
            'note': _note.text.trim()
          };
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key, jsonEncode(request))) {
        throw const ApiRequestException('Could not save the transfer reference. Nothing was submitted.');
      }
      _request = request;
      final result = await _api.sendMoney(
          toUsername: request['toUsername'] as String,
          currency: 'NGN',
          amount: request['amount'] as String,
          pin: _pin.text,
          operationId: request['id'] as String,
          note: request['note'] as String?);
      await _accept(result);
    } catch (error) {
      _error = error.toString();
    } finally {
      _pin.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final success = _operation?['status'] == 'completed';
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: AppColors.page,
          appBar: AppBar(
              title: Text(_finished ? 'Transfer receipt' : 'Send money')),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(22), children: [
            Center(
                child: ScorchMascot(
                    activity: _busy
                        ? ScorchActivity.processing
                        : success
                            ? ScorchActivity.celebrate
                            : _finished
                                ? ScorchActivity.rest
                                : ScorchActivity.pay,
                    size: 155)),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child:
                      Text(_error!, style: TextStyle(color: AppColors.loss))),
            if (_finished) ...[
              Text(success ? 'Money sent' : 'Transfer not completed',
                  style: AppText.pageTitle),
              const SizedBox(height: 12),
              Text(
                  '${_operation!['amount']} NGN to ${_operation!['recipient']}',
                  style: AppText.body),
              if (!success)
                Text(_operation!['error'] as String? ?? 'No funds moved',
                    style: AppText.bodyMuted),
              const SizedBox(height: 12),
              SelectableText('Reference: ${_operation!['id']}',
                  style: AppText.caption),
              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'Done', onPressed: () => Navigator.of(context).pop()),
            ] else ...[
              if (_request == null) ...[
                TextField(
                    controller: _recipient,
                    enabled: !_busy,
                    decoration:
                        const InputDecoration(labelText: 'Recipient username'),
                    onChanged: (_) => setState(() => _resolved = null)),
                TextButton(
                    onPressed: _busy ? null : _resolve,
                    child: const Text('Find recipient')),
                if (_resolved != null) ...[
                  Text('Sending to ${_resolved!['display_name']}',
                      style: AppText.cardTitle),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _amount,
                      enabled: !_busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Amount', suffixText: 'NGN')),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _note,
                      enabled: !_busy,
                      maxLength: 200,
                      decoration:
                          const InputDecoration(labelText: 'Note (optional)')),
                  Text(
                      'Fee: 0.00 NGN · Check the recipient and amount before confirming.',
                      style: AppText.caption),
                ],
              ] else ...[
                Text('Awaiting confirmation', style: AppText.pageTitle),
                const SizedBox(height: 8),
                Text('${_request!['amount']} NGN to ${_request!['recipient']}',
                    style: AppText.body),
                const SizedBox(height: 8),
                SelectableText('Reference: ${_request!['id']}',
                    style: AppText.caption),
                const SizedBox(height: 12),
                Text(
                    'The result is not confirmed yet. Check its status or resume this same transfer. Your saved reference prevents a duplicate payment.',
                    style: AppText.bodyMuted),
                TextButton(
                    onPressed: _busy ? null : _check,
                    child: const Text('Check status')),
              ],
              if (_resolved != null || _request != null) ...[
                const SizedBox(height: 20),
                TextField(
                    controller: _pin,
                    enabled: !_busy,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        labelText: 'Confirm with your PIN')),
                PrimaryButton(
                    label: _request == null
                        ? 'Confirm transfer'
                        : 'Resume same transfer',
                    onPressed: _busy ? null : _submit),
              ],
            ],
          ])),
        ));
  }
}
