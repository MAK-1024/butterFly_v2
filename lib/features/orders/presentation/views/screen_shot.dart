import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/model/orderModel.dart';

class InvoiceScreen extends StatefulWidget {
  final OrderModel order;

  const InvoiceScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: _isSaving ? null : _saveAsPdf,
        //   label: _isSaving
        //       ? const Text("جاري الحفظ...")
        //       : const Text("حفظ كـ PDF"),
        //   icon: _isSaving
        //       ? const CircularProgressIndicator(color: Colors.white)
        //       : const Icon(Icons.picture_as_pdf),
        // ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: _buildInvoiceWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'فاتورة نهائية',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/bshop.jpg',
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 32),
          Text(widget.order.id ,style: TextStyle(fontSize: 18 , fontWeight: FontWeight.bold),),
          // _invoiceRow("كود الطلبية", widget.order.id),
          _invoiceRow("اسم الزبون", widget.order.customerName),
          _invoiceRow("رقم الزبون", widget.order.customerNumber ?? "غير متوفر"),
          _invoiceRow("عنوان الزبون", widget.order.address ?? "غير متوفر"),
          _invoiceRow("عدد القطع", widget.order.pieceCount.toString()),
          _invoiceRow("العربون", '${widget.order.deposit} دينار'),
          _invoiceRow("نوع التوصيل", widget.order.shippingType.toString() ?? 'غير متوفر'),

          _invoiceRow("التكلفة الاجمالية", '${widget.order.totalPrice} دينار'),
          _invoiceRow("تكلفة الشحن", '${widget.order.shippingCost} دينار'),
          _invoiceRow("السعر النهائي", '${_calculateFinalPrice(widget.order).toStringAsFixed(2)} دينار'),
          const SizedBox(height: 30),
          const Text(
            "شكرًا لتعاملكم معنا!",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label :", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16 ,)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  double _calculateFinalPrice(OrderModel order) {
    return order.totalPrice - order.deposit + (order.shippingCost ?? 0);
  }

  Future<void> _saveAsPdf() async {
    setState(() => _isSaving = true);

    final pdf = pw.Document();
    final order = widget.order;

    try {
      // ✅ Load Arabic font (must be added in pubspec.yaml under assets)
      final fontData = await rootBundle.load(GoogleFonts.cairo().fontFamily!,);
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(
          textDirection: pw.TextDirection.rtl, // RTL support
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('فاتورة نهائية',
                      style: pw.TextStyle(fontSize: 24, font: ttf, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text("اسم الزبون: ${order.customerName}", style: pw.TextStyle(font: ttf)),
                pw.Text("رقم الزبون: ${order.customerNumber ?? "غير متوفر"}", style: pw.TextStyle(font: ttf)),
                pw.Text("عنوان الزبون: ${order.address ?? "غير متوفر"}", style: pw.TextStyle(font: ttf)),
                pw.Text("عدد القطع: ${order.pieceCount}", style: pw.TextStyle(font: ttf)),
                pw.Text("العربون: ${order.deposit} دينار", style: pw.TextStyle(font: ttf)),
                pw.Text("التكلفة الاجمالية: ${order.totalPrice} دينار", style: pw.TextStyle(font: ttf)),
                pw.Text("تكلفة الشحن: ${order.shippingCost} دينار", style: pw.TextStyle(font: ttf)),
                pw.Text("السعر النهائي: ${_calculateFinalPrice(order).toStringAsFixed(2)} دينار", style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 20),
                pw.Text("شكرًا لتعاملكم معنا!", style: pw.TextStyle(font: ttf, color: PdfColors.grey700)),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/فاتورة_${order.id}.pdf");

      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة كـ PDF')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء حفظ PDF: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
