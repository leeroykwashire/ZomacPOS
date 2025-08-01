import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';
import '../tables/companies_table.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users, Companies])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(AppDatabase db) : super(db);

  // Get all users
  Future<List<User>> getAllUsers() => select(users).get();

  // Get user by ID
  Future<User?> getUserById(String userId) =>
    (select(users)..where((u) => u.id.equals(userId))).getSingleOrNull();

  // Get user by email
  Future<User?> getUserByEmail(String email) =>
    (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();

  // Get users by role
  Future<List<User>> getUsersByRole(String role) =>
    (select(users)..where((u) => u.role.equals(role))).get();

  // Get users by company
  Future<List<User>> getUsersByCompany(String companyId) =>
    (select(users)..where((u) => u.companyId.equals(companyId))).get();

  // Create user
  Future<String> createUser(UsersCompanion user) async {
    return await into(users).insertReturning(user).then((u) => u.id);
  }

  // Update user
  Future<void> updateUser(String userId, UsersCompanion user) =>
    (update(users)..where((u) => u.id.equals(userId)))
      .write(user.copyWith(updatedAt: Value(DateTime.now())));

  // Delete user (soft delete)
  Future<void> deleteUser(String userId) =>
    (update(users)..where((u) => u.id.equals(userId)))
      .write(UsersCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

  // Check if email exists
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  // Get active users only
  Future<List<User>> getActiveUsers() =>
    (select(users)..where((u) => u.isDeleted.equals(false))).get();

  // Get users with company info
  Future<List<UserWithCompany>> getUsersWithCompany() {
    final query = select(users).join([
      leftOuterJoin(companies, companies.id.equalsExp(users.companyId))
    ]);
    
    return query.map((row) {
      final user = row.readTable(users);
      final company = row.readTableOrNull(companies);
      return UserWithCompany(user: user, company: company);
    }).get();
  }

  // Update user password
  Future<void> updatePassword(String userId, String hashedPassword) =>
    (update(users)..where((u) => u.id.equals(userId)))
      .write(UsersCompanion(
        password: Value(hashedPassword),
        updatedAt: Value(DateTime.now()),
      ));

  // Update last login
  Future<void> updateLastLogin(String userId) =>
    (update(users)..where((u) => u.id.equals(userId)))
      .write(UsersCompanion(
        updatedAt: Value(DateTime.now()),
      ));

  // Search users
  Future<List<User>> searchUsers(String query) =>
    (select(users)..where((u) => 
      u.fullName.like('%$query%') | u.email.like('%$query%')))
    .get();

  // Get admins
  Future<List<User>> getAdmins() => getUsersByRole('admin');

  // Get managers
  Future<List<User>> getManagers() => getUsersByRole('manager');

  // Get cashiers
  Future<List<User>> getCashiers() => getUsersByRole('cashier');

  // Check if user is admin
  Future<bool> isAdmin(String userId) async {
    final user = await getUserById(userId);
    return user?.role == 'admin';
  }

  // Check if user can perform admin actions
  Future<bool> canPerformAdminActions(String userId) async {
    final user = await getUserById(userId);
    return user?.role == 'admin' || user?.role == 'manager';
  }
}

// Helper class
class UserWithCompany {
  final User user;
  final Company? company;

  UserWithCompany({required this.user, this.company});
}
