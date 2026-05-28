import 'package:flutter/material.dart';

enum InitStepState { pending, running, done, error }

class InitStep {
  final String label;
  InitStepState state;
  int? elapsedMs;
  String? errorMsg;

  InitStep(this.label) : state = InitStepState.pending;
}

class InitProgressOverlay extends StatelessWidget {
  final List<InitStep> steps;

  const InitProgressOverlay({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pose Animator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              ...steps.map(_buildStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(InitStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _buildIcon(step),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    color: _labelColor(step),
                    fontSize: 14,
                  ),
                ),
                if (step.errorMsg != null)
                  Text(
                    step.errorMsg!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (step.elapsedMs != null)
            Text(
              '${step.elapsedMs} ms',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(InitStep step) {
    switch (step.state) {
      case InitStepState.pending:
        return const SizedBox(
          width: 18,
          height: 18,
          child: Icon(Icons.circle_outlined, color: Colors.white24, size: 18),
        );
      case InitStepState.running:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.greenAccent,
          ),
        );
      case InitStepState.done:
        return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18);
      case InitStepState.error:
        return const Icon(Icons.error, color: Colors.redAccent, size: 18);
    }
  }

  Color _labelColor(InitStep step) {
    return switch (step.state) {
      InitStepState.pending => Colors.white38,
      InitStepState.running => Colors.white,
      InitStepState.done => Colors.white70,
      InitStepState.error => Colors.redAccent,
    };
  }
}
