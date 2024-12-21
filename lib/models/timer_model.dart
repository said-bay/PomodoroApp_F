import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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

class TimerModel extends ChangeNotifier {
  Timer? _timer;
  bool _isRunning = false;
  int _timeLeft = 25 * 60; // 25 dakika
  TimerMode _currentMode = TimerMode.work;
  final int workDuration = 25 * 60; // 25 dakika
  final int breakDuration = 5 * 60; // 5 dakika
  bool _isDarkTheme = true;
  bool _isClockOnlyMode = false;
  bool _isEditing = false;
  String _inputMinutes = '25';
  bool _showMenu = false;
  String _currentScreen = 'timer';
  List<PomodoroRecord> _pomodoroHistory = [];
  bool _showDeleteConfirm = false;
  bool _showColon = true;
  bool _showFinished = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _startTime;

  // Getter'lar
  int get timeLeft => _timeLeft;
  bool get isRunning => _isRunning;
  bool get isDarkTheme => _isDarkTheme;
  bool get isClockOnlyMode => _isClockOnlyMode;
  bool get isEditing => _isEditing;
  String get inputMinutes => _inputMinutes;
  bool get showMenu => _showMenu;
  String get currentScreen => _currentScreen;
  List<PomodoroRecord> get history => _pomodoroHistory;
  bool get showDeleteConfirm => _showDeleteConfirm;
  bool get showColon => _showColon;
  bool get showFinished => _showFinished;
  TimerMode get currentMode => _currentMode;

  // Tema değiştirme
  void toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    await _saveThemePreference();
    notifyListeners();
  }

  // Saat modu değiştirme
  void toggleClockOnlyMode() async {
    _isClockOnlyMode = !_isClockOnlyMode;
    await _saveClockOnlyModePreference();
    notifyListeners();
  }

  // Menü gösterme/gizleme
  void toggleMenu() {
    _showMenu = !_showMenu;
    notifyListeners();
  }

  // Ekran değiştirme
  void setScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  // Silme onayı gösterme/gizleme
  void toggleDeleteConfirm() {
    _showDeleteConfirm = !_showDeleteConfirm;
    notifyListeners();
  }

  // Düzenleme modunu aç/kapa
  void toggleEditing() {
    if (!_isRunning) {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _inputMinutes = (_timeLeft ~/ 60).toString();
      }
      notifyListeners();
    }
  }

  // Dakika girişini güncelle
  void updateInputMinutes(String minutes) {
    _inputMinutes = minutes;
    notifyListeners();
  }

  // Bildirimleri başlat
  Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'timer_channel',
          channelName: 'Timer',
          channelDescription: 'Pomodoro Timer bildirimleri',
          defaultColor: Colors.red,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          locked: true,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          criticalAlerts: true,
        )
      ],
    );

    // Bildirim izinlerini kontrol et
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // İzin iste
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // Bildirimi güncelle
  Future<void> _updateNotification() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        return;
      }

      if (_isRunning) {
        final minutes = _timeLeft ~/ 60;
        final seconds = _timeLeft % 60;
        final currentMode = _currentMode == TimerMode.work ? 'Çalışma' : 'Mola';
        
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 0,
            channelKey: 'timer_channel',
            title: 'Pomodoro $currentMode',
            body: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.Default,
            locked: true,
            autoDismissible: false,
            displayOnBackground: true,
            displayOnForeground: true,
            wakeUpScreen: true,
            fullScreenIntent: true,
            criticalAlert: true,
          ),
        );
      } else {
        await AwesomeNotifications().cancel(0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Bildirim hatası: $e');
      }
    }
  }

  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      
      // Sistem UI'ı gizle ve navigation bar rengini ayarla
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
      ));
      
      // Ekranın kapanmasını engelle
      WakelockPlus.enable();
      
      // Timer başlangıç zamanını kaydet
      _startTime = DateTime.now();
      _saveTimerState();
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          _timeLeft--;
          _showColon = !_showColon;
          _updateNotification(); // Bildirimi güncelle
          notifyListeners();
        } else {
          _timer?.cancel();
          _isRunning = false;
          // Timer bittiğinde ekran kilidini kaldır
          WakelockPlus.disable();
          // Timer bittiğinde sistem UI'ı geri getir
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          AwesomeNotifications().cancel(0); // Bildirimi kaldır
          _handleTimerComplete();
        }
      });
      notifyListeners();
    }
  }

  void _addIncompleteRecord() {
    print('_addIncompleteRecord çağrıldı');
    print('_startTime: $_startTime');
    if (_startTime != null) {
      final elapsedMinutes = DateTime.now().difference(_startTime!).inMinutes;
      print('elapsedMinutes: $elapsedMinutes');
      if (elapsedMinutes > 0) {
        final newRecord = PomodoroRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          duration: int.parse(_inputMinutes),
          date: DateTime.now(),
          completed: false,
          note: '${elapsedMinutes}dk çalışıldı',
        );
        print('Yeni kayıt oluşturuldu: ${newRecord.note}');
        _pomodoroHistory.insert(0, newRecord);
        _saveHistory();
      } else {
        print('elapsedMinutes 0 olduğu için kayıt eklenmedi');
      }
    } else {
      print('_startTime null olduğu için kayıt eklenmedi');
    }
  }

  void pauseTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      _addIncompleteRecord();
    }
    _isRunning = false;
    _startTime = null;
    // Timer duraklatıldığında ekran kilidini kaldır
    WakelockPlus.disable();
    // Timer duraklatıldığında sistem UI'ı geri getir
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    
    _updateNotification();
    notifyListeners();
  }

  void resetTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      _addIncompleteRecord();
    }
    
    _timeLeft = 1500; // 25 dakika (25 * 60)
    _isRunning = false;
    _showColon = true;
    _currentMode = TimerMode.work;
    _startTime = null;
    _updateNotification();
    notifyListeners();
  }

  void stopTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      _addIncompleteRecord();
    }
    
    _isRunning = false;
    _timeLeft = workDuration;
    _startTime = null;
    // Timer durdurulduğunda ekran kilidini kaldır
    WakelockPlus.disable();
    _updateNotification();
    notifyListeners();
  }

  void setTime(String minutes) {
    if (int.tryParse(minutes) != null) {
      final newMinutes = int.parse(minutes);
      if (newMinutes > 0 && newMinutes <= 180) {
        _timer?.cancel();
        _timeLeft = newMinutes * 60;
        _inputMinutes = minutes;
        _isRunning = false;
        _isEditing = false;
        notifyListeners();
      }
    }
  }

  void _handleTimerComplete() async {
    _showFinished = true;
    notifyListeners();

    // Yeni pomodoro kaydı ekle
    final newRecord = PomodoroRecord(
      id: DateTime.now().millisecondsSinceEpoch,
      duration: int.parse(_inputMinutes),
      date: DateTime.now(),
      completed: true,
      note: 'Tamamlandı',
    );
    _pomodoroHistory.insert(0, newRecord);
    await _saveHistory();

    await _playAlarmSound();
    await Future.delayed(const Duration(seconds: 2));
    
    _showFinished = false;
    // Timer'ı sıfırla ama kayıt ekleme
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    
    _timeLeft = 1500; // 25 dakika (25 * 60)
    _isRunning = false;
    _showColon = true;
    _currentMode = TimerMode.work;
    _startTime = null;
    _updateNotification();
    notifyListeners();
  }

  // Geçmişi temizle
  void clearHistory() {
    _pomodoroHistory.clear();
    _saveHistory();
    notifyListeners();
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Ses çalma hatası: $e');
      }
    }
  }

  String get timeString {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    if (_showColon) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')} ${seconds.toString().padLeft(2, '0')}';
    }
  }

  // İstatistikleri hesapla
  StatsOverview calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(today.year, today.month - 1, today.day);

    final todayRecords = _pomodoroHistory.where((record) => 
      record.date.isAfter(today) || record.date.isAtSameMomentAs(today)
    ).toList();

    final weekRecords = _pomodoroHistory.where((record) => 
      record.date.isAfter(weekAgo) || record.date.isAtSameMomentAs(weekAgo)
    ).toList();

    final monthRecords = _pomodoroHistory.where((record) => 
      record.date.isAfter(monthAgo) || record.date.isAtSameMomentAs(monthAgo)
    ).toList();

    return StatsOverview(
      today: Stats(
        total: todayRecords.length,
        completed: todayRecords.where((r) => r.completed).length,
        totalMinutes: todayRecords.where((r) => r.completed).fold(0, (sum, r) => sum + r.duration),
      ),
      week: Stats(
        total: weekRecords.length,
        completed: weekRecords.where((r) => r.completed).length,
        totalMinutes: weekRecords.where((r) => r.completed).fold(0, (sum, r) => sum + r.duration),
      ),
      month: Stats(
        total: monthRecords.length,
        completed: monthRecords.where((r) => r.completed).length,
        totalMinutes: monthRecords.where((r) => r.completed).fold(0, (sum, r) => sum + r.duration),
      ),
      all: Stats(
        total: _pomodoroHistory.length,
        completed: _pomodoroHistory.where((r) => r.completed).length,
        totalMinutes: _pomodoroHistory.where((r) => r.completed).fold(0, (sum, r) => sum + r.duration),
      ),
    );
  }

  // En verimli saatleri hesapla
  List<int> calculateMostProductiveHours() {
    final hourCounts = List.filled(24, 0);
    _pomodoroHistory
      .where((r) => r.completed)
      .forEach((record) {
        final hour = record.date.hour;
        hourCounts[hour]++;
      });
    
    final maxCount = hourCounts.reduce((a, b) => a > b ? a : b);
    return List.generate(24, (i) => i)
      .where((hour) => hourCounts[hour] > maxCount * 0.7)
      .toList()
      ..sort((a, b) => hourCounts[b].compareTo(hourCounts[a]));
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

  // Saat modu tercihini kaydet
  Future<void> _saveClockOnlyModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isClockOnlyMode', _isClockOnlyMode);
    } catch (e) {
      if (kDebugMode) {
        print('Saat modu kaydetme hatası: $e');
      }
    }
  }

  // Geçmişi kaydet
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _pomodoroHistory.map((record) => record.toJson()).toList();
      await prefs.setString('pomodoroHistory', json.encode(historyJson));
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

  // Saat modu tercihini yükle
  Future<void> loadClockOnlyModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isClockOnlyMode = prefs.getBool('isClockOnlyMode') ?? false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Saat modu yükleme hatası: $e');
      }
    }
  }

  // Geçmişi yükle
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('pomodoroHistory');
      if (historyString != null) {
        final List<dynamic> historyJson = json.decode(historyString);
        _pomodoroHistory = historyJson
            .map((json) => PomodoroRecord.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geçmiş yükleme hatası: $e');
      }
    }
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

  // Modu değiştir
  void _switchMode() {
    _currentMode = _currentMode == TimerMode.work ? TimerMode.rest : TimerMode.work;
    _timeLeft = _currentMode == TimerMode.work ? workDuration : breakDuration;
    _updateNotification();
  }

  // Ses çal
  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Ses çalma hatası: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
} 