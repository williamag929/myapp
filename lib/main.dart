import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'view_models/report_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel(),
      child: MaterialApp(
        title: 'Construction Daily Report',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final TextEditingController _noteController = TextEditingController();

  HomeScreen({super.key});

  //const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ReportViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Construction Daily Report')),
      body: Column(
        children: [
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (viewModel.isAnalyzing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.photos.length,
              itemBuilder: (context, index) {
                final photo = viewModel.photos[index];
                return ListTile(
                  leading: Image.file(
                    File(photo.photoPath),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  title: Text('Note: ${photo.note}'),
                  subtitle:
                      photo.aiAnalysis != null
                          ? Text(
                            'AI Analysis: ${photo.aiAnalysis}',
                            style: const TextStyle(color: Colors.blue),
                          )
                          : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Enter note',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed:
                    viewModel.isAnalyzing
                        ? null
                        : () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (pickedFile != null) {
                            await viewModel.savePhoto(
                              File(pickedFile.path),
                              _noteController.text,
                            );
                            _noteController.clear();
                          }
                        },
                child: const Text('Take Photo'),
              ),
              ElevatedButton(
                onPressed:
                    viewModel.isAnalyzing
                        ? null
                        : () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            await viewModel.savePhoto(
                              File(pickedFile.path),
                              _noteController.text,
                            );
                            _noteController.clear();
                          }
                        },
                child: const Text('Pick Photo'),
              ),
            ],
          ),
          ElevatedButton(
            onPressed:
                viewModel.isAnalyzing
                    ? null
                    : () => showDialog(
                      context: context,
                      builder: (_) => const ReportDialog(),
                    ),
            child: const Text('Generate Report'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ReportViewModel>(context, listen: false);
    return AlertDialog(
      title: const Text('Daily Report'),
      content: SingleChildScrollView(child: Text(viewModel.generateReport())),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () async {
            final pdfFile = await viewModel.exportPDF();
            if (pdfFile != null) {
              await Share.shareFiles([
                pdfFile.path,
              ]); // Updated for share_plus 6.3.0
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to generate PDF')),
                );
              }
            }
          },
          child: const Text('Share PDF'),
        ),
      ],
    );
  }
}
