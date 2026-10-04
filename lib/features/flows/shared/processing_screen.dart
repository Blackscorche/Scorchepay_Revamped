import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/scorch_mascot.dart';
import '../../../data/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Attaches error handling before animating. Unknown outcomes never become
/// success, and closing this screen never retries the underlying task.
class ProcessingScreen<T> extends StatefulWidget {
  const ProcessingScreen(
      {super.key,
      required this.steps,
      required this.task,
      this.timeout = const Duration(seconds: 30)});
  final List<String> steps;
  final Future<T> Function() task;
  final Duration timeout;
  @override
  State<ProcessingScreen<T>> createState() => _ProcessingScreenState<T>();
}

class _ProcessingScreenState<T> extends State<ProcessingScreen<T>> {
  int _stepIndex = 0;
  Timer? _steps;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _steps = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted && _stepIndex + 1 < widget.steps.length)
        setState(() => _stepIndex++);
    });
    _run();
  }

  Future<void> _run() async {
    try {
      final result = await Future<T>.sync(widget.task).timeout(widget.timeout);
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _steps?.cancel();
    }
  }

  @override
  void dispose() {
    _steps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _error != null,
        child: Scaffold(
            backgroundColor: AppColors.page,
            body: SafeArea(
                child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ScorchMascot(
                        activity: _error == null
                            ? ScorchActivity.processing
                            : ScorchActivity.rest,
                        size: 150),
                    const SizedBox(height: 24),
                    Text(
                        _error != null
                            ? 'We could not confirm the result'
                            : widget.steps.isEmpty
                                ? 'Working on it…'
                                : widget.steps[_stepIndex],
                        style:
                            AppText.body.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                          _error is ApiRequestException
                              ? _error.toString()
                              : 'Check your activity before starting another payment.',
                          style: AppText.bodyMuted,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close')),
                    ],
                  ])),
            ))),
      );
}
