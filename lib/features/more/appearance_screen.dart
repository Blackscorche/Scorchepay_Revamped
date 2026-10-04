import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/detail_header.dart';
import '../../core/widgets/section_title.dart';
import '../../state/providers/accent_color_provider.dart';
import '../../state/providers/theme_mode_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Lets the user pick how ScorchePay is themed — follow the OS, pin it
/// to light/dark, and re-tint the brand accent. Both choices persist
/// (see [ThemeModeNotifier] / [AccentColorNotifier]) and apply
/// instantly everywhere, not just on this screen, so any light/dark ×
/// accent combination the user picks is a real supported "theme", not
/// just a preview.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            const DetailHeader(
              icon: AppIcons.contrast,
              title: 'Appearance',
              subtitle: 'Choose how ScorchePay looks on this device',
            ),
            const SizedBox(height: 22),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  _ThemeOptionRow(
                    icon: AppIcons.contrast,
                    title: 'System',
                    subtitle: 'Matches your device setting',
                    selected: mode == AppThemeMode.system,
                    showDivider: true,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.system),
                  ),
                  _ThemeOptionRow(
                    icon: AppIcons.sun,
                    title: 'Light',
                    subtitle: 'Bright background, dark text',
                    selected: mode == AppThemeMode.light,
                    showDivider: true,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.light),
                  ),
                  _ThemeOptionRow(
                    icon: AppIcons.moon,
                    title: 'Dark',
                    subtitle: 'Dimmed, easier at night',
                    selected: mode == AppThemeMode.dark,
                    showDivider: false,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(AppThemeMode.dark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'System keeps ScorchePay in sync with your phone\'s '
              'display setting, including any automatic day/night '
              'schedule.',
              style: AppText.caption,
            ),
            const SectionTitle('Accent color'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final preset in AccentPreset.values)
                    _AccentSwatch(
                      preset: preset,
                      selected: accent.value == preset.color.value,
                      onTap: () => ref
                          .read(accentColorProvider.notifier)
                          .setColor(preset.color),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mix any accent with Light, Dark or System — every combo '
              'is fully supported, not just the default ember on dark.',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch(
      {required this.preset, required this.selected, required this.onTap});

  final AccentPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: preset.color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.textPrimary, width: 2.5)
                  : Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                    color: preset.color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: selected
                ? Icon(AppIcons.check,
                    size: 18,
                    color: preset.color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(preset.label,
              style: TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.showDivider,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: AppColors.hairline))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 18,
                  color: selected ? AppColors.accent : AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppText.body),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(AppIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
