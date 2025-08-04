import 'dart:io';

Future<void> main() async {
  print('🗑️  Clearing database cache...');
  
  try {
    // Common database locations on Windows
    final locations = [
      'C:\\Users\\${Platform.environment['USERNAME']}\\Documents\\zomac_pos.db',
      'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Local\\zomac_pos\\zomac_pos.db',
      'C:\\Users\\${Platform.environment['USERNAME']}\\AppData\\Roaming\\zomac_pos\\zomac_pos.db',
    ];
    
    bool found = false;
    
    for (final location in locations) {
      final file = File(location);
      if (await file.exists()) {
        print('✅ Found database at: $location');
        await file.delete();
        print('🗑️  Deleted database file');
        found = true;
      }
    }
    
    if (!found) {
      print('ℹ️  No database file found in common locations');
      print('   This will force the app to create a fresh database on next run');
    }
    
    print('✅ Database reset complete!');
    print('📱 Next app launch will create a fresh database with admin@pos.local/admin123');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
