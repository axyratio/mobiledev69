import 'package:flutter/material.dart';

import '../viewmodels/create_story_view_model.dart';

/// Stepper + quick-pick chips for choosing the target word count (FR-04),
/// with inline validation copy when the value is out of range (FR-15).
class WordCountControl extends StatelessWidget {
  const WordCountControl({
    super.key,
    required this.value,
    required this.isValid,
    required this.onChanged,
  });

  final int value;
  final bool isValid;
  final ValueChanged<int> onChanged;

  static const List<int> quickPicks = [3, 5, 8, 10, 15];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'จำนวนคำ ($minStoryWords–$maxStoryWords)',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StepButton(icon: Icons.remove, onTap: () => onChanged(value - 1)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid
                        ? theme.colorScheme.outline
                        : theme.colorScheme.error,
                    width: isValid ? 1 : 1.5,
                  ),
                  color: isValid ? null : theme.colorScheme.errorContainer,
                ),
                child: Text('$value', style: theme.textTheme.headlineSmall),
              ),
            ),
            const SizedBox(width: 10),
            _StepButton(icon: Icons.add, onTap: () => onChanged(value + 1)),
          ],
        ),
        if (!isValid) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 15,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'กรอกจำนวนคำระหว่าง $minStoryWords ถึง $maxStoryWords คำเท่านั้น',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'เลือกเร็ว',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final quick in quickPicks)
              ChoiceChip(
                label: Text('$quick'),
                selected: value == quick,
                onSelected: (_) => onChanged(quick),
                showCheckmark: false,
              ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
