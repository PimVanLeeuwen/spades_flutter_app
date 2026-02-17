/// ============================================================================
/// numeric_stepper.dart - Custom Numeric Input Widget
/// ============================================================================
///
/// A reusable Cupertino-styled numeric stepper for inputting integer values.
/// This widget demonstrates:
///
/// - Building custom input controls
/// - Composing widgets from primitives
/// - Supporting multiple layout orientations
/// - Proper callback patterns for state changes
///
/// WIDGET DESIGN PRINCIPLES:
/// 1. **Single Responsibility** - Just handles numeric input
/// 2. **Controlled Component** - Parent owns the value, widget reports changes
/// 3. **Configurable** - Supports horizontal/vertical layout, custom ranges
/// 4. **Accessible** - Clear visual feedback for enabled/disabled states
/// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:spades/colors.dart';

/// A Cupertino-styled numeric stepper with increment/decrement buttons.
///
/// FLUTTER CONCEPT: Controlled vs Uncontrolled Components
/// This is a "controlled" component - the parent widget owns the `value`
/// state and passes it down. The stepper reports changes via callbacks
/// but doesn't manage its own state.
///
/// CONTROLLED (this widget):
/// ```dart
/// NumericStepper(
///   value: myValue,           // Parent owns the state
///   onIncrement: () => setState(() => myValue++),  // Parent handles changes
/// )
/// ```
///
/// UNCONTROLLED (alternative pattern):
/// ```dart
/// NumericStepper(
///   initialValue: 5,
///   onChanged: (newValue) => print(newValue),  // Widget manages internal state
/// )
/// ```
///
/// We chose controlled because:
/// - Parent has full control over validation
/// - Easier to coordinate with other widgets
/// - State is lifted up, matching Riverpod architecture
class NumericStepper extends StatelessWidget {
  /// The current value to display.
  final int value;

  /// Minimum allowed value (inclusive).
  final int min;

  /// Maximum allowed value (inclusive).
  final int max;

  /// Amount to change per button press (not currently used but extensible).
  final int step;

  /// Layout direction: horizontal (side-by-side) or vertical (stacked).
  final Axis direction;

  /// Called when the decrement button is pressed.
  /// Should decrease the value by [step] (or handle it appropriately).
  ///
  /// DART CONCEPT: VoidCallback
  /// `VoidCallback` is a typedef for `void Function()` - a function that
  /// takes no parameters and returns nothing. It's the standard type for
  /// button press handlers.
  final VoidCallback? onDecrement;

  /// Called when the increment button is pressed.
  final VoidCallback? onIncrement;

  /// Creates a NumericStepper widget.
  ///
  /// DART CONCEPT: Constructor Parameter Styles
  /// - `required this.value` - Named, required, stored in field
  /// - `this.min = 0` - Named, optional with default, stored in field
  /// - `this.onDecrement` - Named, optional nullable, stored in field
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
    // Get the current text style from the theme for consistency
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    /// Helper function to build a stepper button.
    ///
    /// DART CONCEPT: Local Functions
    /// Functions can be defined inside other functions. They can access
    /// variables from the enclosing scope (closure). This is useful for
    /// DRY code within a single method.
    Widget buildButton(IconData icon, bool enabled, VoidCallback? onPressed) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // Disable button when not enabled (shows visual feedback automatically)
        onPressed: enabled ? onPressed : null,
        child: Icon(
          icon,
          size: 18,
          // Visual feedback: accent when enabled, muted when disabled
          color: enabled ? AppColors.accent : AppColors.textMuted,
        ),
      );
    }

    final bool isHorizontal = direction == Axis.horizontal;

    // Check if buttons should be enabled based on min/max bounds
    final bool canDecrement = value > min;
    final bool canIncrement = value < max;

    // Build the value display text
    final valueDisplay = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '$value',
        style: textStyle.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );

    // FLUTTER CONCEPT: Container Decoration
    // BoxDecoration allows styling containers with:
    // - Solid colors, gradients, or images
    // - Border radius (rounded corners)
    // - Borders with color and width
    // - Shadows for elevation effect
    return Container(
      decoration: BoxDecoration(
        // Elevated surface color for depth
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        // Subtle border for definition
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: isHorizontal
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: isHorizontal
          // Horizontal layout: [−] value [+]
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildButton(CupertinoIcons.minus, canDecrement, onDecrement),
                Expanded(child: Center(child: valueDisplay)),
                buildButton(CupertinoIcons.plus, canIncrement, onIncrement),
              ],
            )
          // Vertical layout: [+] / value / [−]
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildButton(CupertinoIcons.plus, canIncrement, onIncrement),
                valueDisplay,
                buildButton(CupertinoIcons.minus, canDecrement, onDecrement),
              ],
            ),
    );
  }
}
