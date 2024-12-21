import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
              onPressed: () => timer.setScreen('timer'),
            ),
            title: Text(
              'Ayarlar',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          body: ListView(
            children: [
              ListTile(
                title: Text(
                  'Karanlık Tema',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                trailing: Switch(
                  value: timer.isDarkTheme,
                  onChanged: (_) => timer.toggleTheme(),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              ListTile(
                title: Text(
                  'Sadece Saat Göster (Yakında!)',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                trailing: Switch(
                  value: timer.isClockOnlyMode,
                  onChanged: (_) => timer.toggleClockOnlyMode(),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 