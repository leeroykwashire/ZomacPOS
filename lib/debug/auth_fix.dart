import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:zomac_pos/database/app_database.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 Debugging Authentication Issue...\n');
  
  final database = AppDatabase();
  
  try {
    // Check for admin user
    print('📋 Checking for admin user...');
    final adminUser = await database.usersDao.getUserByEmail('admin@pos.local');
    
    if (adminUser != null) {
      print('✅ Admin user found:');
      print('   - ID: ${adminUser.id}');
      print('   - Email: ${adminUser.email}');
      print('   - Password: "${adminUser.password}"');
      print('   - Role: ${adminUser.role}');
      print('   - Password matches "admin123": ${adminUser.password == "admin123"}');
      
      if (adminUser.password != 'admin123') {
        print('\n🔧 Password mismatch detected! Fixing...');
        await database.usersDao.updateUser(
          adminUser.id,
          UsersCompanion(
            password: const Value('admin123'),
          ),
        );
        print('✅ Password updated to "admin123"');
      }
    } else {
      print('❌ Admin user not found! Creating...');
      
      // Check if there's a default company
      final companies = await database.companiesDao.getAllCompanies();
      String companyId;
      
      if (companies.isNotEmpty) {
        companyId = companies.first.id;
        print('✅ Using existing company: ${companies.first.name}');
      } else {
        print('🏢 Creating default company...');
        companyId = await database.companiesDao.createCompany(
          CompaniesCompanion.insert(
            name: 'Default Company',
            address: const Value('123 Main St'),
            phone: const Value('+1234567890'),
            email: const Value('info@company.com'),
          ),
        );
        print('✅ Default company created');
      }
      
      // Create admin user
      await database.usersDao.createUser(
        UsersCompanion.insert(
          fullName: 'System Administrator',
          email: 'admin@pos.local',
          password: 'admin123',
          role: const Value('admin'),
          companyId: companyId,
        ),
      );
      print('✅ Admin user created successfully!');
    }
    
    // List all users for verification
    print('\n👥 All users in database:');
    final allUsers = await database.usersDao.getAllUsers();
    for (final user in allUsers) {
      print('   - ${user.email} | "${user.password}" | ${user.role}');
    }
    
    // Test login logic
    print('\n🧪 Testing login logic...');
    final testUser = await database.usersDao.getUserByEmail('admin@pos.local');
    if (testUser != null) {
      final loginSuccess = testUser.password == 'admin123';
      print('   - Email found: ✅');
      print('   - Password check: ${loginSuccess ? '✅' : '❌'}');
      if (!loginSuccess) {
        print('     Expected: "admin123"');
        print('     Got: "${testUser.password}"');
      }
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await database.close();
    print('\n🏁 Database check complete!');
    exit(0);
  }
}
