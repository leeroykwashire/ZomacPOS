import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zomac_pos/main.dart';
import 'package:zomac_pos/services/barcode_printing_service.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('App loads and shows login screen', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Verify we're on the login screen
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Sign In'), findsOneWidget);
      
      print('✅ Login screen loads correctly');
    });
    
    testWidgets('Navigation buttons exist', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Check for sign up navigation
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      
      print('✅ Navigation elements present');
    });
    
    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Try to submit empty form
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Should still be on login screen since validation failed
      expect(find.text('Welcome Back'), findsOneWidget);
      
      print('✅ Form validation prevents empty submission');
    });
  });

  group('Barcode Integration Tests', () {
    test('Barcode service integrates with app', () {
      // Test that we can create the service without errors
      final service = BarcodePrintingService();
      expect(service, isNotNull);
      
      // Test basic barcode generation
      final barcodeData = BarcodePrintingService.generateBarcodeData(
        'TEST123',
        type: BarcodeType.code128,
      );
      expect(barcodeData, isNotNull);
      expect(barcodeData.isNotEmpty, true);
      
      print('✅ Barcode service works with app architecture');
    });
    
    test('Multiple barcode types work correctly', () {
      const testData = 'ZOMAC123456';
      
      // Test all supported types
      final formats = [
        BarcodeType.code128,
        BarcodeType.code39,
        BarcodeType.ean13,
        BarcodeType.upcA,
        BarcodeType.qrCode,
      ];
      
      for (final format in formats) {
        final data = BarcodePrintingService.generateBarcodeData(
          testData,
          type: format,
        );
        expect(data, isNotNull);
        expect(data.isNotEmpty, true);
      }
      
      print('✅ All barcode formats generate successfully');
    });
  });

  group('App Performance Tests', () {
    testWidgets('App starts within reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should start within 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      
      print('✅ App startup time: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
