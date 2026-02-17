/// ============================================================================
/// readonly_field.dart - Display-Only Text Field Widget
/// ============================================================================
///
/// A styled read-only text display that visually matches input fields.
/// Used for showing calculated values (like scores) that users can't edit.
///
/// DESIGN RATIONALE:
/// Why have a "read-only field" instead of just Text?
/// 1. Visual consistency with editable inputs
/// 2. Clear boundaries and padding
/// 3. Background color for semantic meaning (success/error)
/// 4. Professional, polished appearance
/// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:spades/colors.dart';

/// A Cupertino-themed read-only field that displays text with optional
/// background coloring for semantic meaning.
///
/// FLUTTER CONCEPT: Composing Widgets
/// This widget composes lower-level widgets (Container, Text) into a
/// higher-level abstraction. This is the Flutter way of building UIs:
/// small, focused widgets combined into larger, meaningful components.
///
/// USAGE:
/// ```dart
/// ReadonlyField(
///   text: '250 + 3',  // Score display
///   backgroundColor: AppColors.success,  // Winning score
/// )
/// ```
class ReadonlyField extends StatelessWidget {
  /// The text to display in the field.
  final String text;

  /// How to align the text within the field.
  /// Defaults to center alignment for score displays.
  final TextAlign textAlign;

  /// Internal padding around the text.
  final EdgeInsets padding;

  /// Background color for semantic meaning.
  /// Use [AppColors.success] for winning, [AppColors.error] for losing.
  final Color backgroundColor;

  /// Creates a ReadonlyField widget.
  ///
  /// DART CONCEPT: Const Constructor Best Practices
  /// Making constructors `const` when possible enables:
  /// 1. Compile-time constant widgets (cached, never rebuilt)
  /// 2. Const propagation in widget trees
  /// 3. Slight performance improvements
  ///
  /// Rule: Use `const` if all fields can be assigned const values.
  const ReadonlyField({
    super.key,
    required this.text,
    this.textAlign = TextAlign.center,
    this.backgroundColor = AppColors.surface,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    // FLUTTER CONCEPT: Theme Access
    // CupertinoTheme.of(context) walks up the widget tree to find the
    // nearest CupertinoTheme ancestor and returns its data. This is
    // how widgets access app-wide styling.
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    // FLUTTER CONCEPT: Container Widget
    // Container is a convenience widget that combines:
    // - Padding
    // - Decoration (background, border, shadow)
    // - Constraints (min/max size)
    // - Alignment
    // It's one of the most commonly used layout widgets.
    return Container(
      decoration: BoxDecoration(
        // Apply the semantic background color
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        // Subtle border for definition against backgrounds
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      // FLUTTER CONCEPT: DefaultTextStyle.merge
      // This widget merges additional style properties with the inherited
      // text style. Child Text widgets without explicit styles will use
      // this merged style. Useful for applying styles to a subtree.
      child: DefaultTextStyle.merge(
        style: textStyle.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}


