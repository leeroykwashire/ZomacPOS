# POS System Database

A comprehensive Flutter-based Point of Sale system with offline-first capabilities and robust synchronization features.

## Features

- **Offline-First Architecture**: Works completely offline with automatic sync when connection is available
- **Comprehensive Database Schema**: Matches your Laravel backend exactly
- **Advanced Sync Management**: Conflict resolution, retry logic, and error handling
- **Audit Trail**: Complete change tracking for debugging and compliance
- **Performance Optimized**: Proper indexing and query optimization

## Database Tables

### Core Business Tables
- **Users**: Staff management with roles (admin, cashier, superuser)
- **Companies**: Multi-company support
- **Products**: Inventory management with categories and pricing
- **Categories**: Hierarchical product categorization
- **Sales & Sales Items**: Complete transaction tracking
- **Carts**: Shopping cart management
- **Currencies**: Multi-currency support
- **Cash Customers**: Customer management
- **Cash Drawers**: Cash management and reconciliation
- **Expenses**: Expense  tracking
- **Stock Takes & Stock Take Lines**: Inventory auditing
- **Stock Movements**: Inventory movement tracking

### Sync Management Tables
- **Sync Metadata**: Advanced conflict resolution and version control
- **Sync Queue**: Robust operation queuing with dependencies
- **Sync Sessions**: Detailed sync progress tracking
- **Change Log**: Complete audit trail
- **App Settings**: Configuration management

## Getting Started

### Prerequisites
- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher
- Android Studio or VS Code with Flutter extensions
- Git for version control

### For New Developers Taking Over This Project

#### 1. Environment Setup
```bash
# Verify Flutter installation
flutter doctor

# If Flutter is not installed, follow: https://docs.flutter.dev/get-started/install

# Clone the repository
git clone <repository-url>
cd pos_system

# Check Flutter version compatibility
flutter --version
# Should be 3.10.0 or higher