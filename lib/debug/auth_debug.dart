import '../database/app_database.dart';

class AuthDebugHelper {
  static Future<void> debugAuthenticationIssue(AppDatabase database) async {
    print('🔍 Starting Authentication Debug...');
    
    try {
      // Check if users table exists and has data
      final allUsers = await database.usersDao.getAllUsers();
      print('📋 Total users in database: ${allUsers.length}');
      
      for (final user in allUsers) {
        print('👤 User: ${user.email} | Password: ${user.password} | Role: ${user.role}');
      }
      
      // Specifically check for admin user
      print('\n🔍 Looking for admin@pos.local...');
      final adminUser = await database.usersDao.getUserByEmail('admin@pos.local');
      
      if (adminUser != null) {
        print('✅ Admin user found!');
        print('   - ID: ${adminUser.id}');
        print('   - Email: ${adminUser.email}');
        print('   - Password: ${adminUser.password}');
        print('   - Full Name: ${adminUser.fullName}');
        print('   - Role: ${adminUser.role}');
        
        // Test password comparison
        const testPassword = 'admin123';
        final passwordMatch = adminUser.password == testPassword;
        print('   - Password matches "admin123": $passwordMatch');
        
        if (!passwordMatch) {
          print('   ⚠️ Expected password: $testPassword');
          print('   ⚠️ Actual password: ${adminUser.password}');
        }
      } else {
        print('❌ Admin user NOT found!');
        print('🔧 Attempting to create admin user...');
        
        // Try to create the admin user
        await database.usersDao.createUser(UsersCompanion.insert(
          fullName: 'System Administrator',
          email: 'admin@pos.local',
          password: 'admin123',
          role: 'admin',
          companyId: '1', // Assuming company ID 1 exists
        ));
        
        print('✅ Admin user created successfully!');
      }
      
    } catch (e) {
      print('❌ Error during authentication debug: $e');
    }
    
    print('🔍 Authentication Debug Complete\n');
  }
  
  static Future<void> testDirectLogin(AppDatabase database, String email, String password) async {
    print('🧪 Testing direct login for: $email');
    
    try {
      final user = await database.usersDao.getUserByEmail(email);
      
      if (user == null) {
        print('❌ User not found with email: $email');
        return;
      }
      
      print('✅ User found: ${user.email}');
      print('   - Stored password: "${user.password}"');
      print('   - Provided password: "$password"');
      print('   - Passwords match: ${user.password == password}');
      
      if (user.password == password) {
        print('✅ Login should succeed!');
      } else {
        print('❌ Login will fail - password mismatch');
        
        // Check for common issues
        if (user.password.trim() != user.password) {
          print('⚠️ Stored password has whitespace');
        }
        
        if (password.trim() != password) {
          print('⚠️ Provided password has whitespace');
        }
        
        print('   - Stored password length: ${user.password.length}');
        print('   - Provided password length: ${password.length}');
      }
      
    } catch (e) {
      print('❌ Error during direct login test: $e');
    }
  }
}
