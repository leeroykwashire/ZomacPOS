import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';
import '../database/app_database.dart';

class ReceiptPrintingService {
  /// Generate a receipt PDF for a completed sale
  static Future<Uint8List> generateReceiptPdf(
    Sale sale,
    List<SaleItem> saleItems,
    List<Product> products, {
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    bool includeQrCode = true,
  }) async {
    final pdf = pw.Document();
    
    // Create a receipt reference QR code for easy returns/exchanges
    final receiptQrData = 'RECEIPT:${sale.id}:${sale.saleDate.millisecondsSinceEpoch}';
    
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm, // 80mm thermal printer width
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Business Header
            _buildBusinessHeader(
              businessName ?? 'ZomacPOS Store',
              businessAddress ?? 'Your Business Address',
              businessPhone ?? 'Contact: +1234567890',
            ),
            
            pw.SizedBox(height: 10),
            
            // Sale Information
            _buildSaleInfo(sale),
            
            pw.SizedBox(height: 10),
            
            // Items List
            _buildItemsList(saleItems, products),
            
            pw.SizedBox(height: 10),
            
            // Totals
            _buildTotals(sale),
            
            pw.SizedBox(height: 10),
            
            // Payment Information
            _buildPaymentInfo(sale),
            
            if (includeQrCode) ...[
              pw.SizedBox(height: 15),
              _buildReceiptQrCode(receiptQrData),
            ],
            
            pw.SizedBox(height: 10),
            
            // Footer
            _buildReceiptFooter(),
          ],
        ),
      ),
    );
    
    return pdf.save();
  }

  /// Build business header section
  static pw.Widget _buildBusinessHeader(String name, String address, String phone) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            address,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            phone,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Divider(thickness: 1),
        ],
      ),
    );
  }

  /// Build sale information section
  static pw.Widget _buildSaleInfo(Sale sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Receipt #:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(sale.id.toString(), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year} ${sale.saleDate.hour}:${sale.saleDate.minute.toString().padLeft(2, '0')}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        if (sale.customerId != null)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Customer:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(sale.customerId!, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        pw.Divider(thickness: 0.5),
      ],
    );
  }

  /// Build items list section
  static pw.Widget _buildItemsList(List<SaleItem> saleItems, List<Product> products) {
    return pw.Column(
      children: [
        // Header
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('Price', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.Divider(thickness: 0.5),
        
        // Items
        ...saleItems.map((item) {
          final product = products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => Product(
              id: '',
              name: item.productName,
              price: item.salePrice,
              qty: 0,
              minQty: 0,
              trackStock: false,
            ),
          );
          
          return pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 9),
                          maxLines: 2,
                        ),
                        if (product.sku != null)
                          pw.Text(
                            'SKU: ${product.sku}',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      item.qty.toString(),
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.salePrice.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.lineTotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
            ],
          );
        }).toList(),
        
        pw.Divider(thickness: 0.5),
      ],
    );
  }

  /// Build totals section
  static pw.Widget _buildTotals(Sale sale) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('\$${sale.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        if (sale.taxAmount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('\$${sale.taxAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        if (sale.discountAmount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('-\$${sale.discountAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        pw.Divider(thickness: 1),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              '\$${sale.total.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build payment information section
  static pw.Widget _buildPaymentInfo(Sale sale) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Payment Method:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(sale.paymentMethod, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Amount Paid:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('\$${sale.amountPaid.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        if (sale.changeAmount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('\$${sale.changeAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
      ],
    );
  }

  /// Build receipt QR code section
  static pw.Widget _buildReceiptQrCode(String qrData) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'Receipt Reference:',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 5),
          pw.BarcodeWidget(
            barcode: Barcode.qrCode(),
            data: qrData,
            width: 50,
            height: 50,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Scan for returns/exchanges',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ],
      ),
    );
  }

  /// Build receipt footer
  static pw.Widget _buildReceiptFooter() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Divider(thickness: 0.5),
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Powered by ZomacPOS',
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Print receipt to default printer
  static Future<void> printReceipt(
    Sale sale,
    List<SaleItem> saleItems,
    List<Product> products, {
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    bool includeQrCode = true,
  }) async {
    try {
      final pdf = await generateReceiptPdf(
        sale,
        saleItems,
        products,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        includeQrCode: includeQrCode,
      );

      await Printing.layoutPdf(
        onLayout: (format) => pdf,
        name: 'Receipt ${sale.id}',
      );
    } catch (e) {
      throw Exception('Failed to print receipt: $e');
    }
  }

  /// Print receipt to specific thermal printer
  static Future<void> printReceiptToThermalPrinter(
    Sale sale,
    List<SaleItem> saleItems,
    List<Product> products,
    Printer printer, {
    String? businessName,
    String? businessAddress,
    String? businessPhone,
  }) async {
    try {
      final pdf = await generateReceiptPdf(
        sale,
        saleItems,
        products,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
      );

      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf,
        name: 'Receipt ${sale.id}',
      );
    } catch (e) {
      throw Exception('Failed to print receipt to thermal printer: $e');
    }
  }

  /// Get available thermal printers
  static Future<List<Printer>> getThermalPrinters() async {
    final printers = await Printing.listPrinters();
    // Filter for thermal printers (this might need adjustment based on your setup)
    return printers.where((printer) => 
      printer.name.toLowerCase().contains('thermal') ||
      printer.name.toLowerCase().contains('receipt') ||
      printer.name.toLowerCase().contains('pos')
    ).toList();
  }
}
