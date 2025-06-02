import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pantallas/login_screen.dart';
import 'pantallas/home_screen.dart';
import 'pantallas/admin_panel_screen.dart';
import 'pantallas/detalle_clase_screen.dart';
import 'pantallas/mis_reservas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyATWZ2i7G-ijQc7574cLoBXuhV5Ja-q5_k",
        authDomain: "fitreserve2307.firebaseapp.com",
        projectId: "fitreserve2307",
        storageBucket: "fitreserve2307.appspot.com",
        messagingSenderId: "894303775154",
        appId: "1:894303775154:web:7fffc1e978ca7e08985cab",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitReserve',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminPanelScreen(),
        '/detalle': (context) => const DetalleClaseScreen(),
        '/mis_reservas': (context) => const MisReservasScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
