import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentThemeName = 'Azul Clásico';
  Color? _customPrimaryColor;
  Color? _customAccentColor;
  ThemeData _themeData = AppTheme.lightTheme;

  ThemeProvider() {
    _loadTheme();
  }

  // Getters
  String get currentThemeName => _currentThemeName;
  ThemeData get themeData => _themeData;
  Color? get customPrimaryColor => _customPrimaryColor;
  Color? get customAccentColor => _customAccentColor;

  bool get isCustomTheme => _currentThemeName == 'Personalizado';

  // Cargar tema guardado
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeName = prefs.getString('theme_name') ?? 'Azul Clásico';

    if (_currentThemeName == 'Personalizado') {
      final primaryValue = prefs.getInt('custom_primary_color');
      final accentValue = prefs.getInt('custom_accent_color');

      if (primaryValue != null) {
        _customPrimaryColor = Color(primaryValue);
      }
      if (accentValue != null) {
        _customAccentColor = Color(accentValue);
      }
    }

    _updateTheme();
  }

  // Cambiar tema
  Future<void> setTheme(
    String themeName, {
    Color? customPrimary,
    Color? customAccent,
  }) async {
    print('DEBUG: setTheme called with $themeName');
    _currentThemeName = themeName;

    if (themeName == 'Personalizado') {
      _customPrimaryColor = customPrimary ?? _customPrimaryColor;
      _customAccentColor = customAccent ?? _customAccentColor;
    } else {
      _customPrimaryColor = null;
      _customAccentColor = null;
    }

    _updateTheme();
    await _saveTheme();
  }

  // Actualizar solo los colores personalizados (sin cambiar el tema)
  Future<void> updateCustomColors({Color? primary, Color? accent}) async {
    if (_currentThemeName == 'Personalizado') {
      if (primary != null) _customPrimaryColor = primary;
      if (accent != null) _customAccentColor = accent;

      _updateTheme();
      await _saveTheme();
    }
  }

  // Actualizar el ThemeData actual
  void _updateTheme() {
    _themeData = AppTheme.getTheme(
      _currentThemeName,
      customPrimary: _customPrimaryColor,
      customAccent: _customAccentColor,
    );
    notifyListeners();
  }

  // Guardar tema en SharedPreferences
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_name', _currentThemeName);

    if (_currentThemeName == 'Personalizado') {
      if (_customPrimaryColor != null) {
        await prefs.setInt('custom_primary_color', _customPrimaryColor!.value);
      }
      if (_customAccentColor != null) {
        await prefs.setInt('custom_accent_color', _customAccentColor!.value);
      }
    } else {
      await prefs.remove('custom_primary_color');
      await prefs.remove('custom_accent_color');
    }
  }
}
