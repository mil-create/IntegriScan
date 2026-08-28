import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_colors.dart';
import 'theme/auth_provider.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'widgets/enhanced_loading.dart';
import 'services/hive_service.dart';

void main() async {
  debugPrint('Main entry point');
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.init();

  runApp(const IntegriScanApp());
}

class IntegriScanApp extends StatelessWidget {
  const IntegriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final AppColors colors = themeProvider.isDarkMode
              ? AppColors.dark
              : AppColors.light;
          return MaterialApp(
            title: 'IntegriScan',
            debugShowCheckedModeBanner: false,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: colors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: colors.accent,
                brightness: Brightness.light,
              ),
              splashFactory: InkRipple.splashFactory,
              extensions: [colors],
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: colors.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: colors.accent,
                brightness: Brightness.dark,
              ),
              splashFactory: InkRipple.splashFactory,
              extensions: [colors],
            ),
            // Define routes for authentication screens
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper widget that handles authentication state
/// Shows auth screens when not authenticated, main app when authenticated
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading indicator while checking auth state
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: EnhancedLoading(type: LoadingType.pulse),
        ),
      );
    }

    // If not authenticated, show login screen
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // If authenticated, show main app
    return const MainShell();
  }
}