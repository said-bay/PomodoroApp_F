import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final theme = Theme.of(context);

    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        return WillPopScope(
          onWillPop: () async {
            if (timer.currentScreen != 'home') {
              timer.setScreen('home');
              return false; // Uygulamadan çıkma
            }
            return true; // Ana ekrandaysa uygulamadan çık
          },
          child: Scaffold(
            backgroundColor: theme.colorScheme.background,
            body: Stack(
              children: [
                // Ana içerik
                Column(
                  children: [
                    // Sayaç
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            if (!timer.isEditing && !timer.isRunning) {
                              timer.toggleEditing();
                            }
                          },
                          child: timer.isEditing
                              ? Container(
                                  width: size.width * (isPortrait ? 0.5 : 0.3),
                                  height: isPortrait ? size.height * 0.1 : size.height * 0.2,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      autofocus: true,
                                      style: TextStyle(
                                        color: theme.colorScheme.onBackground,
                                        fontSize: isPortrait
                                            ? size.width * 0.12
                                            : size.height * 0.25,
                                        fontWeight: FontWeight.w300,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '${timer.inputMinutes} dk',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onBackground.withOpacity(0.5),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (value) {
                                        if (int.tryParse(value) != null) {
                                          final minutes = int.parse(value);
                                          if (minutes > 0 && minutes <= 180) {
                                            timer.updateDuration(value);
                                            timer.saveDuration();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                )
                              : Text(
                                  timer.timeString,
                                  style: TextStyle(
                                    fontSize: isPortrait
                                        ? size.width * 0.25
                                        : size.height * 0.6,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: 4,
                                    color: theme.colorScheme.onBackground.withOpacity(0.9),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Başlat/Durdur butonu
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
                // Menü butonu
                Positioned(
                  top: 40,
                  right: 20,
                  child: PopupMenuButton<String>(
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
