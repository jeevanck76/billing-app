import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(BillGeneratorApp());
}

class BillGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: BillFormPage());
  }
}

class BillFormPage extends StatefulWidget {
  @override
  _BillFormPageState createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  File? pdfFile;
  String selectedTemplate = "SRK 7585 Bill";

  final List<String> billTemplates = [
    "SRK 7585 Bill",
    "Ramakrishna Bus Bill",
    "Star Hitech Cam",
    "Star Hitech GPS",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bill Generator")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedTemplate,
                decoration: InputDecoration(labelText: "Select Bill Template"),
                items:
                    billTemplates.map((String template) {
                      return DropdownMenuItem<String>(
                        value: template,
                        child: Text(template),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTemplate = value!;
                  });
                },
              ),
              TextFormField(
                controller: customerNameController,
                decoration: InputDecoration(labelText: "Customer Name"),
                validator:
                    (value) => value!.isEmpty ? "Enter customer name" : null,
              ),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter amount" : null,
              ),
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(labelText: "Date"),
                validator: (value) => value!.isEmpty ? "Enter date" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    File file = await generatePDF();
                    setState(() {
                      pdfFile = file;
                    });
                  }
                },
                child: Text("Generate PDF"),
              ),
              SizedBox(height: 20),
              if (pdfFile != null) ...[
                ElevatedButton(
                  onPressed: () {
                    Printing.layoutPdf(
                      onLayout:
                          (PdfPageFormat format) async =>
                              pdfFile!.readAsBytes(),
                    );
                  },
                  child: Text("Preview PDF"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Share.shareFiles([pdfFile!.path], text: "Invoice PDF");
                  },
                  child: Text("Share PDF"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<File> generatePDF() async {
    final pdf = pw.Document();

    final pw.MemoryImage? image = await loadTemplateImage(selectedTemplate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (image != null)
                pw.Image(image, width: 200), // Add template image
              pw.SizedBox(height: 10),
              generateBillLayout(selectedTemplate),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/bill.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<pw.MemoryImage?> loadTemplateImage(String template) async {
    String imagePath;
    switch (template) {
      case "SRK 7585 Bill":
        imagePath = "assets/srk_7585_bill.png";
        break;
      case "Ramakrishna Bus Bill":
        imagePath = "assets/ramakrishna_bus_bill.png";
        break;
      case "Star Hitech Cam":
        imagePath = "assets/star_hitech_cam.png";
        break;
      case "Star Hitech GPS":
        imagePath = "assets/star_hitech_gps.png";
        break;
      default:
        return null;
    }

    final ByteData bytes = await rootBundle.load(imagePath);
    final Uint8List imageData = bytes.buffer.asUint8List();
    return pw.MemoryImage(imageData);
  }

  pw.Widget generateBillLayout(String template) {
    switch (template) {
      case "SRK 7585 Bill":
        return buildBill("SRK 7585 BILL");
      case "Ramakrishna Bus Bill":
        return buildBill("RAMAKRISHNA BUS BILL");
      case "Star Hitech Cam":
        return buildBill("STAR HITECH CAM BILL");
      case "Star Hitech GPS":
        return buildBill("STAR HITECH GPS BILL");
      default:
        return pw.Text("Invalid Template");
    }
  }

  pw.Widget buildBill(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Divider(),
        pw.Text(
          "Billed To: ${customerNameController.text}",
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          "Date: ${dateController.text}",
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          "Total Amount: \$${amountController.text}",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
