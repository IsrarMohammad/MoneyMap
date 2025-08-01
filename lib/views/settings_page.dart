import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_settings.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();
    final settings =
        settingsVM.userSettings ?? UserSettings(); // Defaults if not loaded

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // THEME
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Theme'),
                  subtitle: Text(_themeLabel(settings.themeMode)),
                  trailing: DropdownButton<AppThemeMode>(
                    value: settings.themeMode,
                    onChanged: (mode) {
                      if (mode != null) settingsVM.updateThemeMode(mode);
                    },
                    items: AppThemeMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(_themeLabel(mode)),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 32),

                // NOTIFICATIONS
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive budget alerts and reminders'),
                  value: settings.notificationsEnabled,
                  onChanged: (val) => settingsVM.setNotificationsEnabled(val),
                ),
                const Divider(height: 32),

                // (OPTIONAL) CURRENCY, DATE FORMAT, etc.
                // ListTile(
                //   title: const Text('Currency'),
                //   subtitle: Text(settings.currency ?? 'USD'),
                //   onTap: () {
                //     // Show a dialog to pick supported currencies
                //   },
                // ),

                // --- You can add more preferences here as your app grows. ---
                const SizedBox(height: 24),
                Text(
                  'App Version: 1.0.0\nMade with Flutter',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }
}
