import 'dart:math';

class IdGenerator {
  static final Random _random = Random();
  
  // Generate a UUID-like string for local IDs
  static String generateLocalId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final buffer = StringBuffer();
    
    // Generate a 36-character ID in UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    for (int i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) {
        buffer.write('-');
      } else {
        buffer.write(chars[_random.nextInt(chars.length)]);
      }
    }
    
    return buffer.toString();
  }
  
  // Generate a receipt number
  static String generateReceiptNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7); // Last 6 digits
    final random = _random.nextInt(999).toString().padLeft(3, '0');
    return 'R$timestamp$random';
  }
  
  // Generate a session ID for cart management
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999);
    return 'session_${timestamp}_$random';
  }
}
