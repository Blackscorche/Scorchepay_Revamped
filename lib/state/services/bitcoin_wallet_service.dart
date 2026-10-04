import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A real, working Signet (Bitcoin testnet) wallet backed by BDK —
/// this is a genuine on-chain wallet, not a simulation: it generates a
/// real BIP84 descriptor, syncs against a public Signet Esplora
/// indexer, and can send a real Signet transaction. Wired up first as
/// its own standalone flow (no server dependency) so it has the
/// fewest possible moving parts for a live demo.
///
/// The mnemonic is the wallet's only secret — anyone with it controls
/// the funds — so it's stored in the platform keystore/keychain via
/// [FlutterSecureStorage], the same mechanism the live auth flow
/// already uses for session tokens.
class BitcoinWalletService {
  BitcoinWalletService._();
  static final BitcoinWalletService instance = BitcoinWalletService._();

  static const _mnemonicKey = 'btc_signet_mnemonic_v1';
  static const _storage = FlutterSecureStorage();

  // mempool.space's public Signet Esplora indexer — no API key, no
  // infra to run ourselves, good uptime for a demo.
  static const _esploraUrl = 'https://mempool.space/signet/api';

  Wallet? _wallet;
  Blockchain? _blockchain;

  bool get isLoaded => _wallet != null;

  Future<Blockchain> _getBlockchain() async {
    return _blockchain ??= await Blockchain.create(
      config: BlockchainConfig.esplora(
        config: EsploraConfig(baseUrl: _esploraUrl, stopGap: BigInt.from(20)),
      ),
    );
  }

  /// Loads the existing wallet from secure storage, or returns null if
  /// none has been created yet on this device.
  Future<Wallet?> loadExisting() async {
    if (_wallet != null) return _wallet;
    final saved = await _storage.read(key: _mnemonicKey);
    if (saved == null) return null;
    return _openFromMnemonic(saved);
  }

  /// Generates a brand-new 12-word mnemonic, persists it, and opens
  /// the wallet from it. Returns the mnemonic so the UI can show it to
  /// the user once as a backup phrase.
  Future<(Wallet, String)> createNew() async {
    final mnemonic = await Mnemonic.create(WordCount.words12);
    final phrase = mnemonic.toString();
    await _storage.write(key: _mnemonicKey, value: phrase);
    final wallet = await _openFromMnemonic(phrase);
    return (wallet, phrase);
  }

  Future<Wallet> _openFromMnemonic(String phrase) async {
    final mnemonic = await Mnemonic.fromString(phrase);
    final secretKey = await DescriptorSecretKey.create(
      network: Network.signet,
      mnemonic: mnemonic,
    );
    final external = await Descriptor.newBip84(
      secretKey: secretKey,
      network: Network.signet,
      keychain: KeychainKind.externalChain,
    );
    final internal = await Descriptor.newBip84(
      secretKey: secretKey,
      network: Network.signet,
      keychain: KeychainKind.internalChain,
    );
    final wallet = await Wallet.create(
      descriptor: external,
      changeDescriptor: internal,
      network: Network.signet,
      databaseConfig: const DatabaseConfig.memory(),
    );
    return _wallet = wallet;
  }

  Future<void> sync() async {
    final wallet = _wallet;
    if (wallet == null) throw StateError('Wallet not loaded');
    await wallet.sync(blockchain: await _getBlockchain());
  }

  AddressInfo getReceiveAddress() {
    final wallet = _wallet;
    if (wallet == null) throw StateError('Wallet not loaded');
    return wallet.getAddress(addressIndex: const AddressIndex.lastUnused());
  }

  Balance getBalance() {
    final wallet = _wallet;
    if (wallet == null) throw StateError('Wallet not loaded');
    return wallet.getBalance();
  }

  List<TransactionDetails> getTransactions() {
    final wallet = _wallet;
    if (wallet == null) throw StateError('Wallet not loaded');
    final txs = wallet.listTransactions(includeRaw: false);
    txs.sort((a, b) {
      final ah = a.confirmationTime?.height ?? 1 << 30; // unconfirmed first
      final bh = b.confirmationTime?.height ?? 1 << 30;
      return bh.compareTo(ah);
    });
    return txs;
  }

  /// Sends [amountSat] to [address] on Signet, broadcasts it, and
  /// returns the transaction ID.
  Future<String> send({required String address, required int amountSat}) async {
    final wallet = _wallet;
    if (wallet == null) throw StateError('Wallet not loaded');
    final blockchain = await _getBlockchain();
    final recipient = await Address.fromString(s: address, network: Network.signet);
    final script = recipient.scriptPubkey();
    final feeRate = await blockchain.estimateFee(target: BigInt.from(6));
    final (psbt, _) = await TxBuilder()
        .addRecipient(script, BigInt.from(amountSat))
        .feeRate(feeRate.satPerVb)
        .finish(wallet);
    final finalized = wallet.sign(psbt: psbt);
    if (!finalized) throw StateError('Could not finalize transaction');
    final tx = psbt.extractTx();
    return blockchain.broadcast(transaction: tx);
  }
}
