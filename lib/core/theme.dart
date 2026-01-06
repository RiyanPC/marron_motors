import 'package:flutter/material.dart';

class AppTheme {
  // Temas Predefinidos
  static const Map<String, Map<String, Color>> predefinedThemes = {
    'Azul Clásico': {'primary': Color(0xFF0D47A1), 'accent': Color(0xFFD4AF37)},
    'Verde Esmeralda': {
      'primary': Color(0xFF2E7D32),
      'accent': Color(0xFF81C784),
    },
    'Morado Profesional': {
      'primary': Color(0xFF6A1B9A),
      'accent': Color(0xFFBA68C8),
    },
    'Naranja Vibrante': {
      'primary': Color(0xFFE65100),
      'accent': Color(0xFFFFB74D),
    },
    'Rojo Elegante': {
      'primary': Color(0xFFC62828),
      'accent': Color(0xFFEF5350),
    },
  };

  // Obtener tema por nombre
  static ThemeData getTheme(
    String themeName, {
    Color? customPrimary,
    Color? customAccent,
  }) {
    Color primaryColor;
    Color accentColor;

    if (themeName == 'Personalizado') {
      primaryColor = customPrimary ?? const Color(0xFF0D47A1);
      accentColor = customAccent ?? const Color(0xFFD4AF37);
    } else {
      final theme =
          predefinedThemes[themeName] ?? predefinedThemes['Azul Clásico']!;
      primaryColor = theme['primary']!;
      accentColor = theme['accent']!;
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[50], // Background remains neutral
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: TextStyle(
          color: primaryColor,
        ), // Label remains primary or neutral
        floatingLabelStyle: TextStyle(
          color: accentColor,
        ), // Floating label highlights with accent
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withOpacity(0.4),
        selectionHandleColor: accentColor,
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        selectedColor: Colors.white,
        fillColor: accentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor;
          }
          return Colors.grey.shade600;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor;
          }
          return Colors.grey.shade600;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return accentColor.withOpacity(0.5);
          }
          return Colors.grey.shade200;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: accentColor.withOpacity(0.3),
        thumbColor: accentColor,
        overlayColor: accentColor.withOpacity(0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accentColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // Mantener compatibilidad con código existente
  static ThemeData get lightTheme => getTheme('Azul Clásico');
}
