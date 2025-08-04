import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(AppDatabase db) : super(db);

  // Get all categories
  Future<List<Category>> getAllCategories() => select(categories).get();

  // Get active categories only
  Future<List<Category>> getActiveCategories() =>
    (select(categories)..where((c) => c.isActive.equals(true))).get();

  // Get categories by company
  Future<List<Category>> getCategoriesByCompany(String companyId) =>
    (select(categories)..where((c) => c.companyId.equals(companyId))).get();

  // Get category by ID
  Future<Category?> getCategoryById(String categoryId) =>
    (select(categories)..where((c) => c.id.equals(categoryId))).getSingleOrNull();

  // Search categories by name
  Future<List<Category>> searchCategories(String query) =>
    (select(categories)..where((c) => c.name.like('%$query%'))).get();

  // Get subcategories
  Future<List<Category>> getSubcategories(String parentId) =>
    (select(categories)..where((c) => c.parentId.equals(parentId))).get();

  // Get root categories (no parent)
  Future<List<Category>> getRootCategories() =>
    (select(categories)..where((c) => c.parentId.isNull())).get();

  // Create category
  Future<String> createCategory(CategoriesCompanion category) async {
    return await into(categories).insertReturning(category).then((c) => c.id);
  }

  // Insert category (alias for createCategory)
  Future<String> insertCategory(CategoriesCompanion category) => createCategory(category);

  // Update category
  Future<void> updateCategory(String categoryId, CategoriesCompanion category) =>
    (update(categories)..where((c) => c.id.equals(categoryId)))
      .write(category.copyWith(updatedAt: Value(DateTime.now())));

  // Delete category (soft delete)
  Future<void> deleteCategory(String categoryId) =>
    (update(categories)..where((c) => c.id.equals(categoryId)))
      .write(CategoriesCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

  // Get total categories count
  Future<int> getTotalCategoriesCount() async {
    final result = await (selectOnly(categories)
      ..addColumns([categories.id.count()])).getSingleOrNull();
    return result?.read(categories.id.count()) ?? 0;
  }

  // Get active categories count
  Future<int> getActiveCategoriesCount() async {
    final result = await (selectOnly(categories)
      ..addColumns([categories.id.count()])
      ..where(categories.isActive.equals(true))).getSingleOrNull();
    return result?.read(categories.id.count()) ?? 0;
  }

  // Check if category has products
  Future<bool> categoryHasProducts(String categoryId) async {
    final productsDao = attachedDatabase.productsDao;
    final products = await productsDao.getProductsByCategory(categoryId);
    return products.isNotEmpty;
  }

  // Get categories with product counts
  Future<List<CategoryWithProductCount>> getCategoriesWithProductCounts() async {
    final allCategories = await getAllCategories();
    final result = <CategoryWithProductCount>[];
    
    for (final category in allCategories) {
      final products = await attachedDatabase.productsDao.getProductsByCategory(category.id);
      result.add(CategoryWithProductCount(
        category: category,
        productCount: products.length,
      ));
    }
    
    return result;
  }
}

// Helper class for categories with product counts
class CategoryWithProductCount {
  final Category category;
  final int productCount;

  CategoryWithProductCount({
    required this.category,
    required this.productCount,
  });
}
