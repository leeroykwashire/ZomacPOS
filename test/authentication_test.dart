import 'package:flutter_test/flutter_test.dart';
import 'package:zomac_pos/database/app_database.dart';
import 'package:zomac_pos/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Tests', () {
    late AppDatabase database;
    late CurrentUserNotifier userNotifier;
    
    setUp(() async {
      database = AppDatabase();
      userNotifier = CurrentUserNotifier(database);
      
      // Wait for database initialization and seeding
      await database.customStatement('SELECT 1'); // Trigger database creation
      await Future.delayed(const Duration(milliseconds: 100)); // Allow seeding to complete
    });
    
    tearDown(() async {
      await database.close();
    });
    
    test('should have default admin user created', () async {
      final user = await database.usersDao.getUserByEmail('admin@pos.local');
      
      expect(user, isNotNull);
      expect(user!.email, 'admin@pos.local');
      expect(user.role, 'admin');
      expect(user.fullName, 'System Administrator');
      
      print('✅ Default admin user exists: ${user.email}');
    });
    
    test('should login with correct credentials', () async {
      final success = await userNotifier.login('admin@pos.local', 'admin123');
      
      expect(success, true);
      expect(userNotifier.isLoggedIn, true);
      expect(userNotifier.isAdmin, true);
      expect(userNotifier.userRole, 'admin');
      
      print('✅ Login successful with default admin credentials');
    });
    
    test('should fail login with incorrect credentials', () async {
      final success = await userNotifier.login('admin@pos.local', 'wrong-password');
      
      expect(success, false);
      expect(userNotifier.isLoggedIn, false);
      
      print('✅ Login correctly rejects invalid credentials');
    });
    
    test('should fail login with non-existent email', () async {
      final success = await userNotifier.login('nonexistent@example.com', 'any-password');
      
      expect(success, false);
      expect(userNotifier.isLoggedIn, false);
      
      print('✅ Login correctly rejects non-existent users');
    });
    
    test('should logout correctly', () async {
      // First login
      await userNotifier.login('admin@pos.local', 'admin123');
      expect(userNotifier.isLoggedIn, true);
      
      // Then logout
      userNotifier.logout();
      expect(userNotifier.isLoggedIn, false);
      expect(userNotifier.state, null);
      
      print('✅ Logout works correctly');
    });
    
    test('should check email existence', () async {
      final exists = await database.usersDao.emailExists('admin@pos.local');
      final notExists = await database.usersDao.emailExists('nonexistent@example.com');
      
      expect(exists, true);
      expect(notExists, false);
      
      print('✅ Email existence check works correctly');
    });
  });
}
