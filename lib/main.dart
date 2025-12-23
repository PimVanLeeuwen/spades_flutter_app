import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'colors.dart';
import 'game_repository.dart';
import 'screens/games_screen.dart';
import 'screens/home_screen.dart';
import 'screens/play_screen.dart';

final theme = CupertinoThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  textTheme: const CupertinoTextThemeData(
    textStyle: TextStyle(color: AppColors.textPrimary),
    actionTextStyle: TextStyle(color: AppColors.textPrimary),
    navTitleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    navLargeTitleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 34,
      fontWeight: FontWeight.bold,
    ),
  ),
);

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/games', builder: (_, _) => const GamesScreen()),
    GoRoute(
      path: '/play/:id',
      builder: (ctx, st) => PlayScreen(gameId: st.pathParameters['id']!),
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameRepository().init();

  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      title: 'Spades',
      theme: theme,
      routerConfig: _router, // <- use the global router here
    );
  }
}
