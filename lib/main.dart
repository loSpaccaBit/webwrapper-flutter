import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'config/config_parser.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load configuration from YAML
  final AppConfig config = await ConfigParser.loadConfig();

  // Set preferred orientations (portrait only for mobile app feel)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(WebWrapApp(config: config));
}

/// Main application widget
class WebWrapApp extends StatelessWidget {
  final AppConfig config;

  const WebWrapApp({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.app.name,
      debugShowCheckedModeBanner: false,
      themeMode: config.theme.mode,
      theme: ThemeData(
        primaryColor: config.theme.light.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.theme.light.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primaryColor: config.theme.dark.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.theme.dark.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(config: config),
    );
  }
}
