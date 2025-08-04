import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
          final userData = {
            'id': user.id,
            'fullName': user.fullName,
            'email': user.email,
            'role': user.role,
            'companyId': user.companyId,
          };
          state = userData;
          print('🎉 Login successful! User state set.');
          
          // Save session for persistence
          await _saveUserSession(userData);
          
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
  
  Future<bool> register(String fullName, String email, String password, String role) async {
    try {
      print('🔍 Registration attempt: email="$email", fullName="$fullName", role="$role"');
      
      // Check if email already exists
      final existingUser = await _database.usersDao.getUserByEmail(email);
      if (existingUser != null) {
        print('❌ User already exists with email: "$email"');
        return false;
      }
      
      // Get default company using helper method
      final defaultCompanyId = await _database.getDefaultCompanyId();
      if (defaultCompanyId == null) {
        print('❌ No default company found for registration');
        return false;
      }
      
      print('🏢 Using company ID: $defaultCompanyId');
      
      // Create new user
      const uuid = Uuid();
      final userCompanion = UsersCompanion.insert(
        id: uuid.v4(),
        fullName: fullName,
        email: email,
        password: password, // In production, hash this password
        role: Value(role),
        companyId: defaultCompanyId,
      );
      
      final userId = await _database.usersDao.createUser(userCompanion);
      print('✅ User created successfully with ID: $userId');
      
      return true;
    } catch (e) {
      print('💥 Registration error: $e');
      return false;
    }
  }
  
  void logout() {
    state = null;
    // Clear from persistent storage
    _clearUserSession();
  }
  
  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
      print('🗑️ User session cleared from persistent storage');
    } catch (e) {
      print('❌ Error clearing user session: $e');
    }
  }
  
  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(userData);
      await prefs.setString('user_session', userJson);
      print('💾 User session saved: ${userData['email']}');
    } catch (e) {
      print('❌ Error saving user session: $e');
    }
  }
  
  Future<void> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session');
      
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        
        // Verify the user still exists in the database
        final user = await _database.usersDao.getUserById(userData['id']);
        if (user != null) {
          state = userData;
          print('🔄 User session restored: ${userData['email']}');
        } else {
          // User no longer exists, clear the session
          await _clearUserSession();
          print('🚫 Stored user no longer exists, session cleared');
        }
      } else {
        print('📱 No saved session found');
      }
    } catch (e) {
      print('❌ Error loading saved session: $e');
    }
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
