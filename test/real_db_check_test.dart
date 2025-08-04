import 'package:flutter_test/flutter_test.dart';
import 'package:zomac_pos/database/app_database.dart';

void main() {
  group('Authentication Real Database Tests', () {
    test('should check admin user in real database', () async {
      print('\n🔍 Checking real database for admin user...\n');
      
      final database = AppDatabase();
      
      try {
        // Check if admin user exists
        final adminUser = await database.usersDao.getUserByEmail('admin@pos.local');
        
        if (adminUser != null) {
          print('✅ Admin user found!');
          print('   - ID: ${adminUser.id}');
          print('   - Email: ${adminUser.email}');
          print('   - Password: "${adminUser.password}"');
          print('   - Full Name: ${adminUser.fullName}');
          print('   - Role: ${adminUser.role}');
          
          // Test password comparison
          const testPassword = 'admin123';
          final passwordMatch = adminUser.password == testPassword;
          print('   - Password matches "admin123": $passwordMatch');
          
          if (!passwordMatch) {
            print('   ⚠️ Expected password: "$testPassword"');
            print('   ⚠️ Actual password: "${adminUser.password}"');
            print('   ⚠️ Password length: ${adminUser.password.length}');
            print('   ⚠️ Expected length: ${testPassword.length}');
            
            // Check for invisible characters
            for (int i = 0; i < adminUser.password.length; i++) {
              print('   - Char $i: "${adminUser.password[i]}" (${adminUser.password.codeUnitAt(i)})');
            }
          }
        } else {
          print('❌ Admin user NOT found in database!');
          
          // List all users
          final allUsers = await database.usersDao.getAllUsers();
          print('📋 Total users in database: ${allUsers.length}');
          
          for (final user in allUsers) {
            print('👤 User: ${user.email} | Password: "${user.password}" | Role: ${user.role}');
          }
        }
        
      } catch (e) {
        print('❌ Error checking database: $e');
      } finally {
        await database.close();
      }
    });
  });
}
