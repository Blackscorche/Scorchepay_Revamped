import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_env_vars.dart';
import '../../core/formatters.dart';
import '../models/kyc.dart';
import '../models/vtu.dart';
import 'mock_lightning.dart';
import 'shared_prefs_keys.dart';
import 'vtu_api.dart';

/// How [MockVtuApi] behaves, switchable from the debug menu.
enum MockScenario {
  success('Success', 'Orders are paid and fulfilled.'),
  billFails('Bill fails',
      "The provider fails; the payment goes back to the wallet by itself."),
  billNeedsReview('Bill needs review',
      'The provider fails unclearly; after review the user claims a refund.'),
  quoteExpires('Quote expires fast', 'Quotes last 20 seconds instead of 2 minutes.'),
  serverDown('Server down', 'Every request fails as if offline.');

  const MockScenario(this.label, this.description);
  final String label;
  final String description;
}

/// The whole backend on the device, for development without a server:
/// accounts, KYC and bills, following the same contract as the real API
/// (docs/VTU.md). Bills come from a Nigerian catalog, and orders move
/// through their states on a clock: a mock wallet's payment
/// ([MockLightning]) marks an order paid, and it completes (or, in
/// [MockScenario.billFails], is refunded) a few seconds later.
///
/// Accounts and orders persist in shared preferences, so they survive a
/// restart. Everything else the "server" holds (sign-up codes, passkey
/// challenges) is shared by every instance in memory, so a new instance
/// (after signing in, or switching scenario) carries on where the last
/// one left off.
class MockVtuApi implements VtuApi {
  MockVtuApi({required this.token, required this.scenario}) {
    // Payments update the shared orders, so one static listener serves
    // every instance (adding it again is a no-op) and lives as long as
    // the "server": nothing to remove when an instance goes away.
    MockLightning.addListener(_onPayment);
  }

  @override
  final String? token;
  final MockScenario scenario;

  /// The demo account the mock always has.
  static const demoUsername = 'scorche';
  static const demoPin = '1234';

  /// The mock accepts this code for every sign-up OTP.
  static const demoOtp = '123456';

  /// Passkey relying party ID: the domain that hosts the app association
  /// files (see docs/PASSKEYS.md). Set it per build with
  /// `--dart-define=PASSKEY_RP_ID=example.com`. A real backend owns this
  /// setting.
  ///
  /// On web, browsers require it to be the page's host (or a parent
  /// domain of it), so without the define it falls back to the host,
  /// e.g. `localhost` in development. Elsewhere, no define means passkeys
  /// stay off.
  static String get passkeyRpId {
    const configured = String.fromEnvironment(AppEnvVars.passkeyRpId);
    if (configured.isNotEmpty) return configured;
    return kIsWeb ? Uri.base.host : '';
  }

  @override
  ApiFeatures get features => ApiFeatures(
        passkeys: passkeyRpId.isNotEmpty,
        profilePhotos: true,
        simulatePayments: true,
        mockScenarios: true,
        debugLogin: (username: demoUsername, pin: demoPin),
        debugSignUpCode: demoOtp,
      );

  static final _server = _MockServer();

  static const _latency = Duration(milliseconds: 300);
  static const _tokenPrefix = 'mock-token-';

  // Account IDs never change (usernames can), so tokens are built from
  // them.
  static const _demoAccountId = demoUsername;

  /// Prices and limits are in naira (the only catalog so far).
  static const _currency = 'NGN';

  /// NGN per BTC before the spread. Real quotes come from the rates service.
  static const _ngnPerBtc = 165000000.0;
  static const _spread = 0.015;

  /// Settles [orderId]'s invoice as if a wallet paid it, for testing with
  /// a real wallet that can't pay a mock invoice.
  @override
  Future<void> simulatePayment(String orderId) async {
    final order = (await _orders())[orderId];
    if (order != null) MockLightning.pay(order.base.invoice);
  }

  // ---------------------------------------------------------------------
  // Session and profile
  // ---------------------------------------------------------------------

  @override
  Future<String> login(String username, String pin) async {
    await Future.delayed(_latency);
    final accounts = await _db();
    final name = _normalizeUsername(username);
    // A username is always required, like the real API. (Debug builds fill
    // in [demoUsername] for a blank one, in the app.)
    final account =
        accounts.values.where((a) => a.username == name).firstOrNull;
    if (account == null) throw const AuthException('Unknown user.');
    if (pin != account.pin) throw const AuthException('Incorrect PIN.');
    return '$_tokenPrefix${account.id}';
  }

  @override
  Future<ApiUser> getMe() async {
    await Future.delayed(_latency);
    return (await _sessionAccount()).toUser();
  }

  @override
  Future<ApiUser> updateMe({String? username, String? displayName}) async {
    await Future.delayed(_latency);
    final account = await _sessionAccount();
    if (username != null) {
      final name = _validUsername(username);
      if (name != account.username) await _ensureUsernameFree(name);
      account.username = name;
    }
    if (displayName != null) {
      final name = displayName.trim();
      if (name.isEmpty) throw const AuthException('Enter your name.');
      account.displayName = name;
    }
    await _saveAccounts();
    return account.toUser();
  }

  // ---------------------------------------------------------------------
  // Identity verification: approves Tier 1 about 2 seconds after starting,
  // like the backend's development KYC provider. There's no page to open.
  // ---------------------------------------------------------------------

  @override
  Future<KycSession> startIdentityVerification() async {
    await Future.delayed(_latency);
    final account = await _sessionAccount();
    if (account.kyc.tier >= 1) {
      return const KycSession(status: KycStatus.verified);
    }
    account.kyc = KycInfo(tier: account.kyc.tier, status: KycStatus.pending);
    await _saveAccounts();
    unawaited(Future.delayed(const Duration(seconds: 2), () async {
      account.kyc = const KycInfo(tier: 1, status: KycStatus.verified);
      await _saveAccounts();
    }));
    return const KycSession(status: KycStatus.pending);
  }

  // ---------------------------------------------------------------------
  // Profile photo
  // ---------------------------------------------------------------------
  //
  // A real backend stores the image and returns a URL the app can GET. The
  // mock keeps it in shared preferences under its own key and hands out
  // `mock-photo://` URLs that only [loadPhoto] understands.

  static const _maxPhotoBytes = 5 * 1024 * 1024;
  static const _photoUrlScheme = 'mock-photo';

  /// The photo's type comes from the bytes themselves (see
  /// [_imageContentType]), not from the client.
  @override
  Future<String> uploadPhoto(Uint8List photo) async {
    await Future.delayed(_latency);
    final account = await _sessionAccount();
    if (photo.isEmpty || photo.length > _maxPhotoBytes) {
      throw const AuthException('Photos must be smaller than 5 MB.');
    }
    final contentType = _imageContentType(photo);
    if (contentType == null) {
      throw const AuthException('Use a JPEG, PNG, WebP, HEIC or GIF photo.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        SharedPrefsKeys.mockBackendPhoto(account.id), base64Encode(photo));
    // A new URL per upload, so cached copies of the old photo aren't reused.
    final url = '$_photoUrlScheme://${account.id}/${_randomId()}';
    account
      ..photoUrl = url
      // Kept to serve the photo with the right Content-Type; the mock's
      // loadProfilePhoto returns bytes only, so it isn't read back here.
      ..photoContentType = contentType;
    await _saveAccounts();
    return url;
  }

  /// The image type from the file's signature ("magic") bytes, or null if
  /// it isn't one of the accepted types.
  static String? _imageContentType(Uint8List bytes) {
    bool startsWith(List<int> prefix, [int offset = 0]) {
      if (bytes.length < offset + prefix.length) return false;
      for (var i = 0; i < prefix.length; i++) {
        if (bytes[offset + i] != prefix[i]) return false;
      }
      return true;
    }

    String ascii(int offset, int length) => bytes.length < offset + length
        ? ''
        : String.fromCharCodes(bytes.sublist(offset, offset + length));

    if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }
    final gif = ascii(0, 6);
    if (gif == 'GIF87a' || gif == 'GIF89a') return 'image/gif';
    if (ascii(0, 4) == 'RIFF' && ascii(8, 4) == 'WEBP') return 'image/webp';
    // HEIC/HEIF: an ISO-BMFF "ftyp" box with a HEIF brand.
    const heifBrands = {
      'heic',
      'heix',
      'hevc',
      'hevx',
      'heim',
      'heis',
      'mif1',
      'msf1'
    };
    if (ascii(4, 4) == 'ftyp' && heifBrands.contains(ascii(8, 4))) {
      return 'image/heic';
    }
    return null;
  }

  @override
  Future<void> deletePhoto() async {
    await Future.delayed(_latency);
    final account = await _sessionAccount();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPrefsKeys.mockBackendPhoto(account.id));
    account
      ..photoUrl = null
      ..photoContentType = null;
    await _saveAccounts();
  }

  /// Serves the mock's `mock-photo://` URLs.
  @override
  Future<Uint8List> loadPhoto(String photoUrl) async {
    await Future.delayed(_latency);
    final uri = Uri.tryParse(photoUrl);
    final accounts = await _db();
    final account = uri?.scheme == _photoUrlScheme ? accounts[uri!.host] : null;
    final prefs = await SharedPreferences.getInstance();
    final encoded = account?.photoUrl == photoUrl
        ? prefs.getString(SharedPrefsKeys.mockBackendPhoto(account!.id))
        : null;
    if (encoded == null) {
      throw const AuthException('Photo not found.');
    }
    return base64Decode(encoded);
  }

  // ---------------------------------------------------------------------
  // Passkeys: the backend is the WebAuthn relying party
  // ---------------------------------------------------------------------
  //
  // The app passes these JSON strings to the passkeys package and sends
  // back what it returns, so they follow the WebAuthn JSON format.
  //
  // MOCK ONLY: this checks the challenge and the credential ID but does
  // not verify the attestation or the assertion signature (that needs the
  // credential's public key and COSE/CBOR parsing). The real backend must
  // use a WebAuthn library for that, e.g. webauthn-rs in Rust.

  @override
  Future<String> startPasskeyRegistration() async {
    await Future.delayed(_latency);
    _requirePasskeys();
    final account = await _sessionAccount();
    final challenge =
        _newPasskeyChallenge(type: 'webauthn.create', accountId: account.id);
    return jsonEncode({
      'challenge': challenge,
      'rp': {'id': passkeyRpId, 'name': 'ScorchePay'},
      'user': {
        'id': _base64Url(utf8.encode(account.id)),
        'name': account.username,
        'displayName': account.displayName,
      },
      'pubKeyCredParams': [
        {'type': 'public-key', 'alg': -7}, // ES256
        {'type': 'public-key', 'alg': -257}, // RS256
      ],
      'timeout': 60000,
      'authenticatorSelection': {
        'authenticatorAttachment': 'platform',
        'residentKey': 'required',
        'requireResidentKey': true,
        'userVerification': 'required',
      },
      'attestation': 'none',
      'excludeCredentials': [
        for (final id in account.passkeyIds)
          {
            'type': 'public-key',
            'id': id,
            'transports': ['internal', 'hybrid'],
          },
      ],
    });
  }

  @override
  Future<void> finishPasskeyRegistration(String credentialJson) async {
    await Future.delayed(_latency);
    final account = await _sessionAccount();
    final credential = _decodeCredential(credentialJson);
    _consumePasskeyChallenge(credential,
        type: 'webauthn.create', accountId: account.id);
    final accounts = await _db();
    if (accounts.values.any((a) => a.passkeyIds.contains(credential.id))) {
      throw const AuthException('This passkey is already registered.');
    }
    account.passkeyIds.add(credential.id);
    await _saveAccounts();
  }

  /// No username needed: the device offers its ScorchePay passkeys
  /// (discoverable credentials).
  @override
  Future<String> startPasskeyLogin() async {
    await Future.delayed(_latency);
    _requirePasskeys();
    return jsonEncode({
      'challenge': _newPasskeyChallenge(type: 'webauthn.get'),
      'rpId': passkeyRpId,
      'timeout': 60000,
      'userVerification': 'required',
      'allowCredentials': <Object>[],
    });
  }

  @override
  Future<String> finishPasskeyLogin(String credentialJson) async {
    await Future.delayed(_latency);
    final credential = _decodeCredential(credentialJson);
    _consumePasskeyChallenge(credential, type: 'webauthn.get');
    final accounts = await _db();
    final account = accounts.values
        .where((a) => a.passkeyIds.contains(credential.id))
        .firstOrNull;
    if (account == null) {
      throw const AuthException(
          "This passkey isn't linked to a ScorchePay account. Log in with your PIN.");
    }
    final userHandle = credential.userHandle;
    if (userHandle != null &&
        userHandle.isNotEmpty &&
        userHandle != _base64Url(utf8.encode(account.id))) {
      throw const AuthException("This passkey couldn't be verified.");
    }
    return '$_tokenPrefix${account.id}';
  }

  void _requirePasskeys() {
    if (passkeyRpId.isEmpty) {
      throw const AuthException("Passkeys aren't set up for this app yet.");
    }
  }

  String _newPasskeyChallenge({required String type, String? accountId}) {
    final now = DateTime.now();
    _server.passkeyChallenges.removeWhere((_, c) => c.expiresAt.isBefore(now));
    final challenge =
        _base64Url(List.generate(32, (_) => _server.secureRandom.nextInt(256)));
    _server.passkeyChallenges[challenge] = _PasskeyChallenge(
        type: type,
        accountId: accountId,
        expiresAt: now.add(const Duration(minutes: 2)));
    return challenge;
  }

  /// Checks the client data against a challenge this backend issued, and
  /// uses the challenge up.
  void _consumePasskeyChallenge(_PasskeyCredential credential,
      {required String type, String? accountId}) {
    const expired =
        AuthException('This passkey request has expired. Please try again.');
    if (credential.clientType != type) throw expired;
    final issued = _server.passkeyChallenges.remove(credential.challenge);
    if (issued == null ||
        issued.type != type ||
        issued.accountId != accountId ||
        issued.expiresAt.isBefore(DateTime.now())) {
      throw expired;
    }
  }

  static _PasskeyCredential _decodeCredential(String credentialJson) {
    try {
      final json = jsonDecode(credentialJson) as Map<String, dynamic>;
      final response = json['response'] as Map<String, dynamic>;
      final clientData = jsonDecode(utf8.decode(base64Url.decode(
              base64Url.normalize(response['clientDataJSON'] as String))))
          as Map<String, dynamic>;
      return _PasskeyCredential(
        id: json['id'] as String,
        clientType: clientData['type'] as String?,
        challenge: clientData['challenge'] as String?,
        userHandle: response['userHandle'] as String?,
      );
    } catch (_) {
      throw const AuthException("This passkey response couldn't be read.");
    }
  }

  /// Base64url without padding, as WebAuthn uses.
  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  // ---------------------------------------------------------------------
  // Sign-up: verify the contact first, create the account last
  // ---------------------------------------------------------------------

  /// Sends a sign-up OTP to [contact] (a phone number or email) and
  /// returns the ID of that challenge. Rejects invalid or already
  /// registered contacts. Calling it again for the same contact replaces
  /// the earlier code (resend).
  @override
  Future<String> requestSignUpCode(String contact) async {
    await Future.delayed(_latency);
    final normalized = _normalizeContact(contact);
    if (normalized == null) {
      throw const AuthException('Enter a valid phone number or email.');
    }
    final accounts = await _db();
    if (accounts.values.any((a) => a.contact == normalized)) {
      throw const AuthException(
          'An account already uses this phone number or email. Log in instead.');
    }
    _server.challenges.removeWhere((_, c) => c.contact == normalized);
    final id = _randomId();
    _server.challenges[id] = _OtpChallenge(
        contact: normalized,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)));
    return id;
  }

  /// Checks [code] against the challenge [verificationId]. Returns a
  /// sign-up token proving the contact is verified, for [signUp].
  @override
  Future<String> verifySignUpCode(String verificationId, String code) async {
    await Future.delayed(_latency);
    final challenge = _server.challenges[verificationId];
    if (challenge == null || challenge.expiresAt.isBefore(DateTime.now())) {
      throw const AuthException('This code has expired. Request a new one.');
    }
    if (challenge.attempts >= 5) {
      throw const AuthException('Too many attempts. Request a new code.');
    }
    if (code != demoOtp) {
      challenge.attempts++;
      throw const AuthException('Incorrect code. The demo code is $demoOtp.');
    }
    challenge.signUpToken ??= _randomId();
    return challenge.signUpToken!;
  }

  /// Checks that [username] is valid and free, so the profile step can
  /// report it there instead of at the end of sign-up.
  @override
  Future<void> checkUsernameAvailable(String username) async {
    await Future.delayed(_latency);
    await _ensureUsernameFree(_validUsername(username));
  }

  /// Creates the account and returns a session token for it. Every new
  /// account starts at KYC tier 0, unverified.
  @override
  Future<String> signUp({
    required String signUpToken,
    required String displayName,
    required String username,
    required String pin,
  }) async {
    await Future.delayed(_latency);
    final entry = _server.challenges.entries
        .where((e) => e.value.signUpToken == signUpToken)
        .firstOrNull;
    if (entry == null) {
      throw const AuthException(
          'Your verification has expired. Please start sign-up again.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const AuthException('Use a four-digit PIN.');
    }
    final name = displayName.trim();
    if (name.isEmpty || name.length > 80) {
      throw const AuthException('Enter your name.');
    }
    final uname = _validUsername(username);
    await _ensureUsernameFree(uname);

    final accounts = await _db();
    if (accounts.values.any((a) => a.contact == entry.value.contact)) {
      throw const AuthException(
          'An account already uses this phone number or email. Log in instead.');
    }
    final account = _MockAccount(
      id: _randomId(),
      username: uname,
      displayName: name,
      pin: pin,
      contact: entry.value.contact,
      kyc: const KycInfo.initial(),
    );
    accounts[account.id] = account;
    _server.challenges.remove(entry.key);
    await _saveAccounts();
    return '$_tokenPrefix${account.id}';
  }

  // ---------------------------------------------------------------------
  // Account internals
  // ---------------------------------------------------------------------

  Future<Map<String, _MockAccount>> _db() =>
      _server.accounts ??= _loadAccounts();

  Future<Map<String, _MockAccount>> _loadAccounts() async {
    final accounts = <String, _MockAccount>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(SharedPrefsKeys.mockBackendDb);
      if (raw != null) {
        for (final json in (jsonDecode(raw) as List)) {
          final a = _MockAccount.fromJson(Map<String, dynamic>.from(json));
          accounts[a.id] = a;
        }
      }
    } catch (_) {
      // Corrupt or unreadable: start over with just the demo account.
    }
    accounts.putIfAbsent(
        _demoAccountId,
        () => _MockAccount(
              id: _demoAccountId,
              username: demoUsername,
              displayName: 'Scorche',
              pin: demoPin,
              kyc: const KycInfo.initial(),
            ));
    return accounts;
  }

  Future<void> _saveAccounts() async {
    try {
      final accounts = await _db();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.mockBackendDb,
          jsonEncode(accounts.values.map((a) => a.toJson()).toList()));
    } catch (_) {
      // Best-effort: the in-memory copy still serves this run.
    }
  }

  /// The account behind the session [token].
  Future<_MockAccount> _sessionAccount() => _accountFor(token);

  Future<_MockAccount> _accountFor(String? token) async {
    final accounts = await _db();
    final account = token != null && token.startsWith(_tokenPrefix)
        ? accounts[token.substring(_tokenPrefix.length)]
        : null;
    if (account == null) {
      throw const AuthException('Your session has expired. Please log in.');
    }
    return account;
  }

  Future<void> _ensureUsernameFree(String username) async {
    final accounts = await _db();
    if (accounts.values.any((a) => a.username == username)) {
      throw const AuthException('That username is taken.');
    }
  }

  static String _normalizeUsername(String username) {
    final name = username.trim().toLowerCase();
    return name.startsWith('@') ? name.substring(1) : name;
  }

  static String _validUsername(String username) {
    final name = _normalizeUsername(username);
    if (!RegExp(r'^[a-z0-9_.]{3,20}$').hasMatch(name)) {
      throw const AuthException(
          'Usernames are 3–20 characters: letters, numbers, "_" or ".".');
    }
    return name;
  }

  /// Lowercased email, or a phone number without spaces, dashes or
  /// brackets. Null if it's neither.
  static String? _normalizeContact(String contact) {
    final value = contact.trim();
    if (value.contains('@')) {
      final email = value.toLowerCase();
      return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
          ? email
          : null;
    }
    final phone = value.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?\d{10,15}$').hasMatch(phone) ? phone : null;
  }

  String _randomId() => List.generate(
      16, (_) => _server.random.nextInt(16).toRadixString(16)).join();

  // -------------------------------------------------------------------
  // Bills
  // -------------------------------------------------------------------

  @override
  Future<Catalog> getCatalog({String country = 'NG'}) async {
    await _request();
    if (country != 'NG') {
      throw const VtuException(
          VtuErrorCode.notFound, "ScorchePay isn't available there yet.");
    }
    return Catalog.fromJson(_nigeriaCatalog);
  }

  @override
  Future<VtuLimits> getLimits() async {
    await _request();
    final account = await _account();
    return _limits(account.kyc.tier, await _usedToday(account.accountId));
  }

  @override
  Future<CustomerInfo> validateCustomer(
      {required String billerId,
      required String target,
      String? optionId}) async {
    await _request();
    await _account();
    final biller = _biller(billerId);
    final number = TargetField.normalize(target);
    if (!biller.target.isValid(number)) {
      throw VtuException(VtuErrorCode.invalidTarget, biller.target.errorText);
    }
    // Numbers ending in 0000 don't exist, for testing the error.
    if (number.endsWith('0000')) {
      throw VtuException(VtuErrorCode.customerNotFound,
          "We couldn't find a customer with that ${biller.target.label.toLowerCase()}. Check it and try again.");
    }
    final seed = number.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
    return CustomerInfo(
      name: _customerNames[seed.abs() % _customerNames.length],
      address: biller.category == BillCategory.electricity
          ? _addresses[seed.abs() % _addresses.length]
          : null,
    );
  }

  @override
  Future<VtuOrder> createOrder(OrderRequest request) async {
    await _request();
    final account = await _account();
    final order = _MockOrder(
      accountId: account.accountId,
      failure: _Failure.of(scenario),
      base: await _quote(account, request, orderId: _newId()),
    );
    (await _orders())[order.base.id] = order;
    await _saveOrders();
    return order.resolve(DateTime.now());
  }

  @override
  Future<VtuOrder> requote(String orderId, {OrderRequest? request}) async {
    await _request();
    final account = await _account();
    final order = await _ownOrder(orderId);
    final status = order.resolve(DateTime.now()).status;
    if (status != OrderStatus.awaitingPayment &&
        status != OrderStatus.expired) {
      throw const VtuException(
          VtuErrorCode.alreadyPaid, 'This order has already been paid.');
    }
    final quote = await _quote(account, request ?? order.base.request,
        orderId: order.base.id);
    // The old invoice may have been paid while this was pricing.
    if (order.paidAt != null) {
      MockLightning.cancel(quote.invoice);
      throw const VtuException(
          VtuErrorCode.alreadyPaid, 'This order has already been paid.');
    }
    // Retire the old invoice, so the order can't be paid twice.
    MockLightning.cancel(order.base.invoice);
    order
      ..base = quote
      ..failure = _Failure.of(scenario);
    await _saveOrders();
    return order.resolve(DateTime.now());
  }

  /// Validates [request], checks it against the user's limits (leaving
  /// out [orderId]'s own current quote, when requoting) and prices it
  /// with a fresh invoice, as order [orderId] awaiting payment.
  Future<VtuOrder> _quote(
      ({String accountId, KycInfo kyc}) account, OrderRequest request,
      {required String orderId}) async {
    final biller = _biller(request.billerId);
    if (!biller.available) {
      throw VtuException(VtuErrorCode.billerUnavailable,
          '${biller.name} is unavailable right now. Try again later.');
    }
    final target = TargetField.normalize(request.target);
    if (!biller.target.isValid(target)) {
      throw VtuException(VtuErrorCode.invalidTarget, biller.target.errorText);
    }

    final (amount, plan) = switch (biller.pricing) {
      final PlanPricing pricing => _planPrice(pricing, request.planId),
      final AmountPricing pricing => _freePrice(pricing, request.amount),
    };
    final options = biller.options;
    final option = options?.find(request.optionId);
    if (options != null && option == null) {
      throw VtuException(VtuErrorCode.unknown,
          'Choose a ${options.label.toLowerCase()} to continue.');
    }

    final limits = _limits(account.kyc.tier,
        await _usedToday(account.accountId, excluding: orderId));
    if (amount > limits.maxOrder) {
      final daily = amount > limits.remainingToday && amount <= limits.perOrder;
      throw VtuException(
          VtuErrorCode.overLimit,
          daily
              ? "This is over what's left of your daily limit (${formatFiat(limits.remainingToday, limits.currency)})."
              : 'This is over your ${formatFiat(limits.perOrder, limits.currency)} limit per order.');
    }

    final customer = biller.customerCheck
        ? await validateCustomer(
            billerId: biller.id, target: target, optionId: option?.id)
        : null;

    final now = DateTime.now();
    final sats = (amount / _ngnPerBtc * 1e8 * (1 + _spread)).ceil();
    final expiresAt = now.add(scenario == MockScenario.quoteExpires
        ? const Duration(seconds: 20)
        : const Duration(minutes: 2));
    final invoice = MockLightning.fakeInvoice(sats, _server.random.nextInt(1 << 30));
    MockLightning.issue(invoice, expiresAt);

    return VtuOrder(
      id: orderId,
      title: _orderTitle(biller, plan: plan, option: option),
      status: OrderStatus.awaitingPayment,
      category: biller.category,
      billerId: biller.id,
      billerName: biller.name,
      target: target,
      amount: amount,
      currency: _currency,
      sats: sats,
      rate: amount / sats * 1e8,
      invoice: invoice,
      createdAt: now,
      expiresAt: expiresAt,
      request: OrderRequest(
        billerId: biller.id,
        target: target,
        optionId: option?.id,
        planId: plan?.id,
        amount: plan == null ? amount : null,
      ),
      planName: plan?.name,
      optionName: option?.name,
      customerName: customer?.name,
    );
  }

  @override
  Future<VtuOrder> getOrder(String orderId) async {
    await _request();
    final order = await _ownOrder(orderId);
    return order.resolve(DateTime.now());
  }

  @override
  Future<List<VtuOrder>> listOrders({int limit = 20}) async {
    await _request();
    final account = await _account();
    final now = DateTime.now();
    final own = (await _orders())
        .values
        .where((o) => o.accountId == account.accountId)
        .map((o) => o.resolve(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return own.take(limit).toList();
  }

  @override
  Future<VtuOrder> requestRefund(String orderId,
      {required String invoice}) async {
    await _request();
    final order = await _ownOrder(orderId);
    final now = DateTime.now();
    if (order.resolve(now).status != OrderStatus.refundable ||
        order.refundRequestedAt != null) {
      throw const VtuException(
          VtuErrorCode.unknown, "This order can't be refunded.");
    }
    final value = invoice.trim().toLowerCase().replaceFirst('lightning:', '');
    final sats = MockLightning.invoiceSats(value);
    if (!value.startsWith('ln') || sats == null) {
      throw const VtuException(VtuErrorCode.invalidInvoice,
          "That isn't a Lightning invoice with an amount. Create one in your wallet and paste it here.");
    }
    if (sats != order.base.sats) {
      throw VtuException(VtuErrorCode.invalidInvoice,
          'The invoice must be for exactly ${formatSats(order.base.sats)}; this one is for ${formatSats(sats)}.');
    }
    order.refundRequestedAt = now;
    await _saveOrders();
    return order.resolve(now);
  }

  // -------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------

  /// The signed-in account, as the backend resolves the session.
  Future<({String accountId, KycInfo kyc})> _account() async {
    try {
      final account = await _sessionAccount();
      return (accountId: account.id, kyc: account.kyc);
    } on AuthException catch (e) {
      throw VtuException(VtuErrorCode.signedOut, e.message);
    }
  }

  Future<void> _request() async {
    await Future.delayed(_latency);
    if (scenario == MockScenario.serverDown) {
      throw const VtuException(VtuErrorCode.network,
          "Can't reach ScorchePay. Check your connection and try again.");
    }
  }

  static Future<void> _onPayment(String invoice) async {
    final orders = await _orders();
    final now = DateTime.now();
    for (final order in orders.values) {
      if (order.base.invoice == invoice &&
          order.paidAt == null &&
          now.isBefore(order.base.expiresAt)) {
        order.paidAt = now;
        await _saveOrders();
      }
    }
  }

  Future<_MockOrder> _ownOrder(String orderId) async {
    final account = await _account();
    final order = (await _orders())[orderId];
    if (order == null || order.accountId != account.accountId) {
      throw const VtuException(VtuErrorCode.notFound, 'Order not found.');
    }
    return order;
  }

  Biller _biller(String id) {
    final json = (_nigeriaCatalog['billers'] as List)
        .cast<Map<String, dynamic>>()
        .where((b) => b['id'] == id)
        .firstOrNull;
    if (json == null) {
      throw const VtuException(VtuErrorCode.notFound, 'Unknown biller.');
    }
    return Biller.fromJson(json);
  }

  static (int, BillPlan) _planPrice(PlanPricing pricing, String? planId) {
    final plan = pricing.find(planId);
    if (plan == null) {
      throw const VtuException(
          VtuErrorCode.unknown, 'Choose a plan to continue.');
    }
    return (plan.amount, plan);
  }

  static (int, BillPlan?) _freePrice(AmountPricing pricing, int? amount) {
    if (amount == null || !pricing.allows(amount)) {
      final AmountPricing(:min, :max) = pricing;
      throw VtuException(
          VtuErrorCode.unknown,
          switch ((min, max)) {
            (final min?, final max?) =>
              'Enter an amount from ${formatFiat(min, _currency)} to ${formatFiat(max, _currency)}.',
            (final min?, null) =>
              'Enter at least ${formatFiat(min, _currency)}.',
            (null, final max?) =>
              'Enter up to ${formatFiat(max, _currency)}.',
            (null, null) => 'Enter an amount.',
          });
    }
    return (amount, null);
  }

  /// How the backend names an order, per category.
  static String _orderTitle(Biller biller,
          {BillPlan? plan, BillerChoice? option}) =>
      switch (biller.category) {
        BillCategory.airtime => '${biller.name} airtime',
        BillCategory.data => '${biller.name} ${plan?.name ?? 'data'}',
        BillCategory.electricity =>
          option == null ? biller.name : '${biller.name} (${option.name})',
        BillCategory.tv =>
          plan == null ? biller.name : '${biller.name} ${plan.name}',
      };

  static VtuLimits _limits(int tier, int usedToday) => tier >= 1
      ? VtuLimits(
          currency: _currency,
          tier: tier,
          perOrder: 200000,
          daily: 1000000,
          usedToday: usedToday)
      : VtuLimits(
          currency: _currency,
          tier: 0,
          perOrder: 10000,
          daily: 30000,
          usedToday: usedToday,
          nextTier: const VtuLimits(
              currency: _currency,
              tier: 1,
              perOrder: 200000,
              daily: 1000000,
              usedToday: 0),
        );

  /// Today's spend: paid orders, plus unexpired quotes (they hold the
  /// limit until they expire). Failed and refunded ones don't count.
  Future<int> _usedToday(String accountId, {String? excluding}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var total = 0;
    for (final order in (await _orders()).values) {
      if (order.accountId != accountId ||
          order.base.id == excluding ||
          order.base.createdAt.isBefore(today)) {
        continue;
      }
      final status = order.resolve(now).status;
      if (status == OrderStatus.expired ||
          status == OrderStatus.refundable ||
          status == OrderStatus.refunded) {
        continue;
      }
      total += order.base.amount;
    }
    return total;
  }

  String _newId() => List.generate(
      12, (_) => 'abcdefghjkmnpqrstuvwxyz23456789'[_server.random.nextInt(31)]).join();

  static Future<Map<String, _MockOrder>> _orders() =>
      _server.orders ??= _loadOrders();

  static Future<Map<String, _MockOrder>> _loadOrders() async {
    final orders = <String, _MockOrder>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(SharedPrefsKeys.mockVtuOrders);
      if (raw != null) {
        for (final json in jsonDecode(raw) as List) {
          final order =
              _MockOrder.fromJson(Map<String, dynamic>.from(json as Map));
          orders[order.base.id] = order;
        }
      }
    } catch (_) {
      // Unreadable: start with no orders.
    }
    return orders;
  }

  static Future<void> _saveOrders() async {
    try {
      final orders = await _orders();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          SharedPrefsKeys.mockVtuOrders, jsonEncode([for (final o in orders.values) o.toJson()]));
    } catch (_) {
      // Best-effort: the in-memory copy still serves this run.
    }
  }
}

/// How the provider fails a bill in the mock.
enum _Failure {
  none,

  /// Fails cleanly: the held payment goes back ([OrderStatus.refunded]).
  returned,

  /// Fails unclearly: staff review, then the user claims a refund
  /// ([OrderStatus.refundable]).
  review;

  static _Failure of(MockScenario scenario) => switch (scenario) {
        MockScenario.billFails => returned,
        MockScenario.billNeedsReview => review,
        _ => none,
      };
}

/// What the mock "server" holds, shared by every [MockVtuApi].
class _MockServer {
  final random = Random();
  final secureRandom = Random.secure();
  Future<Map<String, _MockAccount>>? accounts;
  Future<Map<String, _MockOrder>>? orders;
  final challenges = <String, _OtpChallenge>{};
  final passkeyChallenges = <String, _PasskeyChallenge>{};
}

/// A stored order plus the mock's bookkeeping. Its status is worked out
/// from timestamps whenever it's read ([resolve]), so no timers are
/// needed and a restart picks up where it left off.
class _MockOrder {
  _MockOrder({
    required this.accountId,
    required this.base,
    required this.failure,
    this.paidAt,
    this.refundRequestedAt,
  });

  final String accountId;

  /// The order as last quoted (awaiting payment). Replaced on a requote.
  VtuOrder base;

  /// How the provider fails this bill, if it does.
  _Failure failure;
  DateTime? paidAt;
  DateTime? refundRequestedAt;

  static const _fulfilAfter = Duration(milliseconds: 1500);
  static const _doneAfter = Duration(seconds: 5);
  static const _refundAfter = Duration(seconds: 4);

  VtuOrder resolve(DateTime now) {
    final paid = paidAt;
    if (paid == null) {
      return _with(now.isAfter(base.expiresAt)
          ? OrderStatus.expired
          : OrderStatus.awaitingPayment);
    }
    final elapsed = now.difference(paid);
    if (elapsed < _fulfilAfter) return _with(OrderStatus.paid);
    if (elapsed < _doneAfter) return _with(OrderStatus.fulfilling);
    switch (failure) {
      case _Failure.none:
        return _with(OrderStatus.done, receipt: _receipt());
      case _Failure.returned:
        // The held payment is cancelled, so the wallet gets it back.
        return _with(OrderStatus.refunded,
            failureReason:
                "${base.billerName} couldn't complete this bill. Your sats went straight back to your wallet.");
      case _Failure.review:
        break;
    }

    final refunded = refundRequestedAt;
    if (refunded != null && now.difference(refunded) >= _refundAfter) {
      return _with(OrderStatus.refunded);
    }
    return _with(OrderStatus.refundable,
        failureReason:
            "${base.billerName} couldn't complete this bill. Your sats can be refunded.",
        refundRequested: refunded != null);
  }

  VtuOrder _with(OrderStatus status,
          {OrderReceipt? receipt,
          String? failureReason,
          bool refundRequested = false}) =>
      VtuOrder(
        id: base.id,
        title: base.title,
        status: status,
        category: base.category,
        billerId: base.billerId,
        billerName: base.billerName,
        target: base.target,
        amount: base.amount,
        currency: base.currency,
        sats: base.sats,
        rate: base.rate,
        invoice: base.invoice,
        createdAt: base.createdAt,
        expiresAt: base.expiresAt,
        request: base.request,
        planName: base.planName,
        optionName: base.optionName,
        customerName: base.customerName,
        paidAt: paidAt,
        receipt: receipt,
        failureReason: failureReason,
        refundRequested: refundRequested,
      );

  /// What the provider returns per category, as receipt items.
  OrderReceipt _receipt() {
    final reference = 'SP-${base.id.toUpperCase()}';
    final amount = formatFiat(base.amount, base.currency);
    return switch (base.category) {
      BillCategory.airtime => OrderReceipt(
          reference: reference,
          message: '$amount ${base.billerName} airtime sent to ${base.target}.'),
      BillCategory.data => OrderReceipt(
          reference: reference,
          message: '${base.planName} sent to ${base.target}.'),
      BillCategory.electricity when base.request.optionId == 'postpaid' =>
        OrderReceipt(
            reference: reference,
            message: '$amount paid to meter ${base.target}.'),
      BillCategory.electricity => OrderReceipt(
          reference: reference,
          message: 'Enter the token on your meter to load the units.',
          items: [
            ReceiptItem(
                label: 'Token',
                value: _meterToken(),
                primary: true,
                copyable: true),
            ReceiptItem(
                label: 'Units',
                value: '${(base.amount / 225).toStringAsFixed(1)} kWh'),
          ]),
      BillCategory.tv => OrderReceipt(
          reference: reference,
          message:
              '${base.billerName} ${base.planName} active on smartcard ${base.target}.'),
    };
  }

  /// A 20-digit prepaid token, stable per order.
  String _meterToken() {
    final digits = base.id.codeUnits
        .fold<int>(7, (a, b) => (a * 131 + b) % 100000000000);
    final token = digits.toString().padLeft(11, '0') +
        (digits * 7 % 1000000000).toString().padLeft(9, '0');
    return [for (var i = 0; i < 20; i += 4) token.substring(i, i + 4)]
        .join('-');
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'base': base.toJson(),
        'failure': failure.name,
        'paidAt': paidAt?.toUtc().toIso8601String(),
        'refundRequestedAt': refundRequestedAt?.toUtc().toIso8601String(),
      };

  factory _MockOrder.fromJson(Map<String, dynamic> json) => _MockOrder(
        accountId: json['accountId'] as String,
        base: VtuOrder.fromJson(Map<String, dynamic>.from(json['base'] as Map)),
        failure: _Failure.values
                .where((f) => f.name == json['failure'])
                .firstOrNull ??
            _Failure.none,
        paidAt: json['paidAt'] == null
            ? null
            : DateTime.parse(json['paidAt'] as String).toLocal(),
        refundRequestedAt: json['refundRequestedAt'] == null
            ? null
            : DateTime.parse(json['refundRequestedAt'] as String).toLocal(),
      );
}

const _customerNames = [
  'ADEBAYO OLUWASEUN',
  'CHIOMA NWOSU',
  'IBRAHIM MUSA',
  'FUNMILAYO ADEYEMI',
  'EMEKA OKAFOR',
  'HALIMA BELLO',
];

const _addresses = [
  '14 Admiralty Way, Lekki, Lagos',
  '7 Aminu Kano Crescent, Wuse 2, Abuja',
  '22 Allen Avenue, Ikeja, Lagos',
  '3 Stadium Road, Port Harcourt',
];

// ---------------------------------------------------------------------
// Nigeria catalog fixture (GET /catalog?country=NG). Prices are
// illustrative; the real catalog comes from the provider.
// ---------------------------------------------------------------------

const _phone = {
  'kind': 'phone',
  'label': 'Phone number',
  'hint': '0803 123 4567',
  'pattern': r'^0[789][01]\d{8}$',
  'errorText': 'Enter an 11-digit Nigerian number, like 0803 123 4567.',
};

const _meter = {
  'kind': 'number',
  'label': 'Meter number',
  'hint': '11 to 13 digits',
  'pattern': r'^\d{11,13}$',
  'errorText': 'Meter numbers are 11 to 13 digits.',
};

const _smartcard = {
  'kind': 'number',
  'label': 'Smartcard (IUC) number',
  'hint': '10 or 11 digits',
  'pattern': r'^\d{10,11}$',
  'errorText': 'Smartcard numbers are 10 or 11 digits.',
};

// Any amount: only the user's tier limits cap it.
const _airtimeAmount = {
  'type': 'amount',
  'presets': [100, 200, 500, 1000, 2000, 5000],
};

const _powerAmount = {
  'type': 'amount',
  'min': 1000,
  'max': 500000,
  'presets': [2000, 5000, 10000, 20000],
};

const _meterTypes = {
  'label': 'Meter type',
  'choices': [
    {'id': 'prepaid', 'name': 'Prepaid'},
    {'id': 'postpaid', 'name': 'Postpaid'},
  ],
};

const _networks = [
  ('mtn', 'MTN', '#FFCC08'),
  ('airtel', 'Airtel', '#FF3B30'),
  ('glo', 'Glo', '#00A651'),
  ('9mobile', '9mobile', '#00A99D'),
];

const _dataSizes = [
  ('1gb-1d', '1GB', '1 day', 500),
  ('1gb-7d', '1GB', '7 days', 800),
  ('2gb-30d', '2GB', '30 days', 1500),
  ('5gb-30d', '5GB', '30 days', 3500),
  ('10gb-30d', '10GB', '30 days', 6000),
  ('20gb-30d', '20GB', '30 days', 10000),
];

const _discos = [
  ('ikedc', 'Ikeja Electric', 'Ikeja', '#E30613'),
  ('ekedc', 'Eko Electric', 'Eko', '#0072BC'),
  ('aedc', 'Abuja Electric', 'Abuja', '#00A651'),
  ('phed', 'Port Harcourt Electric', 'PH', '#F7941D'),
  ('ibedc', 'Ibadan Electric', 'Ibadan', '#662D91'),
];

const _tvProviders = [
  ('dstv', 'DStv', '#0098DA', [
    ('padi', 'Padi', 4400),
    ('yanga', 'Yanga', 6000),
    ('confam', 'Confam', 11000),
    ('compact', 'Compact', 19000),
  ]),
  ('gotv', 'GOtv', '#5BB947', [
    ('smallie', 'Smallie', 1900),
    ('jinja', 'Jinja', 3900),
    ('jolli', 'Jolli', 5800),
    ('max', 'Max', 8500),
  ]),
  ('startimes', 'StarTimes', '#F28C00', [
    ('nova', 'Nova', 2100),
    ('basic', 'Basic', 4000),
    ('classic', 'Classic', 6000),
  ]),
];

final Map<String, dynamic> _nigeriaCatalog = {
  'country': 'NG',
  'currency': 'NGN',
  'billers': [
    for (final (id, name, color) in _networks)
      {
        'id': '$id-airtime',
        'category': 'airtime',
        'name': name,
        'brandColor': color,
        'target': _phone,
        'pricing': _airtimeAmount,
      },
    for (final (id, name, color) in _networks)
      {
        'id': '$id-data',
        'category': 'data',
        'name': name,
        'brandColor': color,
        'target': _phone,
        'pricing': {
          'type': 'plans',
          'label': 'Choose a plan',
          'plans': [
            for (final (i, (planId, size, validity, price))
                in _dataSizes.indexed)
              {
                'id': '$id-$planId',
                'name': size,
                'validity': validity,
                // Small per-network differences, like real price lists.
                'amount': price + (id == 'mtn' ? 0 : (i + 1) * 50),
              }
          ],
        },
      },
    for (final (id, name, short, color) in _discos)
      {
        'id': id,
        'category': 'electricity',
        'name': name,
        'shortName': short,
        'brandColor': color,
        'target': _meter,
        'pricing': _powerAmount,
        'options': _meterTypes,
        'customerCheck': true,
      },
    for (final (id, name, color, plans) in _tvProviders)
      {
        'id': id,
        'category': 'tv',
        'name': name,
        'brandColor': color,
        'target': _smartcard,
        'pricing': {
          'type': 'plans',
          'label': 'Choose a package',
          'plans': [
            for (final (planId, planName, price) in plans)
              {
                'id': '$id-$planId',
                'name': planName,
                'validity': '1 month',
                'amount': price,
              }
          ],
        },
        'customerCheck': true,
      },
  ],
};

class _PasskeyChallenge {
  _PasskeyChallenge(
      {required this.type, required this.accountId, required this.expiresAt});

  /// `webauthn.create` or `webauthn.get`.
  final String type;

  /// The account adding a passkey; null for logins.
  final String? accountId;
  final DateTime expiresAt;
}

class _PasskeyCredential {
  const _PasskeyCredential({
    required this.id,
    required this.clientType,
    required this.challenge,
    required this.userHandle,
  });

  final String id;
  final String? clientType;
  final String? challenge;
  final String? userHandle;
}

class _OtpChallenge {
  _OtpChallenge({required this.contact, required this.expiresAt});

  final String contact;
  final DateTime expiresAt;
  int attempts = 0;

  /// Set once the code is verified.
  String? signUpToken;
}

class _MockAccount {
  _MockAccount({
    required this.id,
    required this.username,
    required this.displayName,
    required this.pin,
    required this.kyc,
    this.contact,
    this.photoUrl,
    this.photoContentType,
    Set<String>? passkeyIds,
  }) : passkeyIds = passkeyIds ?? {};

  final String id;
  String username;
  String displayName;
  final String pin;
  final String? contact;
  KycInfo kyc;
  String? photoUrl;
  String? photoContentType;

  /// Credential IDs (base64url) of this account's passkeys.
  final Set<String> passkeyIds;

  ApiUser toUser() => ApiUser(
        id: id,
        username: username,
        displayName: displayName,
        kyc: kyc,
        photoUrl: photoUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'pin': pin,
        'contact': contact,
        'kyc': kyc.toJson(),
        'photoUrl': photoUrl,
        'photoContentType': photoContentType,
        'passkeyIds': passkeyIds.toList(),
      };

  factory _MockAccount.fromJson(Map<String, dynamic> json) => _MockAccount(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        pin: json['pin'] as String,
        contact: json['contact'] as String?,
        photoUrl: json['photoUrl'] as String?,
        photoContentType: json['photoContentType'] as String?,
        kyc: json['kyc'] is Map
            ? KycInfo.fromJson(Map<String, dynamic>.from(json['kyc'] as Map))
            : const KycInfo.initial(),
        passkeyIds: {
          for (final id in (json['passkeyIds'] as List? ?? const []))
            id as String
        },
      );
}
