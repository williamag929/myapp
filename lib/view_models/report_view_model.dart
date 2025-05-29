import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ReportViewModel extends ChangeNotifier {
  List<Report> photos = [];
  String? errorMessage;
  bool isAnalyzing = false;
  final DatabaseService _dbService = DatabaseService();
  final AIService _aiService = AIService();
  final PDFService _pdfService = PDFService();

  Future<String?> saveImageToDisk(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final path = '${directory.path}/$fileName';
      await image.copy(path);
      return fileName;
    } catch (e) {
      errorMessage = 'Failed to save image: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> savePhoto(File image, String note) async {
    if (note.isEmpty) {
      errorMessage = 'Note cannot be empty';
      notifyListeners();
      return;
    }
    final filePath = await saveImageToDisk(image);
    if (filePath == null) return;

    isAnalyzing = true;
    notifyListeners();
    final aiAnalysis = await _aiService.analyzeImage(image);
    isAnalyzing = false;

    final report = Report(
      id: const Uuid().v4(),
      date: DateTime.now(),
      note: note,
      photoPath: '${(await getApplicationDocumentsDirectory()).path}/$filePath',
      aiAnalysis: aiAnalysis,
    );

    photos.add(report);
    await _dbService.insertReport(report);
    notifyListeners();
  }

  Future<void> loadSavedReports() async {
    photos = await _dbService.getReports();
    notifyListeners();
  }

  String generateReport() {
    final summary = photos
        .map(
          (p) =>
              'Note: ${p.note}\nAI Analysis: ${p.aiAnalysis ?? "No analysis available"}',
        )
        .join('\n\n');
    return '''
      Daily Construction Report
      Date: ${DateTime.now().toString().split(' ')[0]}
      Summary:
      $summary
      (Photos attached in PDF report)
    ''';
  }

  Future<File?> exportPDF() async {
    return await _pdfService.generatePDF(photos);
  }
}
