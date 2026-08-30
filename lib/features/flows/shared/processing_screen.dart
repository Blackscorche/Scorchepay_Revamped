import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Shared "this is really happening asynchronously" step. Renders each
/// of [steps] in sequence with a short delay between them — multi-leg
/// operations (Smart Pay's "debit funding legs, then call the biller")
/// are genuinely two moments, not one spinner, per the flow
/// walkthroughs. Awaits [task] in the background and pops with its
/// result once both the task and the step animation have finished.
class ProcessingScreen<T> extends StatefulWidget {
  const ProcessingScreen({super.key, required this.steps, required this.task});

  final List<String> steps;
  final Future<T> Function() task;

  @override
  State<ProcessingScreen<T>> createState() => _ProcessingScreenState<T>();
}

class _ProcessingScreenState<T> extends State<ProcessingScreen<T>> {
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final taskFuture = widget.task();
    for (int i = 0; i < widget.steps.length; i++) {
      if (!mounted) return;
      setState(() => _stepIndex = i);
      await Future.delayed(const Duration(milliseconds: 700));
    }
    final result = await taskFuture;
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.steps[_stepIndex.clamp(0, widget.steps.length - 1)],
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
