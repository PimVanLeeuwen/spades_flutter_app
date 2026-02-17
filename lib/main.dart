/// ============================================================================
/// main.dart - Application Entry Point & Configuration
/// ============================================================================
///
/// This is the entry point of the Flutter application. It demonstrates:
///
/// - Flutter app initialization and bootstrapping
/// - Cupertino (iOS-style) theming
/// - Declarative routing with go_router
/// - Riverpod state management setup
///
/// FLUTTER APPLICATION LIFECYCLE:
/// 1. Dart VM starts and calls `main()`
/// 2. Flutter bindings are initialized
/// 3. Async setup (database, etc.) completes
/// 4. Widget tree is built starting from `runApp()`
/// 5. First frame is rendered to the screen
/// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'colors.dart';
import 'game_repository.dart';
import 'screens/games_screen.dart';
import 'screens/home_screen.dart';
import 'screens/play_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// THEME CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

/// The global Cupertino theme for the entire app.
///
/// FLUTTER CONCEPT: CupertinoThemeData
/// Cupertino widgets follow iOS design guidelines. The theme controls:
/// - Colors (primary, background, etc.)
/// - Typography (text styles for different contexts)
/// - Default widget appearances
///
/// WHY CUPERTINO VS MATERIAL?
/// - Cupertino: iOS look and feel, cleaner for simple apps
/// - Material: Android/web look, more built-in components
/// - You can mix both, but consistency is usually preferred
///
/// DART CONCEPT: Top-Level Variables
/// Variables declared outside of any function or class are "top-level."
/// They're initialized lazily (when first accessed) unless marked `late`.
final theme = CupertinoThemeData(
  // Primary brand color used for buttons, selections, etc.
  primaryColor: AppColors.accent,

  // Background color for scaffolds (full-screen containers)
  scaffoldBackgroundColor: AppColors.background,

  // Comprehensive text styling for different UI contexts
  textTheme: CupertinoTextThemeData(
    // Default text style for body content
    textStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.2,
    ),

    // Style for interactive text (buttons, links)
    actionTextStyle: TextStyle(
      color: AppColors.accent,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),

    // Navigation bar title style
    navTitleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),

    // Large navigation bar title (iOS-style large titles)
    navLargeTitleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 34,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  ),

  // Default background for navigation bars
  barBackgroundColor: AppColors.surface,
);

// ═══════════════════════════════════════════════════════════════════════════
// ROUTING CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

/// Application router using go_router for declarative navigation.
///
/// GO_ROUTER OVERVIEW:
/// go_router is a declarative routing package that provides:
/// - URL-based routing (great for web, deep links)
/// - Type-safe route parameters
/// - Nested routing support
/// - Redirect guards for authentication
///
/// DECLARATIVE VS IMPERATIVE ROUTING:
/// - Imperative: `Navigator.push(context, MaterialPageRoute(...))`
/// - Declarative: `context.go('/play/123')` - URL describes the state
///
/// ROUTE STRUCTURE:
/// - `/` → Home screen (start new game, continue, view history)
/// - `/games` → List of all saved games
/// - `/play/:id` → Active game scoring screen (id is a path parameter)
final _router = GoRouter(
  routes: [
    // Home route - the default landing screen
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    // Games list route - view all saved games
    GoRoute(
      path: '/games',
      builder: (context, state) => const GamesScreen(),
    ),

    // Play route - active game with dynamic ID parameter
    //
    // FLUTTER CONCEPT: Path Parameters
    // The `:id` syntax defines a path parameter. When navigating to
    // `/play/abc123`, the `id` parameter will be `abc123`.
    //
    // Access via: `state.pathParameters['id']`
    // The `!` asserts it's non-null (safe here since route requires it)
    GoRoute(
      path: '/play/:id',
      builder: (context, state) => PlayScreen(
        gameId: state.pathParameters['id']!,
      ),
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// APPLICATION ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════

/// The main entry point of the application.
///
/// DART CONCEPT: Async main()
/// The `async` keyword allows using `await` for asynchronous operations.
/// This is necessary because:
/// - Database initialization is asynchronous
/// - Flutter bindings must be initialized before runApp()
///
/// FLUTTER CONCEPT: WidgetsFlutterBinding.ensureInitialized()
/// This must be called before any async operations that happen
/// before runApp(). It sets up the binding between Flutter and
/// the underlying platform (iOS, Android, Web, etc.).
Future<void> main() async {
  // Ensure Flutter is ready before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database (Hive)
  // This must complete before the app starts so game data is available
  await GameRepository().init();

  // Start the Flutter application
  //
  // RIVERPOD CONCEPT: ProviderScope
  // ProviderScope is the root widget for Riverpod. It:
  // - Creates the container that holds all provider state
  // - Must wrap the entire app (or the part using providers)
  // - Enables ref.watch/read to work in descendant widgets
  runApp(const ProviderScope(child: App()));
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// The root widget of the application.
///
/// FLUTTER CONCEPT: StatelessWidget
/// A StatelessWidget is a widget that doesn't have mutable state.
/// It's rebuilt when its parent rebuilds or when its inputs change,
/// but it never triggers its own rebuilds.
///
/// Use StatelessWidget when:
/// - The widget just displays data passed to it
/// - It doesn't need to track any internal state
/// - All state comes from inherited widgets or parameters
class App extends StatelessWidget {
  /// Creates the root App widget.
  ///
  /// FLUTTER CONCEPT: super.key
  /// The `key` parameter helps Flutter identify widgets during rebuilds.
  /// Passing it to `super` ensures proper widget identity tracking.
  /// Using `const` constructor makes this widget a compile-time constant.
  const App({super.key});

  /// Builds the widget tree for this widget.
  ///
  /// FLUTTER CONCEPT: build() Method
  /// This method is called whenever the widget needs to render.
  /// It should be pure (no side effects) and fast (no heavy computation).
  /// Returns a widget tree that describes the UI.
  @override
  Widget build(BuildContext context) {
    // CupertinoApp.router provides:
    // - Cupertino styling throughout the app
    // - Integration with go_router for navigation
    // - Theme propagation to all child widgets
    return CupertinoApp.router(
      // App title shown in task switchers, browser tabs, etc.
      title: 'Spades Scorer',

      // Apply our custom theme to all Cupertino widgets
      theme: theme,

      // Connect to go_router for declarative navigation
      routerConfig: _router,

      // Disable the debug banner in development
      debugShowCheckedModeBanner: false,
    );
  }
}
