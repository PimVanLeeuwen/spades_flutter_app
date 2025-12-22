// Simple Cupertino numeric stepper: min..max, step=1 by default
import 'package:flutter/cupertino.dart';

class NumericStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final Axis direction;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const NumericStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 13,
    this.step = 1,
    this.direction = Axis.horizontal,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    Widget pill(IconData icon, bool enabled, VoidCallback? onPressed) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        onPressed: enabled ? onPressed : null,
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? CupertinoColors.activeBlue.resolveFrom(context)
              : CupertinoColors.inactiveGray.resolveFrom(context),
        ),
      );
    }

    final isHorizontal = direction == Axis.horizontal;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      padding: isHorizontal
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: isHorizontal
          ? Row(
              children: [
                pill(CupertinoIcons.minus, value > min, onDecrement),
                Expanded(
                  child: Center(child: Text('$value', style: textStyle)),
                ),
                pill(CupertinoIcons.plus, value < max, onIncrement),
              ],
            )
          : Column(
            mainAxisSize: MainAxisSize.min,
              children: [
                pill(CupertinoIcons.plus, value < max, onIncrement),
                Center(
                  child: Center(child: Text('$value', style: textStyle)),
                ),
                pill(CupertinoIcons.minus, value > min, onDecrement),
              ],
            ),
    );
  }
}
