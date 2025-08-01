import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/tables/all_tables.dart';
import '../providers/database_providers.dart';

// Current user provider - will be properly typed after code generation
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, Map<String, dynamic>?>((ref) {
  final database = ref.read(databaseProvider);
  return CurrentUserNotifier(database);
});

class CurrentUserNotifier extends StateNotifier<Map<String, dynamic>?> {
  final AppDatabase _database;
  
  CurrentUserNotifier(this._database) : super(null);
  
  Future<bool> login(String email, String password) async {
    try {
      final user = await _database.getUserByEmail(email);
      if (user != null) {
        // In a real app, you'd verify the password hash here
        state = user.toJson();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  void logout() {
    state = null;
  }
  
  bool get isLoggedIn => state != null;
  bool get isAdmin => state?['role'] == 'admin';
  bool get isManager => state?['role'] == 'manager' || isAdmin;
  String? get userId => state?['id'];
  String? get userRole => state?['role'];
}

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);
  
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
  
  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

// Navigation provider for current screen
final currentScreenProvider = StateNotifierProvider<CurrentScreenNotifier, String>((ref) {
  return CurrentScreenNotifier();
});

class CurrentScreenNotifier extends StateNotifier<String> {
  CurrentScreenNotifier() : super('/home');
  
  void setScreen(String screen) {
    state = screen;
  }
}

// Loading state provider for global loading indicators
final loadingProvider = StateNotifierProvider<LoadingNotifier, bool>((ref) {
  return LoadingNotifier();
});

class LoadingNotifier extends StateNotifier<bool> {
  LoadingNotifier() : super(false);
  
  void setLoading(bool loading) {
    state = loading;
  }
}
