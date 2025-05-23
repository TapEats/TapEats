import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tapeats/presentation/screens/login_page.dart';
import 'package:tapeats/presentation/state_management/branch_context.dart';
import 'package:tapeats/presentation/state_management/cart_state.dart';
import 'package:tapeats/presentation/state_management/navbar_state.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';
import 'package:tapeats/services/notification_service.dart';
import 'package:tapeats/utils/env_loader.dart';
import 'package:tapeats/presentation/screens/splash_screen.dart';
import 'package:tapeats/presentation/screens/user_side/main_screen.dart';
import 'package:tapeats/services/handle_checkout.dart';

// Add RouteObserver instance at the top level
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await EnvLoader.load();

    print('=== APP INITIALIZATION ===');
    print('Environment loaded successfully');

    // Initialize Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    print('Supabase initialized successfully');

    // Check Razorpay keys
    final razorpayKeyId = dotenv.env['RAZORPAY_KEY_ID'];
    final razorpaySecret = dotenv.env['RAZORPAY_KEY_SECRET'];
    
    if (razorpayKeyId?.isNotEmpty == true) {
      print('Razorpay Key ID found: ${razorpayKeyId!.substring(0, 8)}...');
      if (razorpayKeyId.startsWith('rzp_test_')) {
        print('✅ Using test mode keys');
      } else if (razorpayKeyId.startsWith('rzp_live_')) {
        print('⚠️ Using live mode keys');
      } else {
        print('❌ Invalid key format');
      }
    } else {
      print('❌ Razorpay Key ID not found');
    }

    // Initialize notification service
    final notificationService = NotificationService();
    notificationService.initialize();

    // Initialize payment service
    initializePaymentService();
    print('Payment service initialized');

    print('=== APP READY ===');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartState()),
          ChangeNotifierProvider(create: (_) => SliderState()),
          ChangeNotifierProvider(create: (_) => NavbarState()),
          ChangeNotifierProvider(create: (_) => BranchContext()),
          ChangeNotifierProvider.value(value: notificationService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('❌ App initialization failed: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('App initialization failed'),
              const SizedBox(height: 8),
              Text('Error: $e'),
            ],
          ),
        ),
      ),
    ));
  }
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
      // Current routes:
      routes: {
        '/': (context) => const SplashScreen(selectedIndex: 0),
        '/auth/login': (context) => const LoginPage(),
        '/home': (context) => MainScreen(),
        
        // Add these new routes for restaurant pages:
        '/restaurant': (context) => MainScreen(), // This will use NavbarState to show restaurant pages
        '/restaurant/home': (context) => MainScreen(),
        '/restaurant/orders': (context) {
          // Pre-select the Orders tab (index 1) when navigating here
          final navbarState = Provider.of<NavbarState>(context, listen: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navbarState.updateIndex(1);
          });
          return MainScreen();
        },
        '/admin': (context) {
          // For admin users, update NavbarState to select the admin tab (index 0)
          final navbarState = Provider.of<NavbarState>(context, listen: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navbarState.updateIndex(0);
          });
          return MainScreen();
        },
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