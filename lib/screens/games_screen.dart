/// ============================================================================
/// games_screen.dart - Game History & Management Screen
/// ============================================================================
///
/// This screen displays a list of all saved games and allows users to:
/// - View game summaries (teams, hands played, last update)
/// - Open a game to continue scoring
/// - Delete games they no longer need
///
/// FLUTTER CONCEPTS DEMONSTRATED:
/// - ListView.separated for efficient scrolling lists
/// - Custom list tile widgets
/// - Confirmation dialogs for destructive actions
/// - Empty state handling
/// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../colors.dart';
import '../models.dart';
import '../state.dart';

/// Screen displaying the list of all saved games.
///
/// FLUTTER CONCEPT: ConsumerWidget
/// We use ConsumerWidget to access Riverpod state. This widget watches
/// the gamesProvider and rebuilds whenever the games list changes.
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the games list - rebuilds when games are added/removed/updated
    final games = ref.watch(gamesProvider);

    return CupertinoPageScaffold(
      // FLUTTER CONCEPT: CupertinoNavigationBar
      // iOS-style navigation bar with automatic back button handling,
      // large titles support, and scroll-to-collapse behavior.
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface,
        border: null,
        // Leading widget - custom back button
        leading: CupertinoNavigationBarBackButton(
          color: AppColors.accent,
          onPressed: () => context.go('/'),
        ),
        middle: Text(
          'Game History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: SafeArea(
          // Conditional rendering based on whether games exist
          child: games.isEmpty
              ? _buildEmptyState()
              : _buildGamesList(games, ref),
        ),
      ),
    );
  }

  /// Builds the empty state view when no games exist.
  ///
  /// UI/UX CONCEPT: Empty States
  /// A good empty state should:
  /// 1. Explain why the list is empty
  /// 2. Guide users on how to add items
  /// 3. Not feel like an error or broken state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.suit_spade,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No games yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new game from the home screen',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable list of game tiles.
  ///
  /// FLUTTER CONCEPT: ListView.separated
  /// ListView.separated is an efficient way to build scrolling lists with
  /// separators between items. Unlike ListView.builder + manual separators,
  /// it handles the edge cases (no separator after last item) automatically.
  ///
  /// It's "efficient" because:
  /// - Only builds visible items (lazy loading)
  /// - Recycles widgets as you scroll
  /// - Perfect for lists of any size
  Widget _buildGamesList(List<Game> games, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      // itemBuilder creates each list item on demand
      itemBuilder: (context, index) => _GameTile(
        game: games[index],
        onDelete: () => _confirmDelete(context, ref, games[index]),
      ),
      // separatorBuilder creates the space between items
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: games.length,
    );
  }

  /// Shows a confirmation dialog before deleting a game.
  ///
  /// UI/UX CONCEPT: Destructive Action Confirmation
  /// Always confirm before irreversible actions like delete.
  /// The dialog should:
  /// - Clearly state what will be deleted
  /// - Make the dangerous action visually distinct (red)
  /// - Default to the safe action (Cancel)
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Game game,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Game?'),
        content: Text(
          'This will permanently delete the game between '
          '${game.teams[0].name} and ${game.teams[1].name}.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Proceed with deletion if confirmed
    if (confirmed == true) {
      ref.read(gamesProvider.notifier).delete(game.id);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GAME TILE WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// A single game item in the list.
///
/// WIDGET DESIGN: Separation of Concerns
/// This is extracted as a separate widget because:
/// 1. It has its own visual design/layout
/// 2. It could be reused elsewhere
/// 3. It keeps the parent widget cleaner
/// 4. If it needed state, it could become stateful independently
class _GameTile extends StatelessWidget {
  /// The game to display.
  final Game game;

  /// Callback when delete is requested (after confirmation in parent).
  final VoidCallback onDelete;

  const _GameTile({required this.game, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Format the date for display using a simple helper
    final updatedText = _formatDate(game.updatedAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
        // Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content area - tappable to open game
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.push('/play/${game.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Game icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.suit_spade_fill,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Game details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team names
                        Text(
                          '${game.teams[0].name} vs ${game.teams[1].name}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Metadata row
                        Row(
                          children: [
                            _buildMetaBadge(
                              icon: CupertinoIcons.hand_raised_fill,
                              label: '${game.hands.length} hands',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                updatedText,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron indicator
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Container(
            height: 1,
            color: AppColors.secondary.withValues(alpha: 0.2),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: onDelete,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.trash,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a small metadata badge (icon + text).
  Widget _buildMetaBadge({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Formats a DateTime into a human-readable string.
///
/// DART CONCEPT: Extension Methods Alternative
/// Instead of using an extension method on DateTime, we use a simple
/// top-level function. Extensions would look like:
/// ```dart
/// extension DateTimeFormatting on DateTime {
///   String formatted() => '...';
/// }
/// // Usage: date.formatted()
/// ```
///
/// For a simple utility, a function is more straightforward.
String _formatDate(DateTime date) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final month = months[date.month - 1];
  final day = date.day;
  final year = date.year;
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$month $day, $year • $hour:$minute';
}
