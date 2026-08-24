import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Add more app-wide providers here as features are built
        // (AuthProvider, etc.)
      ],
      child: const JRaphaApp(),
    ),
  );
}

class JRaphaApp extends StatelessWidget {
  const JRaphaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'JRapha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary landing screen — replace with the real login/routing flow
/// once the auth screens are built.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JRapha'),
        actions: const [Padding(padding: EdgeInsets.only(right: 8), child: _ThemeToggleInline())],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('JRapha', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text('Hospital Management System', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// Inline stand-in so this file compiles before theme_toggle_button.dart
// is wired in — swap for the real ThemeToggleButton widget once
// core/theme/theme_toggle_button.dart is in place.
class _ThemeToggleInline extends StatelessWidget {
  const _ThemeToggleInline();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return IconButton(
      tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
    );
  }
}
