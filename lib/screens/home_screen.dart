import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                onSelected: (value) {
                  if (value == 'stats') {
                    timer.setScreen('stats');
                  } else if (value == 'history') {
                    timer.setScreen('history');
                  } else if (value == 'settings') {
                    timer.setScreen('settings');
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'stats',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart, 
                          color: theme.colorScheme.onBackground.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text('İstatistikler'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history,
                          color: theme.colorScheme.onBackground.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text('Geçmiş'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings,
                          color: theme.colorScheme.onBackground.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text('Ayarlar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Zamanlayıcı Metni
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: timer.toggleEditing,
                      child: timer.isEditing
                          ? SizedBox(
                              width: size.width * (isPortrait ? 0.8 : 0.6),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: isPortrait
                                      ? size.width * 0.15
                                      : size.height * 0.15,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: timer.inputMinutes,
                                  errorStyle: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 14,
                                  ),
                                ),
                                onSubmitted: (value) {
                                  if (int.tryParse(value) != null) {
                                    final minutes = int.parse(value);
                                    if (minutes > 0 && minutes <= 180) {
                                      timer.setTime(value);
                                    }
                                  }
                                },
                              ),
                            )
                          : Text(
                              timer.timeString,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isPortrait
                                    ? size.width * 0.25
                                    : size.height * 0.25,
                                fontWeight: FontWeight.w200,
                                letterSpacing: 4,
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.9),
                              ),
                            ),
                    ),
                  ),
                ),

                // Başlat/Durdur Butonu
                Container(
                  width: isPortrait ? size.width * 0.35 : size.width * 0.25,
                  height: 50,
                  margin: EdgeInsets.only(
                    bottom: isPortrait ? size.height * 0.05 : size.height * 0.03,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: timer.isRunning ? timer.stopTimer : timer.startTimer,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      timer.isRunning ? 'Durdur' : 'Başlat',
                      style: TextStyle(
                        color: theme.colorScheme.primary.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
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
