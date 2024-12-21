import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late Timer _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    
    // Sistem UI'ı gizle
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    // Her saniye saati güncelle
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    // Normal moda dönünce sistem UI'ı geri getir
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final timeString = 
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _timeString = timeString;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: Text(
            _timeString,
            style: TextStyle(
              fontSize: isPortrait ? size.width * 0.25 : size.height * 0.6,
              fontWeight: FontWeight.w200,
              letterSpacing: 4,
              color: theme.colorScheme.onBackground.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}
