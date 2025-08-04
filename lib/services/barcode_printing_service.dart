import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/app_database.dart';

class BarcodePrintingService {
  /// Preview barcode labels without printing
  static Future<void> previewBarcodeLabels(
    List<Product> products, {
    bool includeProductInfo = true,
    String? jobName,
  }) async {
    if (products.isEmpty) {
      throw Exception('No products provided for barcode generation');
    }

    try {
      final pdf = await generateMultipleProductBarcodePdf(
        products,
        includeProductInfo: includeProductInfo,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf,
        name: jobName ?? 'Barcode Labels Preview',
      );
    } catch (e) {
      throw Exception('Failed to preview barcode labels: $e');
    }
  }

  /// Generate barcode data as image bytes
  static Uint8List generateBarcodeData(String code, {
    BarcodeType type = BarcodeType.code128,
    int width = 200,
    int height = 80,
  }) {
    final barcode = Barcode.code128();
    final svg = barcode.toSvg(code, width: width.toDouble(), height: height.toDouble());
    // Convert SVG to bytes - this is a simplified approach
    return Uint8List.fromList(svg.codeUnits);
  }

  /// Generate PDF for a single product barcode
  static Future<Uint8List> generateProductBarcodePdf(
    Product product, {
    bool includeProductInfo = true,
    int quantity = 1,
  }) async {
    final pdf = pw.Document();
    
    // Generate pages with multiple labels if quantity > 1
    const labelsPerPage = 6;
    final pages = (quantity / labelsPerPage).ceil();
    
    for (int page = 0; page < pages; page++) {
      final startIndex = page * labelsPerPage;
      final endIndex = (startIndex + labelsPerPage).clamp(0, quantity);
      final labelsOnPage = endIndex - startIndex;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(labelsOnPage, (index) =>
              _buildBarcodeLabel(
                product: product,
                includeProductInfo: includeProductInfo,
              ),
            ),
          ),
        ),
      );
    }
    
    return pdf.save();
  }

  /// Generate PDF for multiple products
  static Future<Uint8List> generateMultipleProductBarcodePdf(
    List<Product> products, {
    bool includeProductInfo = true,
    int labelsPerRow = 2,
  }) async {
    final pdf = pw.Document();
    
    const labelsPerPage = 12; // 6 rows x 2 columns
    final pages = (products.length / labelsPerPage).ceil();
    
    for (int page = 0; page < pages; page++) {
      final startIndex = page * labelsPerPage;
      final endIndex = (startIndex + labelsPerPage).clamp(0, products.length);
      final productsOnPage = products.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            children: [
              // Create rows of labels
              for (int i = 0; i < productsOnPage.length; i += labelsPerRow)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    children: [
                      for (int j = 0; j < labelsPerRow && (i + j) < productsOnPage.length; j++)
                        pw.Expanded(
                          child: pw.Padding(
                            padding: pw.EdgeInsets.only(right: j < labelsPerRow - 1 ? 10 : 0),
                            child: _buildBarcodeLabel(
                              product: productsOnPage[i + j],
                              includeProductInfo: includeProductInfo,
                            ),
                          ),
                        ),
                      // Fill remaining space if needed
                      for (int k = productsOnPage.length - i; k < labelsPerRow; k++)
                        pw.Expanded(child: pw.SizedBox()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return pdf.save();
  }

  /// Build individual barcode label widget for PDF
  static pw.Widget _buildBarcodeLabel({
    required Product product,
    bool includeProductInfo = true,
  }) {
    // Use barcode if available, otherwise use SKU, otherwise use ID
    final barcodeText = product.barcode ?? product.sku ?? product.id.toString();
    
    return pw.Container(
      width: 200,
      height: 120,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Product name (if enabled)
          if (includeProductInfo)
            pw.Text(
              product.name,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),
          
          // Barcode
          pw.Expanded(
            child: pw.Center(
              child: pw.BarcodeWidget(
                barcode: Barcode.code128(),
                data: barcodeText,
                width: 160,
                height: 50,
              ),
            ),
          ),
          
          // Barcode text
          pw.Text(
            barcodeText,
            style: const pw.TextStyle(
              fontSize: 8,
            ),
            textAlign: pw.TextAlign.center,
          ),
          
          // Additional product info (if enabled)
          if (includeProductInfo) ...[
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (product.sku != null)
                  pw.Text(
                    'SKU: ${product.sku}',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                pw.Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Print barcode labels for multiple products
  static Future<void> printBarcodeLabels(
    List<Product> products, {
    bool includeProductInfo = true,
    String? printerName,
  }) async {
    try {
      final pdf = await generateMultipleProductBarcodePdf(
        products,
        includeProductInfo: includeProductInfo,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf,
        name: 'Product Barcodes',
      );
    } catch (e) {
      throw Exception('Failed to print barcode labels: $e');
    }
  }

  /// Print a single product barcode
  static Future<void> printProductBarcode(
    Product product, {
    int quantity = 1,
    bool includeProductInfo = true,
    String? jobName,
  }) async {
    try {
      final pdf = await generateProductBarcodePdf(
        product,
        includeProductInfo: includeProductInfo,
        quantity: quantity,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf,
        name: jobName ?? 'Barcode - ${product.name}',
      );
    } catch (e) {
      throw Exception('Failed to print product barcode: $e');
    }
  }

  /// Check if printing is available
  static Future<bool> isPrintingAvailable() async {
    final info = await Printing.info();
    return info.canPrint;
  }

  /// Get list of available printers
  static Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }

  /// Print to a specific printer
  static Future<void> printToSpecificPrinter(
    Uint8List pdfBytes,
    Printer printer, {
    String? jobName,
  }) async {
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (format) => pdfBytes,
      name: jobName ?? 'Barcode Print Job',
    );
  }
}

/// Barcode type enumeration
enum BarcodeType {
  code128,
  code39,
  ean13,
  upcA,
  qrCode,
}

/// Extension for barcode type conversion
extension BarcodeTypeExtension on BarcodeType {
  Barcode toBarcode() {
    switch (this) {
      case BarcodeType.code128:
        return Barcode.code128();
      case BarcodeType.code39:
        return Barcode.code39();
      case BarcodeType.ean13:
        return Barcode.ean13();
      case BarcodeType.upcA:
        return Barcode.upcA();
      case BarcodeType.qrCode:
        return Barcode.qrCode();
    }
  }
}
