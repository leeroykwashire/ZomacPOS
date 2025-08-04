import 'package:flutter_test/flutter_test.dart';
import 'package:zomac_pos/services/barcode_printing_service.dart';

void main() {
  group('Barcode Printing Tests', () {
    test('should generate barcode data', () {
      // Test basic barcode generation
      final barcodeData = BarcodePrintingService.generateBarcodeData(
        '1234567890123',
        type: BarcodeType.code128,
      );
      
      expect(barcodeData, isNotNull);
      expect(barcodeData.isNotEmpty, true);
      print('✅ Code128 barcode data generated successfully');
    });
    
    test('should validate barcode types', () {
      // Test different barcode types
      final code128 = BarcodeType.code128.toBarcode();
      final code39 = BarcodeType.code39.toBarcode();
      final ean13 = BarcodeType.ean13.toBarcode();
      final upcA = BarcodeType.upcA.toBarcode();
      final qrCode = BarcodeType.qrCode.toBarcode();
      
      expect(code128, isNotNull);
      expect(code39, isNotNull);
      expect(ean13, isNotNull);
      expect(upcA, isNotNull);
      expect(qrCode, isNotNull);
      
      print('✅ All barcode types validated successfully');
    });
    
    test('should generate different barcode formats', () {
      const testData = '1234567890123';
      
      // Test Code128
      final code128Data = BarcodePrintingService.generateBarcodeData(
        testData,
        type: BarcodeType.code128,
      );
      expect(code128Data, isNotNull);
      
      // Test Code39
      final code39Data = BarcodePrintingService.generateBarcodeData(
        testData,
        type: BarcodeType.code39,
      );
      expect(code39Data, isNotNull);
      
      // Test QR Code
      final qrData = BarcodePrintingService.generateBarcodeData(
        testData,
        type: BarcodeType.qrCode,
      );
      expect(qrData, isNotNull);
      
      print('✅ Multiple barcode formats generated successfully');
    });
    
    test('should handle barcode generation edge cases', () {
      // Test edge cases that should still work
      
      // Very short data (QR codes can handle this)
      final shortData = BarcodePrintingService.generateBarcodeData(
        'A', 
        type: BarcodeType.qrCode,
      );
      expect(shortData, isNotNull);
      expect(shortData.isNotEmpty, true);
      
      // Numeric only data (good for barcodes)
      final numericData = BarcodePrintingService.generateBarcodeData(
        '123456789', 
        type: BarcodeType.code128,
      );
      expect(numericData, isNotNull);
      expect(numericData.isNotEmpty, true);
      
      print('✅ Edge cases handled correctly');
    });
  });
  
  group('Barcode Service Integration Tests', () {
    test('should validate service initialization', () {
      // Test that service can be instantiated
      expect(() => BarcodePrintingService(), returnsNormally);
      print('✅ BarcodePrintingService initializes correctly');
    });
    
    test('should handle large data volumes', () {
      // Test with larger data sets
      final longData = 'A' * 100; // 100 character string
      final barcodeData = BarcodePrintingService.generateBarcodeData(
        longData,
        type: BarcodeType.qrCode, // QR codes can handle more data
      );
      
      expect(barcodeData, isNotNull);
      expect(barcodeData.isNotEmpty, true);
      print('✅ Large data volume handled successfully');
    });
  });
}
