import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/authProvider.dart';
import 'providers/settingsProvider.dart';
import 'screens/splashScreen.dart';
import 'screens/welcomeScreen.dart';
import 'screens/auth/loginScreen.dart';
import 'screens/auth/registroScreen.dart';
import 'screens/inmuebles/arrendatario/listaInmueblesScreen.dart';
import 'screens/inmuebles/propietario/propietarioHomeScreen.dart';
import 'screens/inmuebles/arrendatario/arrendatarioHomeScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const UniHabApp());
}

class UniHabApp extends StatelessWidget {
  const UniHabApp({super.key});

  static const _verde = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'UniHab',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _verde),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/registro': (_) => const RegistroScreen(),
          '/arrendatario-home': (_) => const ArrendatarioHomeScreen(),
          '/propietario-home': (_) => const PropietarioHomeScreen(),
        },
      ),
    );
  }
}
