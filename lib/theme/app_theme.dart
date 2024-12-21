import 'package:flutter/material.dart';

class AppTheme {
  static final TextStyle menuButtonStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w300,
  );

  static final TextStyle timerTextStyle = TextStyle(
    fontSize: 161,
    fontWeight: FontWeight.w200,
  );

  static final TextStyle startButtonStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle clockTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w300,
  );

  static final TextStyle finishedTextStyle = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.w200,
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      background: Colors.white,
      primary: Colors.black,
      secondary: Colors.grey[700]!,
      surface: Colors.grey[100]!,
      error: Colors.red[400]!,
    ),
    dividerColor: Colors.grey[300],
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      background: Colors.black,
      primary: Colors.white,
      secondary: Colors.grey[400]!,
      surface: Colors.grey[900]!,
      error: Colors.red[400]!,
    ),
    dividerColor: Colors.grey[800],
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
    ),
  );
} 