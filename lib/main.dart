// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:retierment/screens/financialOnborading.dart';
import 'firebase_options.dart'; // Import generated options

// Your existing imports
import 'providers/auth_provider.dart';
import 'providers/financial_provider.dart';
import 'providers/ai_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<FinancialProvider>(
          create: (_) => FinancialProvider(),
        ),
        ChangeNotifierProvider<AIProvider>(create: (_) => AIProvider()),
      ],
      child: MaterialApp(
        title: 'RetireWise Co-pilot',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => MainHomeScreen(),
          '/onboarding': (BuildContext context) => OnboardingScreen(),
          '/questionnaire':
              (BuildContext context) => RetirementQuestionnaireScreen(),
        },
      ),
    );
  }
}
