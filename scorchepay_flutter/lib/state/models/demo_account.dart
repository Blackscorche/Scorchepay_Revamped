/// Seeded counterparty accounts so P2P, escrow, and group-savings flows
/// are fully testable by one person without a real backend. These are
/// not full simulated wallets — they exist so "@ada_b" is a resolvable,
/// named recipient with a display name confirmation step, matching the
/// spec's anti-mis-send pattern (§8), and so escrow/group flows have a
/// counterparty whose side of the flow can be simulated on demand.
class DemoAccount {
  const DemoAccount({required this.username, required this.displayName, required this.initials});

  final String username;
  final String displayName;
  final String initials;
}

class DemoAccounts {
  DemoAccounts._();

  static const all = [
    DemoAccount(username: '@ada_b', displayName: 'Ada Balogun', initials: 'AB'),
    DemoAccount(username: '@chidi.eth', displayName: 'Chidi Eze', initials: 'CE'),
    DemoAccount(username: '@nomsa', displayName: 'Nomsa Khumalo', initials: 'NK'),
    DemoAccount(username: '@kwame_gh', displayName: 'Kwame Mensah', initials: 'KM'),
    DemoAccount(username: '@tobi_biz', displayName: 'Tobi Adeyemi', initials: 'TA'),
  ];

  static DemoAccount? byUsername(String username) {
    final needle = username.trim().toLowerCase();
    for (final a in all) {
      if (a.username.toLowerCase() == needle) return a;
    }
    return null;
  }
}
