import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/empty_state_page.dart';

/// Get notified when an asset crosses a target price.
class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStatePage(
      headerIcon: AppIcons.bell,
      title: 'Price Alerts',
      subtitle: 'Get notified when an asset crosses a target price',
      emptyIcon: AppIcons.bell,
      emptyTitle: 'No price alerts yet',
      emptyMessage:
          'Pick an asset and a target price and we\'ll notify you the moment it\'s crossed.',
      ctaLabel: 'Add a price alert',
      onCta: () => showAppModal(
        context,
        icon: AppIcons.bell,
        title: 'Add a price alert',
        message:
            'Pick an asset, a target price, and whether to notify above or below it.',
      ),
    );
  }
}
