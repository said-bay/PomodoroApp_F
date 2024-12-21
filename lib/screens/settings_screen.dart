import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import 'clock_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        return WillPopScope(
          onWillPop: () async {
            timer.setScreen('timer');
            return false;
          },
          child: Scaffold(
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
                  leading: const Icon(Icons.watch_later_outlined),
                  title: const Text('Saat Modu'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClockScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Karanlık Mod'),
                  trailing: Switch(
                    value: timer.isDarkTheme,
                    onChanged: (_) => timer.toggleTheme(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}