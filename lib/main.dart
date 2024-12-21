import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/timer_model.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final timerModel = TimerModel();
  await timerModel.initNotifications();
  await timerModel.loadThemePreference();
  await timerModel.loadClockOnlyModePreference();
  await timerModel.loadHistory();
  await timerModel.loadTimerState();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => timerModel,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        return MaterialApp(
          title: 'Pomodoro Timer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: timer.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          home: Builder(
            builder: (context) {
              switch (timer.currentScreen) {
                case 'history':
                  return const HistoryScreen();
                case 'stats':
                  return const StatsScreen();
                case 'settings':
                  return const SettingsScreen();
                default:
                  return const HomeScreen();
              }
            },
          ),
        );
      },
    );
  }
}
