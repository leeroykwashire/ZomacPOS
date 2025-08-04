import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../providers/database_providers.dart';

class AuthDebugScreen extends ConsumerStatefulWidget {
  const AuthDebugScreen({super.key});

  @override
  ConsumerState<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends ConsumerState<AuthDebugScreen> {
  final List<String> _logs = [];
  bool _isChecking = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)} $message');
    });
  }

  Future<void> _checkDatabase() async {
    setState(() {
      _isChecking = true;
      _logs.clear();
    });

    try {
      final database = ref.read(databaseProvider);
      
      _addLog('🔍 Starting database check...');
      
      // Check all users
      final allUsers = await database.usersDao.getAllUsers();
      _addLog('👥 Total users in database: ${allUsers.length}');
      
      for (final user in allUsers) {
        _addLog('👤 User: ${user.email} | Password: "${user.password}" | Role: ${user.role}');
      }
      
      // Check specifically for admin user
      _addLog('🔍 Looking for admin@pos.local...');
      final adminUser = await database.usersDao.getUserByEmail('admin@pos.local');
      
      if (adminUser != null) {
        _addLog('✅ Admin user found!');
        _addLog('   - Email: ${adminUser.email}');
        _addLog('   - Password: "${adminUser.password}"');
        _addLog('   - ID: ${adminUser.id}');
        _addLog('   - Role: ${adminUser.role}');
        
        // Test password comparison
        const testPassword = 'admin123';
        final passwordMatch = adminUser.password == testPassword;
        _addLog('   - Password matches "admin123": $passwordMatch');
        
        if (!passwordMatch) {
          _addLog('   ⚠️ Expected: "$testPassword"');
          _addLog('   ⚠️ Actual: "${adminUser.password}"');
          _addLog('   ⚠️ Length expected: ${testPassword.length}');
          _addLog('   ⚠️ Length actual: ${adminUser.password.length}');
        }
      } else {
        _addLog('❌ Admin user NOT found!');
        _addLog('🔧 Attempting to create admin user...');
        
        // Try to get or create a company first
        final companies = await database.select(database.companies).get();
        String companyId;
        
        if (companies.isNotEmpty) {
          companyId = companies.first.id;
          _addLog('✅ Using existing company: ${companies.first.name}');
        } else {
          _addLog('🏢 Creating default company...');
          const uuid = Uuid();
          final companyCompanion = CompaniesCompanion.insert(
            id: uuid.v4(),
            name: 'Default Company',
            email: 'info@company.com',
            address: const Value('123 Main St'),
            phone: const Value('+1234567890'),
          );
          final company = await database.into(database.companies).insertReturning(companyCompanion);
          companyId = company.id;
          _addLog('✅ Default company created with ID: $companyId');
        }
        
        // Create admin user
        const uuid = Uuid();
        final userCompanion = UsersCompanion.insert(
          id: uuid.v4(),
          fullName: 'System Administrator',
          email: 'admin@pos.local',
          password: 'admin123',
          role: const Value('admin'),
          companyId: companyId,
        );
        final user = await database.into(database.users).insertReturning(userCompanion);
        _addLog('✅ Admin user created with ID: ${user.id}');
      }
      
      _addLog('🎯 Test complete!');
      
    } catch (e) {
      _addLog('❌ Error: $e');
    }
    
    setState(() {
      _isChecking = false;
    });
  }

  Future<void> _testLogin() async {
    _addLog('🧪 Testing login with admin@pos.local / admin123...');
    
    try {
      final database = ref.read(databaseProvider);
      final user = await database.usersDao.getUserByEmail('admin@pos.local');
      
      if (user == null) {
        _addLog('❌ User not found');
        return;
      }
      
      _addLog('✅ User found: ${user.email}');
      _addLog('🔑 Stored password: "${user.password}"');
      _addLog('🔑 Test password: "admin123"');
      
      final match = user.password == 'admin123';
      _addLog('✅ Password match: $match');
      
      if (match) {
        _addLog('🎉 Login should work!');
      } else {
        _addLog('❌ Login will fail due to password mismatch');
      }
      
    } catch (e) {
      _addLog('❌ Login test error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkDatabase,
                    child: _isChecking 
                      ? const CircularProgressIndicator()
                      : const Text('Check Database'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _testLogin,
                    child: const Text('Test Login'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _logs.clear();
                      });
                    },
                    child: const Text('Clear Logs'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Tap "Check Database" to start.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
