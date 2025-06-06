import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/login_page.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/favorites_state.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/utils/env_loader.dart';
import 'package:tapeats/presentation/screens/splash_screen.dart';
import 'package:tapeats/presentation/screens/user_side/main_screen.dart';

// Add RouteObserver instance at the top level
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvLoader.load();

  // Initialize Supabase and handle missing .env keys
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => SliderState()),
        ChangeNotifierProvider(create: (_) => NavbarState()),
        ChangeNotifierProvider(create: (_) => FavoritesState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TapEats',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      navigatorObservers: [routeObserver],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(selectedIndex: 0),
        '/auth/login': (context) => const LoginPage(),
        '/home': (context) => MainScreen(),
      },
      // Handle undefined routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(selectedIndex: 0),
        );
      },
      // Optional: Add onGenerateRoute for dynamic routes if needed
      onGenerateRoute: (settings) {
        // Handle any dynamic routes here
        return null;
      },
    );
  }
}