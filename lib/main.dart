import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme/app_theme.dart';
import 'config/language/app_localizations.dart';
import 'core/routes/app_routes.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/movie_detail_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forget_password_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/home/data/models/movie_model.dart';

import 'providers/splash_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'core/prefs_manager/prefs_manager.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/home/data/repositories/movie_repository.dart';
import 'features/home/data/datasources/yts_api_service.dart';
import 'providers/movie_provider.dart';
import 'core/widgets/auth_sync_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  final prefsManager = await PrefsManager.getInstance();
  final movieRepository = MovieRepository(YtsApiService());
  runApp(MyApp(prefsManager: prefsManager, movieRepository: movieRepository));
}

class MyApp extends StatelessWidget {
  final PrefsManager prefsManager;
  final MovieRepository movieRepository;

  const MyApp({
    super.key,
    required this.prefsManager,
    required this.movieRepository,
  });

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(prefsManager);

    return MultiProvider(
      providers: [
        Provider<MovieRepository>.value(value: movieRepository),
        ChangeNotifierProvider(
          create: (_) => MovieProvider(movieRepository)..loadHomeData(),
        ),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: AuthSyncWidget(
        child: MaterialApp(
          title: 'Movies App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en', ''), Locale('ar', '')],
          locale: const Locale('en'),
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.onboarding: (_) => const OnboardingFlowScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.forgetPassword: (_) => const ForgetPasswordScreen(),
            AppRoutes.home: (_) => const HomeScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.movieDetails) {
              final movie = settings.arguments as MovieModel;
              return MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movie: movie),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
