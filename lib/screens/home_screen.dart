/// ============================================================================
/// home_screen.dart - Main Landing Screen
/// ============================================================================
///
/// The home screen is the entry point of the app, providing navigation to:
/// - Start a new game
/// - Continue the most recent game
/// - View past games
///
/// This file demonstrates several key Flutter/Dart concepts:
/// - ConsumerWidget for Riverpod integration
/// - Navigation with go_router
/// - Dialogs and user input collection
/// - Stateful dialog implementation
/// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';
import '../state.dart';

/// The home screen widget that shows the main menu.
///
/// RIVERPOD CONCEPT: ConsumerWidget
/// ConsumerWidget is Riverpod's alternative to StatelessWidget.
/// It provides a `ref` parameter in the build method for accessing providers.
///
/// WHEN TO USE:
/// - `ConsumerWidget` - Stateless widget that needs providers
/// - `ConsumerStatefulWidget` - Stateful widget that needs providers
/// - `Consumer` - Wrap part of a widget tree to access providers
///
/// The `ref` object provides:
/// - `ref.watch(provider)` - Subscribe to changes, rebuild when state changes
/// - `ref.read(provider)` - Read once without subscribing
/// - `ref.listen(provider, callback)` - React to changes without rebuilding
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // RIVERPOD: Watch the games list
    // This widget will rebuild whenever the games list changes.
    // `watch` creates a subscription that's automatically disposed.
    final games = ref.watch(gamesProvider);

    // Get the most recent game (if any) for "Continue" button
    // Games are sorted by updatedAt in descending order
    final lastGame = games.isNotEmpty ? games.first : null;

    // FLUTTER CONCEPT: CupertinoPageScaffold
    // The iOS-style equivalent of Material's Scaffold.
    // Provides the basic page structure with navigation bar support.
    return CupertinoPageScaffold(
      // Navigation bar with app branding
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface,
        border: null, // Remove default border for cleaner look
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spade icon for branding
            Icon(
              CupertinoIcons.suit_spade_fill,
              color: AppColors.accent,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Spades Scorer',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Container(
          // FLUTTER CONCEPT: LinearGradient
          // Creates a gradient from one color to another.
          // Used here for visual depth and polish.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface,
                AppColors.background,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero section with app description
                _buildHeroSection(),

                const SizedBox(height: 48),

                // Primary action: Start new game
                _buildPrimaryButton(
                  context: context,
                  ref: ref,
                  icon: CupertinoIcons.add_circled_solid,
                  label: 'Start New Game',
                  onPressed: () => _promptNewGame(context, ref),
                ),

                const SizedBox(height: 16),

                // Secondary action: Continue last game (if exists)
                if (lastGame != null) ...[
                  _buildSecondaryButton(
                    context: context,
                    icon: CupertinoIcons.play_fill,
                    label: 'Continue Last Game',
                    subtitle: '${lastGame.teams[0].name} vs ${lastGame.teams[1].name}',
                    onPressed: () => context.push('/play/${lastGame.id}'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tertiary action: View past games
                _buildSecondaryButton(
                  context: context,
                  icon: CupertinoIcons.list_bullet,
                  label: 'View Past Games',
                  subtitle: '${games.length} game${games.length == 1 ? '' : 's'} saved',
                  onPressed: () => context.push('/games'),
                ),

                const Spacer(),

                // Footer with app info
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the hero section with app branding and description.
  Widget _buildHeroSection() {
    return Column(
      children: [
        // Large spade icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            CupertinoIcons.suit_spade_fill,
            size: 40,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Track your Spades games',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Builds a primary (filled) action button.
  ///
  /// FLUTTER CONCEPT: Widget Composition
  /// Rather than having one massive build method, we extract logical
  /// pieces into helper methods. This improves readability and makes
  /// the widget tree easier to understand.
  Widget _buildPrimaryButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 18),
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(14),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a secondary (outlined) action button with optional subtitle.
  Widget _buildSecondaryButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the footer section.
  Widget _buildFooter() {
    return Text(
      'Made by Pim van Leeuwen',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
    );
  }

  /// Shows a dialog to collect player names and creates a new game.
  ///
  /// FLUTTER CONCEPT: Async Dialog Pattern
  /// Dialogs in Flutter return Futures that complete when the dialog closes.
  /// We use `await` to wait for the result, then process it.
  ///
  /// DART CONCEPT: Null Check Pattern
  /// The result might be null (user cancelled), so we check before proceeding.
  Future<void> _promptNewGame(BuildContext context, WidgetRef ref) async {
    // Show a full-screen modal sheet instead of a small dialog
    final names = await showCupertinoModalPopup<List<String>>(
      context: context,
      builder: (_) => const _NewGameSheet(),
    );

    // User cancelled or didn't enter all names
    if (names == null || names.length != 4) return;

    // Create the game and get its ID
    final id = await ref
        .read(gamesProvider.notifier)
        .createGame(playerNames: names);

    // FLUTTER CONCEPT: mounted Check
    // After an async gap, the widget might have been disposed.
    // Always check `mounted` before using context after await.
    if (!context.mounted) return;

    // FLUTTER CONCEPT: addPostFrameCallback
    // Schedules a callback to run after the current frame completes.
    // This ensures navigation happens after the dialog animation finishes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.push('/play/$id');
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NEW GAME SHEET - Beautiful Full-Screen Modal
// ═══════════════════════════════════════════════════════════════════════════

/// A beautifully designed sheet for entering player names when starting a new game.
///
/// FLUTTER CONCEPT: Modal Bottom Sheet
/// Instead of a cramped dialog, we use a larger sheet that slides up from
/// the bottom. This provides more space for inputs and feels more natural
/// on mobile devices.
class _NewGameSheet extends StatefulWidget {
  const _NewGameSheet();

  @override
  State<_NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends State<_NewGameSheet> {
  /// Controllers for each text input field.
  late final List<TextEditingController> _controllers;

  /// Focus nodes to manage keyboard navigation
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.suit_spade_fill,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Game',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter player names to get started',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Teams explanation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Partners sit across from each other:\nNorth & South vs East & West',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Player inputs
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildTeamSection(
                  teamName: 'Team 1',
                  teamColor: AppColors.teamA,
                  players: [
                    _PlayerInput(
                      position: 'North',
                      icon: CupertinoIcons.arrow_up,
                      controller: _controllers[0],
                      focusNode: _focusNodes[0],
                      onSubmitted: () => _focusNodes[1].requestFocus(),
                    ),
                    _PlayerInput(
                      position: 'South',
                      icon: CupertinoIcons.arrow_down,
                      controller: _controllers[2],
                      focusNode: _focusNodes[2],
                      onSubmitted: () => _focusNodes[3].requestFocus(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildTeamSection(
                  teamName: 'Team 2',
                  teamColor: AppColors.teamB,
                  players: [
                    _PlayerInput(
                      position: 'East',
                      icon: CupertinoIcons.arrow_right,
                      controller: _controllers[1],
                      focusNode: _focusNodes[1],
                      onSubmitted: () => _focusNodes[2].requestFocus(),
                    ),
                    _PlayerInput(
                      position: 'West',
                      icon: CupertinoIcons.arrow_left,
                      controller: _controllers[3],
                      focusNode: _focusNodes[3],
                      onSubmitted: _validateAndSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom action buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _validateAndSubmit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.play_fill,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start Game',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a team section with its players
  Widget _buildTeamSection({
    required String teamName,
    required Color teamColor,
    required List<_PlayerInput> players,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              teamName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...players.map((player) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: player,
        )),
      ],
    );
  }

  /// Validates input and submits the player names.
  void _validateAndSubmit() {
    final names = _controllers.map((c) => c.text.trim()).toList();

    if (names.any((n) => n.isEmpty)) {
      // Show a subtle feedback that names are required
      // For now, shake animation or highlight empty fields could be added
      return;
    }

    Navigator.of(context).pop(names);
  }
}

/// A styled player input field
class _PlayerInput extends StatelessWidget {
  final String position;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  const _PlayerInput({
    required this.position,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              placeholder: '$position player name',
              placeholderStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
              decoration: const BoxDecoration(), // Remove default decoration
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

