import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/timer_model.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final timerModel = TimerModel();
  await timerModel.loadThemePreference();  // Tema tercihini yükle
  await timerModel.loadHistory();          // Geçmişi yükle
  await timerModel.initNotifications();    // Bildirimleri başlat
  await timerModel.loadTimerState();       // Timer durumunu yükle

  // Türkçe dil desteğini başlat
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  
  // Uygulama arkaplanda kapatıldığında bildirimleri temizle
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.detached.toString()) {
      await AwesomeNotifications().cancelAll();
    }
    return null;
  });
  
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
        return WillPopScope(
          onWillPop: () async {
            if (timer.currentScreen != 'timer') {
              timer.setScreen('timer');
              return false;
            }
            return true;
          },
          child: MaterialApp(
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
          ),
        );
      },
    );
  }
}
