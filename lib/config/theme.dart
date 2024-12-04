// ignore_for_file: unused_field

import 'package:flutter/material.dart';

class AppThemes {
  // Cores do Dracula Theme
  static const Color _draculaBackground = Color(0xFF282A36);
  static const Color _draculaCurrentLine = Color(0xFF44475A);
  static const Color _draculaForeground = Color(0xFFF8F8F2);
  static const Color _draculaComment = Color(0xFF6272A4);
  static const Color _draculaCyan = Color(0xFF8BE9FD);
  static const Color _draculaGreen = Color(0xFF50FA7B);
  static const Color _draculaOrange = Color(0xFFFFB86C);
  static const Color _draculaPink = Color(0xFFFF79C6);
  static const Color _draculaPurple = Color(0xFFBD93F9);
  static const Color _draculaRed = Color(0xFFFF5555);
  static const Color _draculaYellow = Color(0xFFF1FA8C);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      color: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.bold, 
        color: Colors.black87
      ),
      bodyLarge: TextStyle(
        fontSize: 16, 
        color: Colors.black87
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.blue.shade700),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      color: Colors.grey[850],
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.bold, 
        color: Colors.white
      ),
      bodyLarge: TextStyle(
        fontSize: 16, 
        color: Colors.white70
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.blue.shade300),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  );

  // Dracula Theme
  static final ThemeData draculaTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _draculaPurple,
    scaffoldBackgroundColor: _draculaBackground,
    appBarTheme: AppBarTheme(
      color: _draculaCurrentLine,
      foregroundColor: _draculaForeground,
      elevation: 4,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.bold, 
        color: _draculaForeground
      ),
      bodyLarge: TextStyle(
        fontSize: 16, 
        color: _draculaComment
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _draculaPink,
        foregroundColor: _draculaBackground,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _draculaCyan),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _draculaCyan),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _draculaGreen, width: 2),
      ),
      labelStyle: TextStyle(color: _draculaForeground),
    ),
    cardTheme: CardTheme(
      color: _draculaCurrentLine,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _draculaPink.withOpacity(0.5);
        }
        return _draculaComment;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _draculaPink;
        }
        return _draculaForeground;
      }),
    ),
    colorScheme: ColorScheme.dark(
      primary: _draculaPurple,
      secondary: _draculaCyan,
      surface: _draculaCurrentLine,
      onPrimary: _draculaForeground,
      onSecondary: _draculaBackground,
    ),
  );

  // Método para obter o tema baseado em uma string
  static ThemeData getThemeByName(String themeName) {
    switch (themeName) {
      case 'light':
        return lightTheme;
      case 'dark':
        return darkTheme;
      case 'dracula':
        return draculaTheme;
      default:
        return lightTheme; // Tema padrão
    }
  }
}