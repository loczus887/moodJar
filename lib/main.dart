import 'package:app/pages/home_page.dart';
import 'package:app/pages/login_screen.dart';
import 'package:app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc/auth_bloc.dart';
import 'bloc/theme_cubit/theme_cubit.dart';
import 'data/repositories/auth_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => ThemeCubit(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'Mood Jar',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFF8F8F8),
                cardColor: Colors.white,
                iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: Color(0xFF2D2D2D)),
                  titleTextStyle: TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                textTheme: const TextTheme(
                  titleLarge: TextStyle(color: Color(0xFF2D2D2D), fontSize: 20, fontWeight: FontWeight.bold),
                  bodyLarge: TextStyle(color: Color(0xFF2D2D2D)),
                  bodyMedium: TextStyle(color: Color(0xFF2D2D2D)),
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E),
                iconTheme: const IconThemeData(color: Colors.white),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: Colors.white),
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                textTheme: const TextTheme(
                  titleLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  bodyLarge: TextStyle(color: Colors.white),
                  bodyMedium: TextStyle(color: Colors.white),
                ),
              ),
              themeMode: themeMode,
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    return const HomeScreen();
                  }
                  if (state is Unauthenticated || state is AuthError || state is AuthLoading) {
                    return const LoginScreen();
                  }

                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}