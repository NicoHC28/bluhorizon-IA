// Entrada de la app Flutter; configura temas y persiste modo claro/oscuro con SharedPreferences.

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "screens/chat_screen.dart";

const ColorScheme _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF6750A4),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE9DDFF),
  onPrimaryContainer: Color(0xFF22005D),
  secondary: Color(0xFF625B71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE8DEF8),
  onSecondaryContainer: Color(0xFF1E192B),
  tertiary: Color(0xFF7D5260),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8E4),
  onTertiaryContainer: Color(0xFF31111D),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFFDFBFF),
  onSurface: Color(0xFF1C1B1F),
  onSurfaceVariant: Color(0xFF49454F),
  outline: Color(0xFF7A757F),
  outlineVariant: Color(0xFFCAC4D0),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFD0BCFF),
  surfaceTint: Color(0xFF6750A4),
);

const ColorScheme _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD0BCFF),
  onPrimary: Color(0xFF381E72),
  primaryContainer: Color(0xFF4F378B),
  onPrimaryContainer: Color(0xFFEADDFF),
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF332D41),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFE8DEF8),
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF492532),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFD8E4),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  surface: Color(0xFF0F1013),
  onSurface: Color(0xFFE6E1E6),
  onSurfaceVariant: Color(0xFFCAC4D0),
  outline: Color(0xFF948F99),
  outlineVariant: Color(0xFF49454F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE6E1E6),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF6750A4),
  surfaceTint: Color(0xFFD0BCFF),
);

void main() {
  runApp(const BluhorizonApp());
}

class BluhorizonApp extends StatefulWidget {
  const BluhorizonApp({super.key});

  @override
  State<BluhorizonApp> createState() => _BluhorizonAppState();
}

class _BluhorizonAppState extends State<BluhorizonApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool("is_dark_mode") ?? false;
    if (!mounted) return;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleThemeMode() async {
    final nextMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {
      _themeMode = nextMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_dark_mode", nextMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Bluhorizon IA",
      theme: ThemeData(
        colorScheme: _lightScheme,
        scaffoldBackgroundColor: _lightScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: _lightScheme.surface,
          foregroundColor: _lightScheme.onSurface,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _lightScheme.primary,
            foregroundColor: _lightScheme.onPrimary,
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: _darkScheme,
        scaffoldBackgroundColor: _darkScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: _darkScheme.surface,
          foregroundColor: _darkScheme.onSurface,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _darkScheme.primaryContainer,
            foregroundColor: _darkScheme.onPrimaryContainer,
          ),
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: ChatScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleThemeMode,
      ),
    );
  }
}
