import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/scorch_mascot.dart';
import '../../data/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LiveSignupScreen extends StatefulWidget {
  const LiveSignupScreen({super.key});
  @override
  State<LiveSignupScreen> createState() => _LiveSignupScreenState();
}

class _LiveSignupScreenState extends State<LiveSignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _username = TextEditingController(),
      _email = TextEditingController(),
      _phone = TextEditingController(),
      _pin = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_name, _username, _email, _phone, _pin, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient.instance.signup(
          username: _username.text.trim(),
          displayName: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          pin: _pin.text);
      _pin.clear();
      _confirm.clear();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.page,
        appBar: AppBar(title: const Text('Create your account')),
        body: SafeArea(
            child: Form(
                key: _form,
                child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const ScorchCompanion(
                      activity: ScorchActivity.protect,
                      title: 'Start with a little spark',
                      message:
                          'Your PIN protects your wallet. Keep it just for you.'),
                  Text('Let’s get you set up', style: AppText.pageTitle),
                  const SizedBox(height: 20),
                  _field(_name, 'Full name',
                      validator: (v) => v.trim().isEmpty || v.length > 80
                          ? 'Enter your name (up to 80 characters)'
                          : null),
                  _field(_username, 'Username',
                      validator: (v) => RegExp(r'^@?[a-zA-Z0-9_.]{3,32}$')
                              .hasMatch(v.trim())
                          ? null
                          : 'Use 3–32 letters, numbers, dots or underscores'),
                  _field(_email, 'Email',
                      keyboard: TextInputType.emailAddress,
                      validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v.trim())
                          ? null
                          : 'Enter a valid email'),
                  _field(_phone, 'Phone number (+234…)',
                      keyboard: TextInputType.phone,
                      validator: (v) =>
                          RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v.trim())
                              ? null
                              : 'Include your country code'),
                  _field(_pin, 'Choose a four-digit PIN',
                      secret: true,
                      keyboard: TextInputType.number,
                      validator: (v) => RegExp(r'^\d{4}$').hasMatch(v)
                          ? null
                          : 'Enter four digits'),
                  _field(_confirm, 'Confirm your PIN',
                      secret: true,
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          v == _pin.text ? null : 'PINs must match'),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!,
                            style: TextStyle(color: AppColors.loss))),
                  PrimaryButton(
                      label: _busy ? 'Creating account…' : 'Create account',
                      onPressed: _busy ? null : _submit),
                  const SizedBox(height: 16),
                  Text('Next, verify your phone with a one-time code.',
                      style: AppText.caption),
                ])))),
      );
  Widget _field(TextEditingController controller, String label,
          {bool secret = false,
          TextInputType? keyboard,
          required String? Function(String) validator}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
              controller: controller,
              enabled: !_busy,
              obscureText: secret,
              enableSuggestions: !secret,
              autocorrect: !secret,
              keyboardType: keyboard,
              decoration: InputDecoration(labelText: label),
              validator: (value) => validator(value ?? '')));
}
