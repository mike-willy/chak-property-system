
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/payment_model.dart';

class ReceiptGenerator {
  static Future<void> generateAndDownload(PaymentModel payment, {String tenantName = 'Valued Tenant'}) async {
    final pdf = pw.Document();
    final date = payment.paidDate ?? payment.dueDate;
    final formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);
    
    // Company Details
    const companyName = "Jesma Investments";
    const companyAddress = "Nairobi, Kenya"; // Placeholder address
    const companyPhone = "+254 700 000 000"; // Placeholder phone

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(companyName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                        pw.Text(companyPhone, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("RECEIPT", style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400)),
                        pw.SizedBox(height: 5),
                        pw.Text("Receipt #: ${payment.transactionId ?? 'N/A'}", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("Date: $formattedDate", style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 20),

                // Bill To
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Bill To:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(tenantName, style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Payment Method:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(payment.method.toString().split('.').last.toUpperCase(), style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Table Header
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text("Description", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(flex: 1, child: pw.Text("Date Found", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Expanded(flex: 1, child: pw.Text("Amount (KES)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),
                
                // Table Row
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text("Rent Payment (Ref: ${payment.transactionId ?? 'N/A'})")),
                      pw.Expanded(flex: 1, child: pw.Text("$formattedDate $formattedTime")),
                      pw.Expanded(flex: 1, child: pw.Text(NumberFormat('#,###.00').format(payment.amount), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("TOTAL PAID", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          "KES ${NumberFormat('#,###.00').format(payment.amount)}", 
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Divider(color: PdfColors.grey400),
                pw.Center(
                  child: pw.Text(
                    "Thank you for your business!", 
                    style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)
                  )
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    "Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}", 
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)
                  )
                ),
              ],
            ),
          );
        },
      ),
    );

    // Open the Print Preview (allows printing or saving as PDF)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'receipt_${payment.transactionId ?? "unknown"}',
    );
  }
}
