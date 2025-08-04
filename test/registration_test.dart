import 'package:flutter_test/flutter_test.dart';
import 'package:zomac_pos/database/app_database.dart';
import 'package:zomac_pos/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Registration and Session Tests', () {
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
    
    test('should register a new user successfully', () async {
      const fullName = 'John Doe';
      const email = 'john.doe@example.com';
      const password = 'password123';
      const role = 'cashier';
      
      final success = await userNotifier.register(fullName, email, password, role);
      
      expect(success, true);
      print('✅ User registration successful');
      
      // Verify user was created in database
      final user = await database.usersDao.getUserByEmail(email);
      expect(user, isNotNull);
      expect(user!.fullName, fullName);
      expect(user.email, email);
      expect(user.role, role);
      expect(user.password, password); // In production, this would be hashed
      
      print('✅ User data verified in database');
    });
    
    test('should reject duplicate email registration', () async {
      const email = 'duplicate@example.com';
      
      // First registration should succeed
      final firstSuccess = await userNotifier.register('User One', email, 'pass1', 'cashier');
      expect(firstSuccess, true);
      
      // Second registration with same email should fail
      final secondSuccess = await userNotifier.register('User Two', email, 'pass2', 'manager');
      expect(secondSuccess, false);
      
      print('✅ Duplicate email registration correctly rejected');
    });
    
    test('should allow login with registered user', () async {
      const fullName = 'Test Manager';
      const email = 'manager@test.com';
      const password = 'manager123';
      const role = 'manager';
      
      // Register user
      final registerSuccess = await userNotifier.register(fullName, email, password, role);
      expect(registerSuccess, true);
      
      // Login with registered user
      final loginSuccess = await userNotifier.login(email, password);
      expect(loginSuccess, true);
      expect(userNotifier.isLoggedIn, true);
      expect(userNotifier.userRole, role);
      expect(userNotifier.isManager, true);
      
      print('✅ Registration and login flow working correctly');
    });
    
    test('should have proper admin user seeded', () async {
      final adminExists = await database.usersDao.emailExists('admin@pos.local');
      expect(adminExists, true);
      
      final adminUser = await database.usersDao.getUserByEmail('admin@pos.local');
      expect(adminUser, isNotNull);
      expect(adminUser!.role, 'admin');
      expect(adminUser.fullName, 'System Administrator');
      
      print('✅ Admin user properly seeded');
    });
  });
}
