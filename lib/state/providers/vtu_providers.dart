import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vtu.dart';
import '../services/vtu_api.dart';
import 'api_providers.dart';
import 'app_state_notifier.dart';



/// The country's billers and plans (Nigeria only for now). Kept for the
/// session; `ref.invalidate` it to retry after an error.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  return ref.watch(vtuApiProvider).getCatalog();
});

/// The user's caps at their KYC tier, refreshed when the tier changes.
final vtuLimitsProvider = FutureProvider.autoDispose<VtuLimits>((ref) async {
  ref.watch(appStateProvider.select((s) => s.valueOrNull?.kyc));
  return ref.watch(vtuApiProvider).getLimits();
});

/// The user's latest orders for the dashboard. Invalidate after creating
/// or finishing one.
final recentOrdersProvider =
    FutureProvider.autoDispose<List<VtuOrder>>((ref) async {
  return ref.watch(vtuApiProvider).listOrders(limit: 5);
});

const _pollEvery = Duration(seconds: 2);

/// One order, polled while its status can still change on its own
/// (system design: polling now, server-sent events optional later).
/// Invalidate it to resume polling, e.g. after requesting a refund.
final orderProvider =
    StreamProvider.autoDispose.family<VtuOrder, String>((ref, orderId) {
  final api = ref.watch(vtuApiProvider);
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return _pollOrder(api, orderId, isDisposed: () => disposed);
});

Stream<VtuOrder> _pollOrder(VtuApi api, String orderId,
    {required bool Function() isDisposed}) async* {
  VtuOrder? last;
  while (!isDisposed()) {
    try {
      final order = await api.getOrder(orderId);
      last = order;
      yield order;
      if (!order.inProgress) return;
    } catch (_) {
      // Keep polling through a blip once there's something to show.
      if (last == null) rethrow;
    }
    await Future.delayed(_pollEvery);
  }
}
