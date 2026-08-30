import 'package:flutter/material.dart';
import '../../app_routes.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/decorative_rings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class _OnboardingSlide {
  const _OnboardingSlide(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _OnboardingSlide(
    icon: AppIcons.walletOutline,
    title: 'One vault for all your money',
    body: 'Hold NGN, USD, GHS, EUR, GBP and crypto — all in a single balance.',
  ),
  _OnboardingSlide(
    icon: AppIcons.bolt,
    title: 'Just tap Pay',
    body:
        'Smart Pay figures out the best way to fund anything — bills, transfers, merchants — automatically.',
  ),
  _OnboardingSlide(
    icon: AppIcons.coins,
    title: 'Crypto that behaves like money',
    body:
        'Buy, hold and spend BTC, ETH, USDT and more without needing to think like a trader.',
  ),
  _OnboardingSlide(
    icon: AppIcons.shield,
    title: 'Escrow on any payment',
    body:
        'Turn any transaction into a protected escrow — freelance work, marketplace deals, property.',
  ),
];

/// Four-slide carousel introducing the app's core pillars, reached right
/// after the splash screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        final slide = _slides[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(slide.icon,
                                    size: 52, color: AppColors.accent),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: AppText.pageTitle.copyWith(fontSize: 22),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                slide.body,
                                textAlign: TextAlign.center,
                                style: AppText.bodyMuted
                                    .copyWith(fontSize: 13.5, height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.surface3,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: isLast ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
