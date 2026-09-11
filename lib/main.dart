import 'package:aullet/repositories/category_viewmodel.dart';
import 'package:aullet/viewmodels/statistics_viewmodel.dart';
import 'package:aullet/views/statics/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aullet/viewmodels/auth_view_model.dart';
import 'package:aullet/viewmodels/profile_viewmodel.dart';
import 'package:aullet/views/auth/signin_view.dart';
import 'package:aullet/views/auth/signup_view.dart';
import 'package:aullet/views/home_view.dart';
import 'package:aullet/views/profile_page.dart';
import 'package:aullet/viewmodels/expense_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnnonKey == null) {
    throw Exception('Errore nel file .env!');
  }

  await Supabase.initialize(
    url: supabaseUrl, 
    anonKey: supabaseAnnonKey
    );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => StatisticsViewModel()),
      ],
      child: MaterialApp(
        title: 'Aullet',
        theme: ThemeData(useMaterial3: true),
        
        home: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data?.session != null) {
              return const HomeView();
            }
            return const LoginPage();
          },
        ),
        routes: {
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignUpPage(),
          '/home': (_) => const HomeView(),
          '/profile': (_) => const ProfilePage(),
          '/statistics': (_) => const StatisticsPage()
        },
      ),
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    
    final authVM = context.watch<AuthViewModel>();
    
    return authVM.isLoggedIn ? const HomeView() : const LoginPage();
  }
}



