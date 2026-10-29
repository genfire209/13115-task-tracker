import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/user.dart';

/// Centralized dark theme + the color helpers used across every screen so
/// task status / category / subteam colors stay consistent app-wide.
class AppTheme {
  AppTheme._();

  static const background = Color(0xFF0E0E12);
  static const surface = Color(0xFF1A1A20);
  static const surfaceVariant = Color(0xFF242430);
  // Team red, two strengths. [primary] is for red text, icons and
  // indicators on the dark surfaces (4.96:1 on [surface]); [primaryFill] is
  // the deeper red behind white button labels (5.10:1 — white on [primary]
  // is only 3.49:1, below the 4.5:1 minimum for button text).
  static const primary = Color(0xFFFF3B57);
  static const primaryFill = Color(0xFFD61F3A);
  static const primaryDeep = Color(0xFF8B1029); // end of the red gradients
  static const onSurface = Color(0xFFF5F5F7);
  static const onSurfaceMuted = Color(0xFF9A9AA5);
  static const outline = Color(0xFF32323C);

  static const statusOpen = Color(0xFF9CA3AF); // 4.97:1 on its own chip tint
  static const statusPending = Color(0xFFFBBF24);
  static const statusActive = Color(0xFF60A5FA);
  static const statusDeclined = Color(0xFFF87171);
  static const statusCompleted = Color(0xFF34D399);

  static const categoryMechanical = Color(0xFF60A5FA);
  static const categoryOutreach = Color(0xFF34D399);
  static const categoryProgramming = Color(0xFFA78BFA);
  static const categoryStrategy = Color(0xFFFBBF24);

  // Shared rounded style for `DropdownMenu` (used for member pickers), since
  // it doesn't automatically pick up the ambient `inputDecorationTheme` the
  // way `TextField`/`DropdownButtonFormField` do.
  static final dropdownInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: onSurfaceMuted),
    hintStyle: const TextStyle(color: onSurfaceMuted),
  );

  static final dropdownMenuStyle = MenuStyle(
    backgroundColor: const WidgetStatePropertyAll(surface),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: outline),
      ),
    ),
  );

  static ThemeData get dark {
    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      // Selected chips and other "container" fills carry white text, so they
      // use the deeper red (5.10:1), not [primary] (3.49:1).
      secondaryContainer: primaryFill,
      onSecondaryContainer: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: statusDeclined,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: onSurfaceMuted),
        titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      ).apply(bodyColor: onSurface, displayColor: onSurface),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryFill,
        checkmarkColor: Colors.white,
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        labelStyle: const TextStyle(
          color: onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: onSurfaceMuted),
        hintStyle: const TextStyle(color: onSurfaceMuted),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: dropdownInputDecorationTheme,
        menuStyle: dropdownMenuStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryFill,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryFill,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceMuted,
        indicatorColor: primary,
      ),
      // Bottom tab bar: white icon on a red-tinted pill when selected
      // (12.35:1), red label (4.96:1), muted otherwise (6.22:1).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.22),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? onSurface : onSurfaceMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? primary : onSurfaceMuted,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: outline, space: 32),
      listTileTheme: const ListTileThemeData(iconColor: onSurfaceMuted),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    );
  }

  static Color statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return statusOpen;
      case TaskStatus.pendingAcceptance:
        return statusPending;
      case TaskStatus.accepted:
      case TaskStatus.inProgress:
        return statusActive;
      case TaskStatus.declined:
        return statusDeclined;
      case TaskStatus.completed:
        return statusCompleted;
    }
  }

  static Color categoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.mechanical:
        return categoryMechanical;
      case TaskCategory.outreach:
        return categoryOutreach;
      case TaskCategory.programming:
        return categoryProgramming;
    }
  }

  static Color subteamColor(Subteam subteam) {
    switch (subteam) {
      case Subteam.mechanical:
        return categoryMechanical;
      case Subteam.outreach:
        return categoryOutreach;
      case Subteam.programming:
        return categoryProgramming;
      case Subteam.strategy:
        return categoryStrategy;
    }
  }
}
