import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_providers.dart';

// Export all specific providers
export 'products_providers.dart';
export 'dashboard_providers.dart';
export 'database_providers.dart';

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
      print('🔍 Login attempt: email="$email", password="$password"');
      
      final user = await _database.usersDao.getUserByEmail(email);
      print('👤 User found: ${user != null}');
      
      if (user != null) {
        print('📧 User email: "${user.email}"');
        print('🔑 Stored password: "${user.password}"');
        print('🆔 User ID: ${user.id}');
        print('👑 User role: ${user.role}');
        print('🏢 Company ID: ${user.companyId}');
        
        final passwordMatch = user.password == password;
        print('✅ Password match: $passwordMatch');
        
        if (passwordMatch) {
          // Simple password check - in production, use proper password hashing
          state = {
            'id': user.id,
            'fullName': user.fullName,
            'email': user.email,
            'role': user.role,
            'companyId': user.companyId,
          };
          print('🎉 Login successful! User state set.');
          return true;
        } else {
          print('❌ Password mismatch!');
          print('   Expected: "$password"');
          print('   Got: "${user.password}"');
        }
      } else {
        print('❌ No user found with email: "$email"');
      }
      return false;
    } catch (e) {
      print('💥 Login error: $e');
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
