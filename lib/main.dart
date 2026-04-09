import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'provider/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase with deep link callback URL
  // The custom scheme io.tinysteps://login-callback is registered in AndroidManifest.xml
  // In Supabase dashboard > Auth > URL Configuration > Redirect URLs, add:
  //   io.tinysteps://login-callback
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: TinyStepsApp()));
}

class TinyStepsApp extends ConsumerWidget {
  const TinyStepsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'TinySteps',
      debugShowCheckedModeBanner: false,
      theme: sunriseLightTheme(),
      darkTheme: sunriseDarkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
