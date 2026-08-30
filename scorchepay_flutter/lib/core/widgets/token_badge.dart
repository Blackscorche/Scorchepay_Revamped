import 'package:flutter/material.dart';

/// Circular crypto-asset badge: a soft tint of the coin's own brand
/// color plus its ticker glyph — the same fallback pattern real wallet
/// apps (Rainbow, Phantom, Coinbase Wallet) use for any token that
/// doesn't have a bespoke logo asset bundled.
class TokenBadge extends StatelessWidget {
  const TokenBadge({super.key, required this.glyph, required this.color, this.size = 38});

  final String glyph;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        glyph,
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
