
import 'package:flutter/cupertino.dart';

/// Cupertino-themed read-only field that matches your stepper styling.
class ReadonlyField extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final EdgeInsets padding;

  const ReadonlyField({
    super.key,
    required this.text,
    this.textAlign = TextAlign.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      padding: padding,
      child: DefaultTextStyle.merge(
        style: textStyle,
        child: Text(text, textAlign: textAlign),
      ),
    );
  }
}
