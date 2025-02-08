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
  final bool completed;
  final int elapsedMinutes;

  PomodoroSession({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.completed,
    required this.elapsedMinutes,
  });

  bool get isCompleted => endTime.difference(startTime).inSeconds >= duration * 60;

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration,
    'completed': completed,
    'elapsedMinutes': elapsedMinutes,
  };

  factory PomodoroSession.fromJson(Map<String, dynamic> json) => PomodoroSession(
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    duration: json['duration'],
    completed: json['completed'],
    elapsedMinutes: json['elapsedMinutes'],
  );
}

class TimerModel extends ChangeNotifier {
  Timer? _timer;
  bool _isRunning = false;
  int _timeLeft = 25 * 60; // Bu varsayılan değer artık constructor'da güncellenecek
  static const int minDuration = 1;
  static const int maxDuration = 180;
  final int workDuration = 25 * 60; // 25 dakika
  DateTime? _startTime;
  int _initialTime = 25 * 60; // Bu varsayılan değer artık constructor'da güncellenecek
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

  // Constructor'da SharedPreferences'dan süreyi okuyacağız
  TimerModel() {
    _loadSavedDuration();
    loadThemePreference();
    loadTimerState();
  }

  // Kaydedilmiş süreyi yükle
  Future<void> _loadSavedDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDuration = prefs.getInt('timer_duration') ?? 25;
    _timeLeft = savedDuration * 60;
    _initialTime = savedDuration * 60;
    _inputMinutes = savedDuration.toString();
    notifyListeners();
  }

  // Süreyi güncelle ve kaydet
  void updateDuration(String minutes) async {
    if (int.tryParse(minutes) != null) {
      final duration = int.parse(minutes);
      if (duration >= minDuration && duration <= maxDuration) {
        _timeLeft = duration * 60;
        _initialTime = duration * 60;
        _inputMinutes = minutes;
        
        // Süreyi SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('timer_duration', duration);
        
        _isEditing = false;
        notifyListeners();
      }
    }
  }

  // Reset fonksiyonunu güncelle
  void reset() async {
    _isRunning = false;
    _timer?.cancel();
    _timeLeft = _initialTime; // Son kaydedilen süreye dön
    _startTime = null;
    await _clearTimerState();
    notifyListeners();
  }

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
    try {
      debugPrint('startTimer çağrıldı: _isRunning=$_isRunning, _timeLeft=$_timeLeft');
      
      if (_isRunning || _timeLeft <= 0) {
        debugPrint('Timer zaten çalışıyor veya süre bitmiş');
        return;
      }

      // Bildirim izinlerini kontrol et
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      debugPrint('Bildirim izni: $isAllowed');
      
      if (!isAllowed) {
        debugPrint('Bildirim izni isteniyor...');
        final granted = await AwesomeNotifications().requestPermissionToSendNotifications();
        if (!granted) {
          debugPrint('Bildirim izni reddedildi');
          return;
        }
      }

      _isRunning = true;
      _startTime = DateTime.now();
      _initialTime = _timeLeft;
      
      // Timer durumunu kaydet
      await _saveTimerState();
      debugPrint('Timer durumu kaydedildi');

      // Sistem UI'ı gizle
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [], // Tüm overlayleri gizle
      );
      debugPrint('Sistem UI gizlendi');

      // Ekranın kapanmasını engelle
      await WakelockPlus.enable();
      debugPrint('WakelockPlus etkinleştirildi');

      // İlk bildirimi göster
      await _updateNotification();
      debugPrint('İlk bildirim gösterildi');

      // Timer'ı başlat
      _timer?.cancel(); // Varolan timer'ı temizle
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!_isRunning) {
          timer.cancel();
          return;
        }

        if (_timeLeft > 0) {
          _timeLeft--;
          try {
            await _updateNotification();
            await _saveTimerState();
          } catch (e) {
            debugPrint('Timer güncelleme hatası: $e');
          }
          notifyListeners();
        } else {
          timer.cancel();
          await _onTimerComplete();
        }
      });

      notifyListeners();
      debugPrint('Timer başarıyla başlatıldı');
    } catch (e, stackTrace) {
      debugPrint('Timer başlatma hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Hata durumunda timer'ı temizle
      _isRunning = false;
      _timer?.cancel();
      _timer = null;
      _startTime = null;
      await _clearTimerState();
      notifyListeners();
    }
  }

  // Timer'ı durdurma
  void stopTimer() async {
    debugPrint('stopTimer çağrıldı: _isRunning=$_isRunning');
    
    if (!_isRunning) {
      debugPrint('Timer zaten durdurulmuş');
      return;
    }

    try {
      if (_startTime != null) {
        final elapsedMinutes = (_initialTime - _timeLeft) ~/ 60;
        final isCompleted = _timeLeft <= 0;
        
        final session = PomodoroSession(
          startTime: _startTime!,
          endTime: DateTime.now(),
          duration: _initialTime ~/ 60,
          completed: isCompleted,
          elapsedMinutes: elapsedMinutes,
        );
        
        // Sadece 1 dakikadan fazla çalışılmışsa kaydet
        if (elapsedMinutes >= 1) {
          _pomodoroHistory.insert(0, session);
          await _saveHistory();
          debugPrint('Oturum kaydedildi: $elapsedMinutes dakika');
        }
      }

      // Timer'ı temizle
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
      _timeLeft = _initialTime; // Son ayarlanan süreye dön
      _startTime = null;

      // Bildirimleri temizle
      await AwesomeNotifications().cancelAll();
      debugPrint('Bildirimler temizlendi');

      // Timer durumunu temizle
      await _clearTimerState();
      debugPrint('Timer durumu temizlendi');

      // Sistem UI'ı geri göster
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      debugPrint('Sistem UI gösterildi');

      // Ekran kilidini kaldır
      await WakelockPlus.disable();
      debugPrint('WakelockPlus devre dışı bırakıldı');

      notifyListeners();
      debugPrint('Timer başarıyla durduruldu');
    } catch (e) {
      debugPrint('Timer durdurma hatası: $e');
      // Hata olsa bile timer'ı durdurmaya çalış
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
      notifyListeners();
    }
  }

  // Timer'ı sıfırlama
  Future<void> resetTimer() async {
    _timer?.cancel();
    _isRunning = false;
    await _loadSavedDuration();
    _startTime = null;
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

  // Düzenlemeyi kaydet
  void saveDuration() {
    if (_inputMinutes.isNotEmpty) {
      int minutes = int.tryParse(_inputMinutes) ?? 25;
      minutes = minutes.clamp(minDuration, maxDuration);
      _timeLeft = minutes * 60;
      _initialTime = minutes * 60;
      _isEditing = false;
      notifyListeners();
    }
  }

  // Yeni kayıt ekle
  void addRecord({required bool completed, String? note}) {
    final now = DateTime.now();
    final session = PomodoroSession(
      startTime: now.subtract(Duration(minutes: _timeLeft ~/ 60)),
      endTime: now,
      duration: _timeLeft ~/ 60,
      completed: completed,
      elapsedMinutes: _timeLeft ~/ 60,
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
            channelKey: 'pomodoro_timer',
            channelName: 'Pomodoro Timer Bildirimleri',
            channelDescription: 'Pomodoro timer bildirimleri',
            defaultColor: Colors.red,
            ledColor: Colors.white,
            importance: NotificationImportance.Low,
            playSound: false,
            enableVibration: false,
            enableLights: false,
            onlyAlertOnce: true,
            criticalAlerts: false,
          ),
          // Tamamlanma bildirimi için ayrı bir kanal
          NotificationChannel(
            channelKey: 'pomodoro_complete',
            channelName: 'Pomodoro Tamamlanma Bildirimleri',
            channelDescription: 'Pomodoro tamamlandığında gönderilen bildirimler',
            defaultColor: Colors.green,
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            playSound: true,
            enableVibration: true,
            criticalAlerts: true,
            defaultRingtoneType: DefaultRingtoneType.Alarm,
            defaultPrivacy: NotificationPrivacy.Public,
          ),
        ],
        debug: false);

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
          channelKey: 'pomodoro_timer',
          title: 'Pomodoro Timer',
          body: 'Kalan süre: ${_formatDuration(Duration(seconds: _timeLeft))}',
          category: NotificationCategory.Progress,
          notificationLayout: NotificationLayout.Default,
          progress: ((_initialTime - _timeLeft) / _initialTime * 100).round(),
          displayOnForeground: true,
          displayOnBackground: true,
          locked: true,
          autoDismissible: false,
          showWhen: true,
          wakeUpScreen: false,
          criticalAlert: false,
        ),
      );
    } else {
      await AwesomeNotifications().cancel(1);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
        completed: todayRecords.where((r) => r.completed).length,
        totalMinutes: todayRecords.where((r) => r.completed).fold(0, (sum, r) => sum + r.elapsedMinutes),
      ),
      week: Stats(
        total: weekRecords.length,
        completed: weekRecords.where((r) => r.completed).length,
        totalMinutes: weekRecords.where((r) => r.completed).fold(0, (sum, r) => sum + r.elapsedMinutes),
      ),
      month: Stats(
        total: monthRecords.length,
        completed: monthRecords.where((r) => r.completed).length,
        totalMinutes: monthRecords.where((r) => r.completed).fold(0, (sum, r) => sum + r.elapsedMinutes),
      ),
      all: Stats(
        total: _pomodoroHistory.length,
        completed: _pomodoroHistory.where((r) => r.completed).length,
        totalMinutes: _pomodoroHistory.where((r) => r.completed).fold(0, (sum, r) => sum + r.elapsedMinutes),
      ),
    );
  }

  // En verimli saatleri hesapla
  List<int> calculateMostProductiveHours() {
    final hourCounts = List.filled(24, 0);
    _pomodoroHistory
      .where((r) => r.completed)  // Tamamlanan tüm pomodoro'ları say
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

  // Timer durumu kaydet
  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isRunning && _startTime != null) {
        await prefs.setInt('timeLeft', _timeLeft);
        await prefs.setString('startTime', _startTime!.toIso8601String());
        await prefs.setBool('isRunning', _isRunning);
        await prefs.setInt('initialTime', _initialTime);
        debugPrint('Timer durumu kaydedildi: timeLeft=$_timeLeft, startTime=$_startTime');
      } else {
        await _clearTimerState();
      }
    } catch (e) {
      debugPrint('Timer durumu kaydedilirken hata: $e');
    }
  }

  // Timer durumunu temizle
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('timeLeft');
      await prefs.remove('startTime');
      await prefs.remove('isRunning');
      await prefs.remove('initialTime');
      await AwesomeNotifications().cancelAll();
      
      // Son ayarlanan süreye sıfırla
      final savedDuration = prefs.getInt('timer_duration') ?? 25;
      _timeLeft = savedDuration * 60;
      _initialTime = savedDuration * 60;
      _isRunning = false;
      _startTime = null;
      
      debugPrint('Timer durumu temizlendi ve son ayarlanan süreye sıfırlandı');
    } catch (e) {
      debugPrint('Timer durumu temizlenirken hata: $e');
    }
  }

  // Timer durumunu yükle
  Future<void> loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Timer durumunu kontrol et
      final savedTimeLeft = prefs.getInt('timeLeft');
      final savedStartTimeStr = prefs.getString('startTime');
      final savedIsRunning = prefs.getBool('isRunning');
      final savedInitialTime = prefs.getInt('initialTime');

      debugPrint('Kayıtlı timer durumu: timeLeft=$savedTimeLeft, startTime=$savedStartTimeStr, isRunning=$savedIsRunning');

      // Timer'ı varsayılan değerlere sıfırla
      _timeLeft = workDuration;
      _isRunning = false;
      _startTime = null;
      _initialTime = _timeLeft;
      
      // Eğer kayıtlı durum varsa
      if (savedTimeLeft != null && savedStartTimeStr != null && 
          savedIsRunning != null && savedInitialTime != null) {
        
        final savedStartTime = DateTime.parse(savedStartTimeStr);
        final now = DateTime.now();
        final elapsedSeconds = now.difference(savedStartTime).inSeconds;
        
        // Eğer timer hala çalışıyor olmalıysa ve süre dolmamışsa
        if (savedIsRunning && elapsedSeconds < savedTimeLeft) {
          _timeLeft = savedTimeLeft - elapsedSeconds;
          _startTime = savedStartTime;
          _isRunning = true;
          _initialTime = savedInitialTime;
          
          debugPrint('Timer durumu yüklendi: timeLeft=$_timeLeft, startTime=$_startTime');
          
          // Timer'ı yeniden başlat
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
            if (_timeLeft > 0) {
              _timeLeft--;
              await _updateNotification();
              await _saveTimerState();
              notifyListeners();
            } else {
              timer.cancel();
              await _onTimerComplete();
            }
          });

          // Bildirimi güncelle
          await _updateNotification();
        } else {
          // Timer süresi dolmuş veya durdurulmuş
          debugPrint('Timer süresi dolmuş veya durdurulmuş, varsayılan değerlere sıfırlanıyor');
          await _clearTimerState();
        }
      } else {
        debugPrint('Kayıtlı timer durumu bulunamadı, varsayılan değerler kullanılıyor');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Timer durumu yüklenirken hata: $e');
      await _clearTimerState();
    }
  }

  // Uygulama başlatıldığında
  Future<void> initState() async {
    await loadTimerState();
    await initNotifications();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clearTimerState();
    AwesomeNotifications().cancelAll();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Timer tamamlanma işlemleri
  Future<void> _onTimerComplete() async {
    try {
      debugPrint('Timer tamamlandı');
      
      // Oturumu kaydet
      if (_startTime != null) {
        final session = PomodoroSession(
          startTime: _startTime!,
          endTime: DateTime.now(),
          duration: _initialTime ~/ 60,
          completed: true,
          elapsedMinutes: _initialTime ~/ 60,
        );
        
        _pomodoroHistory.insert(0, session);
        await _saveHistory();
        debugPrint('Tamamlanan oturum kaydedildi');
      }

      // Timer'ı temizle
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
      _startTime = null;

      // Tamamlanma bildirimi göster
      await _showCompletionNotification();
      debugPrint('Tamamlanma bildirimi gösterildi');

      // Titreşim
      if (await Vibration.hasVibrator() ?? false) {
        try {
          await Vibration.vibrate(duration: 1000);
          debugPrint('Titreşim çalıştırıldı');
        } catch (e) {
          debugPrint('Titreşim hatası: $e');
        }
      }

      // Ses çal
      try {
        final player = AudioPlayer();
        await player.play(AssetSource('sounds/complete.mp3'));
        debugPrint('Tamamlanma sesi çalındı');
      } catch (e) {
        debugPrint('Ses çalma hatası: $e');
      }

      // Timer'ı ayarlanan süreye sıfırla
      _timeLeft = _initialTime;
      debugPrint('Timer sıfırlandı: $_timeLeft saniye');
      
      // Timer durumunu kaydet
      await _saveTimerState();
      debugPrint('Timer durumu güncellendi');

      notifyListeners();
    } catch (e) {
      debugPrint('Timer tamamlama hatası: $e');
    }
  }

  void setShowFinished(bool value) {
    // _showFinished = value;
    notifyListeners();
  }

  // Geçmişi temizle
  void clearHistory() {
    _pomodoroHistory.clear();
    _saveHistory();
    notifyListeners();
  }

  // Tamamlanma bildirimi göster
  Future<void> _showCompletionNotification() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: 'pomodoro_complete',
          title: 'Pomodoro Tamamlandı! 🎉',
          body: 'Tebrikler! Pomodoro süreniz doldu.',
          category: NotificationCategory.Alarm,
          notificationLayout: NotificationLayout.BigText,
          fullScreenIntent: true,
          displayOnForeground: true,
          displayOnBackground: true,
          autoDismissible: true,
          showWhen: true,
          wakeUpScreen: true,
          criticalAlert: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'STOP',
            label: 'Durdur',
          ),
        ],
      );
      debugPrint('Tamamlanma bildirimi oluşturuldu');
    } catch (e) {
      debugPrint('Tamamlanma bildirimi hatası: $e');
    }
  }
}