import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:convert';
import 'package:vibration/vibration.dart';

enum TimerMode { work, rest }

// Pomodoro kaydı için sınıf
class PomodoroRecord {
  final int id;
  final int duration;
  final DateTime date;
  final bool completed;
  final String? note;

  PomodoroRecord({
    required this.id,
    required this.duration,
    required this.date,
    required this.completed,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'duration': duration,
    'date': date.toIso8601String(),
    'completed': completed,
    'note': note,
  };

  factory PomodoroRecord.fromJson(Map<String, dynamic> json) => PomodoroRecord(
    id: json['id'],
    duration: json['duration'],
    date: DateTime.parse(json['date']),
    completed: json['completed'],
    note: json['note'],
  );
}

// İstatistik sınıfı
class Stats {
  final int total;
  final int completed;
  final int totalMinutes;

  Stats({
    required this.total,
    required this.completed,
    required this.totalMinutes,
  });
}

// İstatistik özeti sınıfı
class StatsOverview {
  final Stats today;
  final Stats week;
  final Stats month;
  final Stats all;

  StatsOverview({
    required this.today,
    required this.week,
    required this.month,
    required this.all,
  });
}

class PomodoroSession {
  final DateTime startTime;
  final DateTime endTime;
  final int duration;

  PomodoroSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration,
  };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) => PomodoroSession(
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    duration: json['duration'],
  );
}

class TimerModel extends ChangeNotifier {
  Timer? _timer;
  bool _isRunning = false;
  int _timeLeft = 25 * 60; // 25 dakika
  TimerMode _currentMode = TimerMode.work;
  final int workDuration = 25 * 60; // 25 dakika
  final int breakDuration = 5 * 60; // 5 dakika
  bool _isDarkTheme = true;
  bool _isEditing = false;
  String _inputMinutes = '25';
  bool _showMenu = false;
  bool _showColon = true;
  String _currentScreen = 'timer';
  String _previousScreen = 'timer';
  List<PomodoroSession> _pomodoroHistory = [];
  bool _showDeleteConfirm = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _startTime;

  static const platform = MethodChannel('com.example.placeholder/vibrate');

  // Getter'lar
  int get timeLeft => _timeLeft;
  bool get isRunning => _isRunning;
  bool get isDarkTheme => _isDarkTheme;
  bool get isEditing => _isEditing;
  String get inputMinutes => _inputMinutes;
  bool get showMenu => _showMenu;
  String get currentScreen => _currentScreen;
  String get previousScreen => _previousScreen;
  List<PomodoroSession> get history => _pomodoroHistory;
  bool get showDeleteConfirm => _showDeleteConfirm;
  bool get showColon => _showColon;
  TimerMode get currentMode => _currentMode;

  // Tema değiştirme
  void toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    await _saveThemePreference();
    notifyListeners();
  }

  // Menü gösterme/gizleme
  void toggleMenu() {
    _showMenu = !_showMenu;
    notifyListeners();
  }

  // Ekran değiştirme
  void setScreen(String screen) {
    _previousScreen = _currentScreen;
    _currentScreen = screen;
    notifyListeners();
  }

  // Silme onayı gösterme/gizleme
  void toggleDeleteConfirm() {
    _showDeleteConfirm = !_showDeleteConfirm;
    notifyListeners();
  }

  // Timer'ı başlatma
  void startTimer() async {
    if (!_isRunning) {
      _isRunning = true;
      _startTime = DateTime.now();

      // Sistem UI'ı gizle
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [], // Tüm overlayleri gizle
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          _timeLeft--;
          notifyListeners();
        } else {
          timer.cancel();
          _onTimerComplete();
        }
      });

      // Ekranın kapanmasını engelle
      await WakelockPlus.enable();

      notifyListeners();
    }
  }

  // Timer'ı durdurma
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _timeLeft = _currentMode == TimerMode.work ? workDuration : breakDuration;
    notifyListeners();

    // Sistem UI'ı geri göster
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values, // Tüm overlayleri göster
    );

    // Ekran kilidini kaldır
    WakelockPlus.disable();
  }

  // Timer'ı sıfırlama
  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _timeLeft = _currentMode == TimerMode.work ? workDuration : breakDuration;
    _startTime = null;
    notifyListeners();
  }

  // Modu değiştirme
  void switchMode() {
    _currentMode = _currentMode == TimerMode.work ? TimerMode.rest : TimerMode.work;
    _timeLeft = _currentMode == TimerMode.work ? workDuration : breakDuration;
    _isRunning = false;
    notifyListeners();
  }

  // Düzenleme modunu aç/kapa
  void toggleEditing() {
    _isEditing = !_isEditing;
    if (_isEditing) {
      _inputMinutes = (_timeLeft ~/ 60).toString();
    }
    notifyListeners();
  }

  // Süreyi güncelle
  void updateDuration(String value) {
    _inputMinutes = value;
    notifyListeners();
  }

  // Düzenlemeyi kaydet
  void saveDuration() {
    if (_inputMinutes.isNotEmpty) {
      int minutes = int.tryParse(_inputMinutes) ?? 25;
      minutes = minutes.clamp(1, 60);
      _timeLeft = minutes * 60;
    }
    _isEditing = false;
    notifyListeners();
  }

  // Yeni kayıt ekle
  void addRecord({required bool completed, String? note}) {
    final now = DateTime.now();
    final session = PomodoroSession(
      startTime: now.subtract(Duration(minutes: _timeLeft ~/ 60)),
      endTime: now,
      duration: _timeLeft ~/ 60,
    );
    _pomodoroHistory.insert(0, session);
    _saveHistory();
    notifyListeners();
  }

  // Alarm sesini çal
  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Ses çalma hatası: $e');
      }
    }
  }

  // Zil sesini çal
  Future<void> playBellSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Ses çalma hatası: $e');
      }
    }
  }

  // Tema tercihini kaydet
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkTheme', _isDarkTheme);
    } catch (e) {
      if (kDebugMode) {
        print('Tema kaydetme hatası: $e');
      }
    }
  }

  // Geçmişi kaydet
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _pomodoroHistory.map((session) => session.toJson()).toList();
      await prefs.setStringList('pomodoro_history', 
        historyJson.map((json) => jsonEncode(json)).toList()
      );
    } catch (e) {
      if (kDebugMode) {
        print('Geçmiş kaydetme hatası: $e');
      }
    }
  }

  // Tema tercihini yükle
  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Tema yükleme hatası: $e');
      }
    }
  }

  // Geçmişi yükle
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStringList = prefs.getStringList('pomodoro_history');
      if (historyStringList != null) {
        final List<dynamic> historyJson = historyStringList.map((json) => jsonDecode(json)).toList();
        _pomodoroHistory = historyJson
            .map((json) => PomodoroSession.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geçmiş yükleme hatası: $e');
      }
    }
  }

  // Bildirimleri başlat
  Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'timer_channel',
          channelName: 'Timer Notifications',
          channelDescription: 'Timer için bildirimler',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
        ),
      ],
      debug: false,
    );

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        if (receivedAction.buttonKeyPressed == 'STOP') {
          stopTimer();
        }
      },
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // Bildirimi güncelle
  Future<void> _updateNotification() async {
    if (_isRunning) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'timer_channel',
          title: _currentMode == TimerMode.work ? 'Pomodoro Timer' : 'Mola',
          body: '${_formatTime(_timeLeft)} kaldı',
          category: NotificationCategory.Progress,
          notificationLayout: NotificationLayout.Default,
          autoDismissible: false,
          displayOnBackground: true,
          displayOnForeground: false,
          wakeUpScreen: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'STOP',
            label: 'Durdur',
          ),
        ],
      );
    } else {
      await AwesomeNotifications().cancel(1);
    }
  }

  void pauseTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      addRecord(completed: false);
    }
    _isRunning = false;
    _startTime = null;
    _updateNotification();
    notifyListeners();
  }

  String get timeString {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTime(int time) {
    int minutes = time ~/ 60;
    int seconds = time % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // İstatistikleri hesapla
  StatsOverview calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(today.year, today.month - 1, today.day);

    final todayRecords = _pomodoroHistory.where((record) => 
      record.startTime.isAfter(today) || record.startTime.isAtSameMomentAs(today)
    ).toList();

    final weekRecords = _pomodoroHistory.where((record) => 
      record.startTime.isAfter(weekAgo) || record.startTime.isAtSameMomentAs(weekAgo)
    ).toList();

    final monthRecords = _pomodoroHistory.where((record) => 
      record.startTime.isAfter(monthAgo) || record.startTime.isAtSameMomentAs(monthAgo)
    ).toList();

    return StatsOverview(
      today: Stats(
        total: todayRecords.length,
        completed: todayRecords.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).length,
        totalMinutes: todayRecords.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).fold(0, (sum, r) => sum + r.endTime.difference(r.startTime).inMinutes),
      ),
      week: Stats(
        total: weekRecords.length,
        completed: weekRecords.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).length,
        totalMinutes: weekRecords.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).fold(0, (sum, r) => sum + r.endTime.difference(r.startTime).inMinutes),
      ),
      month: Stats(
        total: monthRecords.length,
        completed: monthRecords.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).length,
        totalMinutes: monthRecords.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).fold(0, (sum, r) => sum + r.endTime.difference(r.startTime).inMinutes),
      ),
      all: Stats(
        total: _pomodoroHistory.length,
        completed: _pomodoroHistory.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).length,
        totalMinutes: _pomodoroHistory.where((r) => r.endTime.difference(r.startTime).inMinutes >= 25).fold(0, (sum, r) => sum + r.endTime.difference(r.startTime).inMinutes),
      ),
    );
  }

  // En verimli saatleri hesapla
  List<int> calculateMostProductiveHours() {
    final hourCounts = List.filled(24, 0);
    _pomodoroHistory
      .where((r) => r.endTime.difference(r.startTime).inMinutes >= 25)
      .forEach((record) {
        final hour = record.startTime.hour;
        hourCounts[hour]++;
      });
    
    final maxCount = hourCounts.reduce((a, b) => a > b ? a : b);
    return List.generate(24, (i) => i)
      .where((hour) => hourCounts[hour] > maxCount * 0.7)
      .toList()
      ..sort((a, b) => hourCounts[b].compareTo(hourCounts[a]));
  }

  // Timer durumunu kaydet
  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('timeLeft', _timeLeft);
      await prefs.setBool('isRunning', _isRunning);
      await prefs.setString('inputMinutes', _inputMinutes);
      await prefs.setInt('startTime', _startTime?.millisecondsSinceEpoch ?? 0);
    } catch (e) {
      if (kDebugMode) {
        print('Timer durumu kaydetme hatası: $e');
      }
    }
  }

  // Timer durumunu temizle
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timeLeft');
      await prefs.remove('isRunning');
      await prefs.remove('inputMinutes');
      await prefs.remove('startTime');
    } catch (e) {
      if (kDebugMode) {
        print('Timer durumu temizleme hatası: $e');
      }
    }
  }

  // Timer durumunu yükle
  Future<void> loadTimerState() async {
    try {
      // Her zaman varsayılan değerlerle başla
      _timeLeft = 25 * 60; // 25 dakika
      _inputMinutes = '25';
      _isRunning = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Timer durumu yükleme hatası: $e');
      }
      // Hata durumunda da varsayılan değerleri ayarla
      _timeLeft = 25 * 60;
      _inputMinutes = '25';
      _isRunning = false;
      notifyListeners();
    }
  }

  // Geçmişi temizle
  void clearHistory() {
    _pomodoroHistory.clear();
    _saveHistory();
    notifyListeners();
  }

  void setShowFinished(bool value) {
    // _showFinished = value;
    notifyListeners();
  }

  void _onTimerComplete() async {
    _isRunning = false;
    _timer?.cancel();
    _timeLeft = 25 * 60; // 25 dakika
    notifyListeners(); // Sayaç değiştiğinde hemen bildiriyoruz
    
    // Sistem UI'ı geri göster
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values, // Tüm overlayleri göster
    );
    
    // İki kez kısa titreşim
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
      await Future.delayed(const Duration(milliseconds: 300));
      Vibration.vibrate(duration: 200);
    }

    // Bildirim gönder
    await _sendNotification();

    notifyListeners(); // Son durumu da bildiriyoruz
  }

  Future<void> _sendNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'pomodoro_channel',
        title: 'Pomodoro Bitti!',
        body: 'Süre doldu. Tebrikler!',
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}