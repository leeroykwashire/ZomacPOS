import 'package:flutter_test/flutter_test.dart';
import 'package:zomac_pos/database/app_database.dart';
import 'package:zomac_pos/debug/auth_debug.dart';

void main() {
  group('Authentication Debug Tests', () {
    late AppDatabase database;
    
    setUp(() async {
      // Create database for testing
      database = AppDatabase();
    });
    
    tearDown(() async {
      await database.close();
    });
    
    test('should debug authentication issue', () async {
      print('\n🚀 Starting Authentication Debug Session...\n');
      
      // Run the debug helper
      await AuthDebugHelper.debugAuthenticationIssue(database);
      
      // Test specific login
      await AuthDebugHelper.testDirectLogin(database, 'admin@pos.local', 'admin123');
      
      print('\n🏁 Debug Session Complete\n');
    });
    
    test('should verify user creation and login flow', () async {
      print('\n🔧 Testing User Creation and Login Flow...\n');
      
      // First, verify no users exist
      final initialUsers = await database.usersDao.getAllUsers();
      print('Initial user count: ${initialUsers.length}');
      
      // Create a test user
      await database.usersDao.createUser(UsersCompanion.insert(
        fullName: 'Test User',
        email: 'test@example.com',
        password: 'testpass123',
        role: 'user',
        companyId: '1',
      ));
      
      // Verify user was created
      final afterUsers = await database.usersDao.getAllUsers();
      print('Users after creation: ${afterUsers.length}');
      
      // Test login
      final testUser = await database.usersDao.getUserByEmail('test@example.com');
      expect(testUser, isNotNull);
      expect(testUser!.password, equals('testpass123'));
      
      print('✅ User creation and retrieval working correctly');
      
      // Test authentication logic
      if (testUser.password == 'testpass123') {
        print('✅ Password comparison working correctly');
      } else {
        print('❌ Password comparison failed');
        print('Expected: testpass123');
        print('Actual: ${testUser.password}');
      }
    });
  });
}
