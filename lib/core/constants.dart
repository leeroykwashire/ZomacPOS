import 'package:flutter/material.dart';

// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Zomac POS';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'pos_app.db';
  static const int databaseVersion = 1;
  
  // Sync Settings
  static const int syncBatchSize = 50;
  static const int syncRetryDelay = 30; // seconds
  static const int maxSyncRetries = 3;
  
  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}

// User Roles
enum UserRole {
  admin('admin'),
  manager('manager'),
  cashier('cashier');
  
  const UserRole(this.value);
  final String value;
  
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.cashier,
    );
  }
}

// App Routes
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String pos = '/pos';
  static const String admin = '/admin';
  static const String products = '/products';
  static const String sales = '/sales';
  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String sync = '/sync';
}

// App Colors
class AppColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
}
