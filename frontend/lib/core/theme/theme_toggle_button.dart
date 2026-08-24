import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

/// A compact icon-button theme toggle, meant for an AppBar action.
/// Drop this into any role's screen — it reads/writes the same shared
/// ThemeProvider, so switching in one screen applies app-wide.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return IconButton(
      tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey<bool>(themeProvider.isDarkMode),
        ),
      ),
      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
    );
  }
}

/// A fuller settings-style row (icon + label + switch), for a Settings
/// screen rather than an app bar.
class ThemeSettingRow extends StatelessWidget {
  const ThemeSettingRow({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ListTile(
      leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
      title: const Text('Dark mode'),
      subtitle: const Text('Switch between light and dark appearance'),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
      ),
    );
  }
}
